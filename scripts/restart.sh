#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Termux Mini Server — Restart Helper (tms-restart)
# ==============================================================================

DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo ">> Merestart Termux Mini Server..."
bash "$DIR/stop.sh"
sleep 1
bash "$DIR/start.sh" "$@"
