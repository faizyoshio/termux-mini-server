#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Script untuk Menghentikan Seluruh Layanan (Panel & VPS)
# ==============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}>> Menghentikan Panel Web Server...${NC}"
pkill -f "panel/server.js" 2>/dev/null || true

echo -e "${YELLOW}>> Menghentikan Ubuntu OpenSSH Server...${NC}"
pkill -f "sshd -D" 2>/dev/null || true
pkill -f "/usr/sbin/sshd" 2>/dev/null || true

# Coba matikan service di proot-distro jika aktif
command -v proot-distro >/dev/null 2>&1 && proot-distro login ubuntu -- service ssh stop 2>/dev/null || true

sleep 1
echo -e "${GREEN}✓ Seluruh layanan Termux Mini Server & Ubuntu VPS berhasil dihentikan.${NC}"
