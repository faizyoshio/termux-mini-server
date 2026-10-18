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

is_port_active() {
    local port="$1"
    netstat -tuln 2>/dev/null | grep -q ":${port} " && return 0
    ss -tuln 2>/dev/null | grep -q ":${port} " && return 0
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
[ -z "$LOCAL_IP" ] && LOCAL_IP=$(ip -4 addr show 2>/dev/null | grep -E "inet (192\.168\.|10\.|172\.)" | awk '{print $2}' | cut -d'/' -f1 | head -n1)
LOCAL_IP="${LOCAL_IP:-127.0.0.1}"

# Ambil IP Tailscale (100.x)
TS_IP=$(ip -4 addr show 2>/dev/null | grep -E "inet 100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\." | awk '{print $2}' | cut -d'/' -f1 | head -n1)

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
