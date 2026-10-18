#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Termux Mini Server — Restore Utility
# Memulihkan konfigurasi panel dan data dari file .tar.gz cadangan
# ==============================================================================

ARCHIVE="$1"

if [ -z "$ARCHIVE" ] || [ ! -f "$ARCHIVE" ]; then
    echo "Penggunaan: bash scripts/restore.sh /jalur/ke/tms-backup_xxx.tar.gz"
    exit 1
fi

echo ">> Memulihkan sistem dari $ARCHIVE ..."
cd "$HOME"
tar -xzf "$ARCHIVE" -C "$HOME"
echo "✓ Pemulihan data selesai!"
echo "Silakan restart server dengan: tms-server"
