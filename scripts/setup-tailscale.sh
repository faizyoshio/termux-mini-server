#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Helper Script: Deteksi & Setup Tailscale di Android / Termux (Multi-Strategy)
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
    # Bypasses all Android SELinux & non-root UID sandboxes with zero external traffic
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

    # 4. Probe via ip -4 addr show (match any IP in 100.64.0.0/10)
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

    # 6. Probe via /proc/net/fib_trie (Kernel routing table)
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

TS_IP=$(get_tailscale_ip)

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
    echo -e "${BLUE}💡 Tips Tambahan Jika Masih Belum Terbaca:${NC}"
    echo -e "• Di aplikasi Tailscale Android: Buka ${YELLOW}Settings${NC} -> Aktifkan ${YELLOW}'Allow incoming connections'${NC}."
    echo -e "• Atau Anda dapat memasukkan IP Tailscale secara manual di Web Dashboard via tombol ${CYAN}'✏️ Set IP Manual'${NC}."
    echo ""
    echo -e "Setelah kedua perangkat terhubung ke Tailscale, jalankan perintah ini lagi:"
    echo -e "  ${YELLOW}bash scripts/setup-tailscale.sh${NC}"
fi
echo -e "${CYAN}==================================================================${NC}"
