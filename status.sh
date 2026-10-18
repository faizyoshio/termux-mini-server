#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Script Pengecekan Status Server, Port, dan Tailscale
# ==============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

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
    local conf_file="$HOME/termux-mini-server/panel/auth-config.json"

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

echo -e "${CYAN}=================================================================="
echo -e " 📊 STATUS TERMUX MINI SERVER & UBUNTU VPS"
echo -e "==================================================================${NC}"

# Status Port 8080 (Panel)
if is_port_active 8080; then
    echo -e " • Web Dashboard (Port 8080) : ${GREEN}AKTIF (ONLINE)${NC}"
else
    echo -e " • Web Dashboard (Port 8080) : ${RED}TIDAK AKTIF (OFFLINE)${NC}"
fi

# Status Port 2222 (VPS SSH)
if is_port_active 2222; then
    echo -e " • Ubuntu OpenSSH (Port 2222): ${GREEN}AKTIF (ONLINE)${NC}"
else
    echo -e " • Ubuntu OpenSSH (Port 2222): ${RED}TIDAK AKTIF (OFFLINE)${NC}"
fi

# Alamat IP Lokal Wi-Fi
LOCAL_IP=$( (ip -4 addr show 2>/dev/null || ifconfig 2>/dev/null) | grep -Eo "inet (addr:)?(192\.168\.[0-9]+\.[0-9]+|10\.[0-9]+\.[0-9]+\.[0-9]+|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]+\.[0-9]+)" | grep -Eo "(192\.168\.[0-9]+\.[0-9]+|10\.[0-9]+\.[0-9]+\.[0-9]+|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]+\.[0-9]+)" | head -n1)
LOCAL_IP="${LOCAL_IP:-127.0.0.1}"
echo -e " • IP Wi-Fi Lokal            : ${CYAN}$LOCAL_IP${NC}"

# Status Tailscale
TS_IP=$(get_tailscale_ip)
if [ -n "$TS_IP" ]; then
    echo -e " • IP Tailscale (VPN)        : ${GREEN}$TS_IP (TERHUBUNG)${NC}"
    echo -e "   -> Akses Remote Web       : ${GREEN}http://$TS_IP:8080${NC}"
    echo -e "   -> Akses Remote SSH       : ${GREEN}ssh root@$TS_IP -p 2222${NC}"
else
    echo -e " • IP Tailscale (VPN)        : ${YELLOW}Belum Terdeteksi${NC}"
    echo -e "   -> Pastikan toggle 'Connected' di aplikasi Tailscale HP aktif."
    echo -e "   -> Atau jalankan: ${CYAN}bash scripts/setup-tailscale.sh${NC}"
fi

echo -e "==================================================================${NC}"
