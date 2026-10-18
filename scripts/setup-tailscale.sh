#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Helper Script: Deteksi & Setup Tailscale di Android / Termux
# ==============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}=================================================================="
echo -e " 🔒 Pemeriksaan Status Tailscale (Akses Jarak Jauh Tanpa Port-Forward)"
echo -e "==================================================================${NC}"
echo ""

# 1. Cek apakah ada IP 100.x di antarmuka jaringan
TS_IP=$(ip -4 addr show 2>/dev/null | grep -E "inet 100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\." | awk '{print $2}' | cut -d'/' -f1 | head -n1)

if [ -n "$TS_IP" ]; then
    echo -e "${GREEN}✓ Tailscale TERHUBUNG!${NC}"
    echo -e "  • IP Tailscale Anda : ${YELLOW}$TS_IP${NC}"
    echo ""
    echo -e "🌐 Tautan Akses dari Laptop / HP Lain (dalam 1 akun Tailscale):"
    echo -e "  • Web Dashboard   : ${CYAN}http://$TS_IP:8080${NC}"
    echo -e "  • SSH Ubuntu VPS  : ${CYAN}ssh root@$TS_IP -p 2222${NC}"
    echo ""
else
    echo -e "${YELLOW}⚠️ Tailscale BELUM TERDETEKSI aktif di HP ini.${NC}"
    echo ""
    echo -e "${BLUE}💡 Cara Menghubungkan Tailscale (Sangat Mudah & Gratis):${NC}"
    echo -e "1. Buka aplikasi ${YELLOW}Google Play Store${NC} atau ${YELLOW}F-Droid${NC} di HP server ini."
    echo -e "2. Cari dan pasang aplikasi ${GREEN}Tailscale${NC}."
    echo -e "3. Buka Tailscale, login dengan akun Google/GitHub/Microsoft Anda, lalu geser toggle ke ${GREEN}ACTIVE / CONNECTED${NC}."
    echo -e "4. Pasang juga Tailscale di Laptop/PC Anda (dari ${CYAN}https://tailscale.com/download${NC}) dan login dengan akun yang sama."
    echo ""
    echo -e "Setelah kedua perangkat terhubung ke Tailscale, jalankan perintah ini lagi:"
    echo -e "  ${YELLOW}bash scripts/setup-tailscale.sh${NC}"
fi
echo -e "${CYAN}==================================================================${NC}"
