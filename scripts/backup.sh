#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Termux Mini Server — Backup Utility
# Mencadangkan konfigurasi panel, kredensial, dan script ke format .tar.gz
# ==============================================================================

export PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
[ -z "$HOME" ] || [ "$HOME" = "/" ] || [ "$HOME" = "/root" ] && [ -d "/data/data/com.termux/files/home" ] && export HOME="/data/data/com.termux/files/home"

DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIR_NAME="$(basename "$DIR")"
PARENT_DIR="$(dirname "$DIR")"

BACKUP_DIR="/sdcard/TMS_Backups"
if [ ! -d "/sdcard" ] || ! mkdir -p "$BACKUP_DIR" 2>/dev/null; then
    BACKUP_DIR="$HOME/tms-backups"
    mkdir -p "$BACKUP_DIR" 2>/dev/null || true
fi

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILENAME="tms-backup_${TIMESTAMP}.tar.gz"
TARGET="$BACKUP_DIR/$FILENAME"

echo ">> Membuat berkas cadangan di $TARGET ..."

cd "$PARENT_DIR"
tar --exclude="*.log" \
    --exclude="node_modules" \
    --exclude=".cache" \
    --exclude="ubuntu-fs" \
    -czf "$TARGET" \
    "$DIR_NAME" 2>/dev/null || true

if [ -f "$TARGET" ]; then
    SIZE=$(ls -lh "$TARGET" | awk '{print $5}')
    echo "✓ Cadangan berhasil dibuat!"
    echo "  • Berkas: $TARGET ($SIZE)"
else
    echo "❌ Gagal membuat cadangan."
    exit 1
fi
