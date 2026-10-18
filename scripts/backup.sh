#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Termux Mini Server — Backup Utility
# Mencadangkan konfigurasi panel, kredensial, dan script ke format .tar.gz
# ==============================================================================

export PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
[ -z "$HOME" ] || [ "$HOME" = "/" ] || [ "$HOME" = "/root" ] && [ -d "/data/data/com.termux/files/home" ] && export HOME="/data/data/com.termux/files/home"

BACKUP_DIR="/sdcard/TMS_Backups"
[ ! -d "/sdcard" ] && BACKUP_DIR="$HOME/tms-backups"
mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILENAME="tms-backup_${TIMESTAMP}.tar.gz"
TARGET="$BACKUP_DIR/$FILENAME"

echo ">> Membuat berkas cadangan di $TARGET ..."

cd "$HOME"
tar --exclude="*.log" \
    --exclude="node_modules" \
    --exclude=".cache" \
    --exclude="ubuntu-fs" \
    -czf "$TARGET" \
    termux-mini-server \
    .termux 2>/dev/null || tar -czf "$TARGET" termux-mini-server 2>/dev/null || true

if [ -f "$TARGET" ]; then
    SIZE=$(ls -lh "$TARGET" | awk '{print $5}')
    echo "✓ Cadangan berhasil dibuat!"
    echo "  • Berkas: $TARGET ($SIZE)"
else
    echo "❌ Gagal membuat cadangan."
    exit 1
fi
