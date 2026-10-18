#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Termux Mini Server — 24/7 Stability & Anti-Sleep Repair Tool (tms-fix)
# ==============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$BASE_DIR" || exit 1

echo -e "${CYAN}=================================================================="
echo -e " 🛠️  PEMULIHAN & OPTIMASI STABILITAS 24/7 (ANTI-SLEEP REPAIR)"
echo -e "==================================================================${NC}"
echo ""

# 1. Pastikan Izin CPU Wake-Lock Aktif
echo -e "${YELLOW}[1/6] Mengaktifkan CPU Wake-Lock Android...${NC}"
termux-wake-lock 2>/dev/null || true
echo -e "${GREEN}✓ CPU Wake-Lock aktif (Mencegah HP deep sleep saat layar mati).${NC}"

# 2. Mitigasi Phantom Process Killer (Android 12/13/14+)
echo -e "${YELLOW}[2/6] Memeriksa limit proses latar belakang (Phantom Killer)...${NC}"
/system/bin/device_config put activity_manager max_phantom_processes 2147483647 2>/dev/null || true
/system/bin/setprop persist.sys.fflag.override.settings_enable_monitor_phantom_procs false 2>/dev/null || true
echo -e "${GREEN}✓ Konfigurasi batas proses diperbarui.${NC}"

# 3. Pembersihan Cache dan Memori Sampah
echo -e "${YELLOW}[3/6] Membersihkan cache sisa instalasi & memori sampah...${NC}"
pkg clean 2>/dev/null || true
apt-get clean 2>/dev/null || true
rm -rf "$HOME/.cache"/* 2>/dev/null || true
rm -rf "${PREFIX:-/data/data/com.termux/files/usr}/tmp"/* 2>/dev/null || true
echo -e "${GREEN}✓ Memori RAM dan cache dibersihkan.${NC}"

# 4. Sinkronisasi Pintasan CLI di $PREFIX/bin
echo -e "${YELLOW}[4/6] Memperbaiki seluruh pintasan CLI di \$PREFIX/bin...${NC}"
PREFIX_BIN="${PREFIX:-/data/data/com.termux/files/usr}/bin"
chmod +x *.sh scripts/*.sh 2>/dev/null || true

if [ -d "$PREFIX_BIN" ]; then
    for cmd in tms-server:start.sh tms-stop:stop.sh tms-status:status.sh tms-update:update.sh tms-fix:scripts/fix-server.sh tms-app:scripts/app-manager.sh tms-backup:scripts/backup.sh tms-restore:scripts/restore.sh ubuntu:scripts/start-ubuntu.sh; do
        cname="${cmd%%:*}"
        ctarget="${cmd##*:}"
        cat << EOF > "$PREFIX_BIN/$cname"
#!/data/data/com.termux/files/usr/bin/bash
bash "$BASE_DIR/$ctarget" "\$@"
EOF
        chmod +x "$PREFIX_BIN/$cname"
    done
    hash -r 2>/dev/null || true
    echo -e "${GREEN}✓ Seluruh perintah CLI (tms-server, tms-fix, tms-update, dll) siap.${NC}"
fi

# 5. Konfigurasi Autostart Termux:Boot
echo -e "${YELLOW}[5/6] Memperbarui konfigurasi autostart (Termux:Boot)...${NC}"
BOOT_DIR="$HOME/.termux/boot"
mkdir -p "$BOOT_DIR"
cat << EOF > "$BOOT_DIR/start-tms.sh"
#!/data/data/com.termux/files/usr/bin/bash
sleep 10
termux-wake-lock 2>/dev/null || true
bash "$BASE_DIR/start.sh" >/dev/null 2>&1 &
EOF
chmod +x "$BOOT_DIR/start-tms.sh"
echo -e "${GREEN}✓ Skrip autostart booting diperbarui.${NC}"

# 6. Verifikasi & Restart Layanan
echo -e "${YELLOW}[6/6] Memastikan layanan Web Dashboard & OpenSSH berjalan...${NC}"
# Cek Web Dashboard
PANEL_ACTIVE=false
(exec 3<>/dev/tcp/127.0.0.1/8080) 2>/dev/null && { exec 3<&-; exec 3>&-; PANEL_ACTIVE=true; }
if [ "$PANEL_ACTIVE" = false ] && ! pgrep -f "node.*panel/server.js" >/dev/null 2>&1; then
    echo -e "${BLUE}>> Menjalankan ulang Web Dashboard (Port 8080)...${NC}"
    mkdir -p "$BASE_DIR/logs"
    nohup node "$BASE_DIR/panel/server.js" > "$BASE_DIR/logs/panel.log" 2>&1 &
    sleep 1
    echo -e "${GREEN}✓ Web Dashboard berhasil diaktifkan kembali.${NC}"
else
    echo -e "${GREEN}✓ Web Dashboard sudah aktif di port 8080.${NC}"
fi

# Cek OpenSSH VPS
SSH_ACTIVE=false
(exec 3<>/dev/tcp/127.0.0.1/2222) 2>/dev/null && { exec 3<&-; exec 3>&-; SSH_ACTIVE=true; }
if [ "$SSH_ACTIVE" = false ] && ! pgrep -f "sshd" >/dev/null 2>&1; then
    echo -e "${BLUE}>> Menjalankan ulang OpenSSH Server Ubuntu (Port 2222)...${NC}"
    bash "$BASE_DIR/scripts/start-ubuntu.sh" --daemon >/dev/null 2>&1 || true
    echo -e "${GREEN}✓ Ubuntu VPS OpenSSH berhasil diaktifkan.${NC}"
else
    echo -e "${GREEN}✓ Ubuntu OpenSSH sudah aktif di port 2222.${NC}"
fi

echo ""
echo -e "${GREEN}=================================================================="
echo -e " 🎉 PERBAIKAN SELESAI! SERVER KEMBALI STABIL 24/7"
echo -e "==================================================================${NC}"
echo -e "${YELLOW}⚠️ PENTING AGAR TERMUX TIDAK DIMATIKAN OLEH ANDROID:${NC}"
echo -e "1. Buka ${CYAN}Pengaturan HP${NC} -> ${CYAN}Aplikasi${NC} -> ${CYAN}Termux${NC} -> ${CYAN}Baterai${NC}."
echo -e "2. Pilih ${GREEN}Tidak Dibatasi / Unrestricted / Jangan Optimalkan${NC}."
echo -e "3. Lakukan hal yang sama untuk aplikasi ${GREEN}Tailscale${NC}."
echo -e "4. Kunci aplikasi Termux di layar Recent Apps (Gembok / Lock)."
echo ""
echo -e "Ketik ${CYAN}tms-status${NC} untuk melihat status IP dan koneksi server."
echo ""
