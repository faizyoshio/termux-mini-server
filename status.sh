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
    netstat -tuln 2>/dev/null | grep -q ":${port} " && return 0
    ss -tuln 2>/dev/null | grep -q ":${port} " && return 0
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

# Alamat IP
LOCAL_IP=$(ip -4 addr show 2>/dev/null | grep -E "inet (192\.168\.|10\.|172\.)" | awk '{print $2}' | cut -d'/' -f1 | head -n1)
LOCAL_IP="${LOCAL_IP:-127.0.0.1}"
echo -e " • IP Wi-Fi Lokal            : ${CYAN}$LOCAL_IP${NC}"

# Status Tailscale
TS_IP=$(ip -4 addr show 2>/dev/null | grep -E "inet 100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\." | awk '{print $2}' | cut -d'/' -f1 | head -n1)
if [ -n "$TS_IP" ]; then
    echo -e " • IP Tailscale (VPN)        : ${GREEN}$TS_IP (TERHUBUNG)${NC}"
    echo -e "   -> Akses Remote Web       : ${GREEN}http://$TS_IP:8080${NC}"
    echo -e "   -> Akses Remote SSH       : ${GREEN}ssh root@$TS_IP -p 2222${NC}"
else
    echo -e " • IP Tailscale (VPN)        : ${YELLOW}Belum Aktif (Buka aplikasi Tailscale di HP)${NC}"
fi

echo -e "==================================================================${NC}"
