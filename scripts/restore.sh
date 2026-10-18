#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Termux Mini Server — Restore Utility
# Memulihkan konfigurasi panel dan data dari file .tar.gz cadangan
# ==============================================================================

ARCHIVE="$1"

if [ -z "$ARCHIVE" ] || [ ! -f "$ARCHIVE" ]; then
    echo "Penggunaan: tms-restore /jalur/ke/tms-backup_xxx.tar.gz"
    exit 1
fi

DIR="$(cd "$(dirname "$0")/.." && pwd)"
PARENT_DIR="$(dirname "$DIR")"

echo ">> Memulihkan sistem dari $ARCHIVE ..."
cd "$PARENT_DIR"
tar -xzf "$ARCHIVE" -C "$PARENT_DIR"
echo "✓ Pemulihan data selesai!"
echo "Silakan restart server dengan: tms-restart (atau tms-start)"
