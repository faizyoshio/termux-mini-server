#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Master Launcher: Menjalankan Panel Web (Port 8080) & Ubuntu VPS (Port 2222)
# ==============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$DIR/logs"
mkdir -p "$LOG_DIR"
PANEL_LOG="$LOG_DIR/panel.log"

export PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
[ -z "$HOME" ] || [ "$HOME" = "/" ] || [ "$HOME" = "/root" ] && [ -d "/data/data/com.termux/files/home" ] && export HOME="/data/data/com.termux/files/home"
export PATH="/data/data/com.termux/files/usr/bin:$PREFIX/bin:$PREFIX/bin/applets:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# Kunci CPU smartphone agar tidak mati saat layar padam (24/7 Always-On)
termux-wake-lock 2>/dev/null || true

is_port_active() {
    local port="$1"

    # 1. Direct TCP connect probe via /dev/tcp (pure bash builtin, bypass SELinux)
    (exec 3<>/dev/tcp/127.0.0.1/"$port") 2>/dev/null && { exec 3<&-; exec 3>&-; return 0; }
    (echo > /dev/tcp/127.0.0.1/"$port") 2>/dev/null && return 0

    # 2. curl probe for port 8080 (Web Dashboard)
    if [ "$port" = "8080" ]; then
        curl -s --connect-timeout 1 http://127.0.0.1:8080/ >/dev/null 2>&1 && return 0
    fi

    # 3. Process inspection (detect active Node / SSHD daemon)
    if [ "$port" = "8080" ]; then
        pgrep -f "node.*panel/server.js" >/dev/null 2>&1 && return 0
    elif [ "$port" = "2222" ]; then
        pgrep -f "sshd.*2222" >/dev/null 2>&1 && return 0
        pgrep -f "usr/sbin/sshd" >/dev/null 2>&1 && return 0
    fi

    # 4. netstat / ss fallback
    netstat -tuln 2>/dev/null | grep -E "(:|\\.)${port}[[:space:]]" && return 0
    ss -tuln 2>/dev/null | grep -E "(:|\\.)${port}[[:space:]]" && return 0

    return 1
}

