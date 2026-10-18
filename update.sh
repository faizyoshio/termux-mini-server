#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Termux Mini Server — Updater (Safe Update Without Reinstall)
# ==============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$BASE_DIR" || exit 1

echo -e "${CYAN}=================================================================="
echo -e " 🔄 MEMPERBARUI TERMUX MINI SERVER (UPDATE)"
echo -e "==================================================================${NC}"
echo ""

# 1. Cek git repo
if [ ! -d ".git" ]; then
    echo -e "${RED}⚠️ Direktori bukan repositori git.${NC}"
    echo -e "Silakan clone ulang jika direktori rusak."
    exit 1
fi

# 2. Ambil perubahan terbaru dari GitHub
echo -e "${YELLOW}>> Mengambil pembaruan terbaru dari GitHub...${NC}"

# Simpan cadangan auth-config.json jika sudah dikustomisasi agar tidak konflik git
if [ -f "panel/auth-config.json" ]; then
    cp "panel/auth-config.json" "$BASE_DIR/.auth-config.json.bak" 2>/dev/null || true
    git checkout -- panel/auth-config.json 2>/dev/null || true
fi

git fetch origin main 2>/dev/null || git fetch origin 2>/dev/null

LOCAL=$(git rev-parse HEAD 2>/dev/null)
REMOTE=$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/HEAD 2>/dev/null)

if [ "$LOCAL" = "$REMOTE" ]; then
    echo -e "${GREEN}✓ Server sudah berada di versi paling mutakhir!${NC}"
else
    echo -e "${BLUE}>> Menarik perubahan kode...${NC}"
    git pull origin main || git pull origin
    echo -e "${GREEN}✓ Berhasil diperbarui ke versi terbaru!${NC}"
fi

# Kembalikan auth-config.json milik pengguna
if [ -f "$BASE_DIR/.auth-config.json.bak" ]; then
    cp "$BASE_DIR/.auth-config.json.bak" "panel/auth-config.json" 2>/dev/null || true
    rm -f "$BASE_DIR/.auth-config.json.bak" 2>/dev/null || true
fi

# 3. Pastikan izin eksekusi skrip aman
chmod +x *.sh scripts/*.sh 2>/dev/null || true

# 4. Pastikan symlinks CLI di $PREFIX/bin up-to-date
PREFIX_BIN="${PREFIX:-/data/data/com.termux/files/usr}/bin"
if [ -d "$PREFIX_BIN" ]; then
    for cmd in tms-server:start.sh tms-stop:stop.sh tms-status:status.sh tms-update:update.sh tms-app:scripts/app-manager.sh tms-backup:scripts/backup.sh tms-restore:scripts/restore.sh ubuntu:scripts/start-ubuntu.sh; do
        cname="${cmd%%:*}"
        ctarget="${cmd##*:}"
        cat << EOF > "$PREFIX_BIN/$cname"
#!/data/data/com.termux/files/usr/bin/bash
bash "$BASE_DIR/$ctarget" "\$@"
EOF
        chmod +x "$PREFIX_BIN/$cname"
    done
    hash -r 2>/dev/null || true
fi

# 5. Cek apakah server panel sedang berjalan dan restart jika perlu
PANEL_PID=$(pgrep -f "node.*panel/server.js" 2>/dev/null | head -n1)
if [ -n "$PANEL_PID" ]; then
    echo ""
    echo -e "${YELLOW}>> Merestart Web Dashboard agar perubahan berlaku...${NC}"
    kill -9 "$PANEL_PID" 2>/dev/null || true
    sleep 1
    nohup node "$BASE_DIR/panel/server.js" > "$BASE_DIR/logs/panel.log" 2>&1 &
    echo -e "${GREEN}✓ Web Dashboard berhasil direstart.${NC}"
fi

echo ""
echo -e "${GREEN}=================================================================="
echo -e " 🎉 PEMBARUAN SELESAI!"
echo -e "==================================================================${NC}"
echo -e "• Versi aktif: $(git log -1 --pretty=format:'%h - %s (%cd)' --date=short 2>/dev/null || echo 'Up-to-date')"
echo -e "• Jalankan ${CYAN}tms-status${NC} untuk melihat status server & Tailscale."
echo ""