get_tailscale_ip() {
    local ip=""
    local conf_file="$DIR/panel/auth-config.json"

    # 1. Manual override from panel config if set
    if [ -f "$conf_file" ]; then
        local override=$(grep -o '"tailscaleOverride": *"[^"]*"' "$conf_file" 2>/dev/null | cut -d'"' -f4)
        if [ -n "$override" ]; then
            echo "$override"
            return 0
        fi
    fi

    # 2. Node.js interface check & UDP probe to Quad-100 (100.100.100.100:53)
    if command -v node >/dev/null 2>&1; then
        ip=$(node -e "
const os = require('os');
const ifaces = os.networkInterfaces();
for (const n of Object.keys(ifaces)) {
  for (const net of ifaces[n]) {
    if (net.family === 'IPv4' && !net.internal && net.address.startsWith('100.')) {
      console.log(net.address);
      process.exit(0);
    }
  }
}
const dgram = require('dgram');
const s = dgram.createSocket('udp4');
s.connect(53, '100.100.100.100', () => {
  try {
    const a = s.address().address;
    if (a && a.startsWith('100.') && a !== '100.100.100.100') {
      console.log(a);
    }
  } catch(e) {}
  s.close();
  process.exit(0);
});
s.on('error', () => process.exit(0));
setTimeout(() => process.exit(0), 600);
" 2>/dev/null)
        if [ -n "$ip" ]; then
            echo "$ip"
            return 0
        fi
    fi

    # 3. Probe via ip route get 100.100.100.100
    ip=$( (ip route get 100.100.100.100 2>/dev/null || /system/bin/ip route get 100.100.100.100 2>/dev/null) | grep -Eo "src 100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.[0-9]+\.[0-9]+" | awk '{print $2}' | head -n1)
    if [ -n "$ip" ]; then
        echo "$ip"
        return 0
    fi

    # 4. Probe via ip -4 addr show
    ip=$( (ip -4 addr show 2>/dev/null || /system/bin/ip -4 addr show 2>/dev/null) | grep -Eo "100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.[0-9]+\.[0-9]+" | grep -v "100.100.100.100" | head -n1)
    if [ -n "$ip" ]; then
        echo "$ip"
        return 0
    fi

    # 5. Probe via ifconfig -a
    ip=$( (ifconfig -a 2>/dev/null || /system/bin/ifconfig -a 2>/dev/null) | grep -Eo "100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.[0-9]+\.[0-9]+" | grep -v "100.100.100.100" | head -n1)
    if [ -n "$ip" ]; then
        echo "$ip"
        return 0
    fi

    # 6. Probe via /proc/net/fib_trie
    if [ -r /proc/net/fib_trie ]; then
        ip=$(grep -B1 "host LOCAL" /proc/net/fib_trie 2>/dev/null | grep -Eo "100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.[0-9]+\.[0-9]+" | grep -v "100.100.100.100" | head -n1)
        if [ -n "$ip" ]; then
            echo "$ip"
            return 0
        fi
    fi

    # 7. Probe via Tailscale CLI if installed in Termux
    if command -v tailscale >/dev/null 2>&1; then
        ip=$(tailscale ip -4 2>/dev/null | head -n1)
        if [ -n "$ip" ]; then
            echo "$ip"
            return 0
        fi
    fi

    return 1
}

# 1. Jalankan OpenSSH Server di dalam Ubuntu VPS (Port 2222)
if is_port_active 2222; then
    echo -e "${GREEN}✓ Ubuntu VPS OpenSSH sudah aktif di port 2222.${NC}"
else
    echo -e "${YELLOW}>> Menjalankan OpenSSH Server Ubuntu VPS (Port 2222)...${NC}"
    bash "$DIR/scripts/start-ubuntu.sh" --daemon >/dev/null 2>&1 || true
    sleep 1
fi

# 2. Jalankan Panel Web Dashboard (Port 8080)
if is_port_active 8080; then
    echo -e "${GREEN}✓ Web Dashboard sudah aktif di port 8080.${NC}"
else
    echo -e "${YELLOW}>> Menjalankan Web Dashboard Server (Port 8080)...${NC}"
    # Matikan proses node lama yang mungkin menggantung
    pkill -f "panel/server.js" 2>/dev/null || true
    sleep 0.5
    nohup node "$DIR/panel/server.js" > "$PANEL_LOG" 2>&1 &
    sleep 1.5
fi

# 3. Ambil Informasi Alamat IP
LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')
[ -z "$LOCAL_IP" ] && LOCAL_IP=$( (ip -4 addr show 2>/dev/null || ifconfig 2>/dev/null) | grep -Eo "inet (addr:)?(192\.168\.[0-9]+\.[0-9]+|10\.[0-9]+\.[0-9]+\.[0-9]+|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]+\.[0-9]+)" | grep -Eo "(192\.168\.[0-9]+\.[0-9]+|10\.[0-9]+\.[0-9]+\.[0-9]+|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]+\.[0-9]+)" | head -n1)
LOCAL_IP="${LOCAL_IP:-127.0.0.1}"

# Ambil IP Tailscale (100.x)
TS_IP=$(get_tailscale_ip)

echo ""
echo -e "${CYAN}=================================================================="
echo -e " 🚀 SERVER BERHASIL DIJALANKAN (SIAP DIGUNAKAN)"
echo -e "==================================================================${NC}"
echo -e "📱 ${YELLOW}Akses Wi-Fi Lokal (HP & Laptop 1 Wi-Fi):${NC}"
echo -e "   • Web Dashboard : ${CYAN}http://$LOCAL_IP:8080${NC}"
echo -e "   • SSH Terminal  : ${CYAN}ssh root@$LOCAL_IP -p 2222${NC}"
echo ""

if [ -n "$TS_IP" ]; then
    echo -e "🔒 ${GREEN}Akses Jarak Jauh Tailscale (Bisa dari Luar Jaringan/Data Seluler):${NC}"
    echo -e "   • Web Dashboard : ${GREEN}http://$TS_IP:8080${NC}"
    echo -e "   • SSH Terminal  : ${GREEN}ssh root@$TS_IP -p 2222${NC}"
else
    echo -e "🔒 ${BLUE}Akses Jarak Jauh Tailscale:${NC}"
    echo -e "   • ${YELLOW}[Belum Terdeteksi]${NC} Aktifkan VPN di aplikasi Tailscale Android."
    echo -e "   • Setelah aktif, server otomatis bisa diakses via IP Tailscale Anda."
fi

echo ""
echo -e "🔑 ${YELLOW}Kredensial Default:${NC}"
echo -e "   • Web Panel : Username: ${CYAN}admin${NC} | Password: ${CYAN}admin123${NC}"
echo -e "   • Ubuntu SSH: User: ${CYAN}root${NC} atau ${CYAN}ubuntu${NC} | Password: ${CYAN}ubuntu123${NC}"
echo -e "=================================================================="
echo -e "💡 Gunakan ${CYAN}tms-status${NC} untuk cek info, dan ${CYAN}tms-stop${NC} untuk mematikan."
echo ""
