#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Termux Mini Server & Ubuntu VPS (Tailscale Edition) — 1-Click Master Installer
# Kompatibel: Android 7.0 s/d 14+ (ARM64, ARM32, x86_64)
# ==============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${CYAN}=================================================================="
echo "  _______                                   __  __ _       _  _____ "
echo " |__   __|                                 |  \/  (_)     (_)/ ____|"
echo "    | | ___ _ __ _ __ ___  _   ___  __     | \  / |_ _ __  _| (___  "
echo "    | |/ _ \ '__| '_ \` _ \| | | \ \/ /     | |\/| | | '_ \| |\___ \ "
echo "    | |  __/ |  | | | | | | |_| |>  <      | |  | | | | | | |____) |"
echo "    |_|\___|_|  |_| |_| |_|\__,_/_/\_\     |_|  |_|_|_| |_|_|_____/ "
echo "=================================================================="
echo -e " 🚀 Master Installer — Web Dashboard + Ubuntu VPS + Tailscale Ready"
echo -e "==================================================================${NC}"
echo ""

# -----------------------------------------------------------------------------
# 0. INISIALISASI LINGKUNGAN
# -----------------------------------------------------------------------------
export PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
[ -z "$HOME" ] || [ "$HOME" = "/" ] || [ "$HOME" = "/root" ] && [ -d "/data/data/com.termux/files/home" ] && export HOME="/data/data/com.termux/files/home"
export PATH="/data/data/com.termux/files/usr/bin:$PREFIX/bin:$PREFIX/bin/applets:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$HOME/termux-mini-server"

# Jika dijalankan langsung dari folder clone, sinkronkan ke $BASE_DIR jika berbeda
if [ "$SRC_DIR" != "$BASE_DIR" ]; then
    echo -e "${YELLOW}>> Menyiapkan direktori instalasi di $BASE_DIR...${NC}"
    mkdir -p "$BASE_DIR"
    cp -r "$SRC_DIR/"* "$BASE_DIR/" 2>/dev/null || true
fi

# -----------------------------------------------------------------------------
# 1. PERIKSA LINGKUNGAN ANDROID & WAKE-LOCK
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[1/5] Memeriksa perangkat & mengaktifkan Wake-Lock...${NC}"

RAW_ARCH=$(uname -m 2>/dev/null || dpkg --print-architecture 2>/dev/null || echo "arm64")
echo -e "  • Arsitektur CPU : ${CYAN}$RAW_ARCH${NC}"

# Aktifkan wake-lock agar CPU tidak tidur saat layar HP mati
if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock 2>/dev/null || true
    echo -e "  • CPU Wake-Lock  : ${GREEN}Aktif${NC}"
fi

# Izin penyimpanan
if [ ! -d "$HOME/storage" ]; then
    echo ">> Meminta izin penyimpanan internal (Storage)..."
    termux-setup-storage 2>/dev/null || true
    sleep 1
fi

# -----------------------------------------------------------------------------
# 2. INSTALASI DEPENDENSI TERMUX HOST
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[2/5] Memperbarui package Termux & memasang dependensi...${NC}"

# Bersihkan lock dpkg lama jika ada
rm -f "$PREFIX/var/lib/dpkg/lock*" "$PREFIX/var/lib/apt/lists/lock" 2>/dev/null || true
dpkg --configure -a 2>/dev/null || true

# Update repo dan install paket
pkg update -y 2>/dev/null || apt-get update -y 2>/dev/null || true
pkg install -y nodejs openssh curl wget git zip unzip tar proot proot-distro net-tools iproute2 2>/dev/null || true

# Opsi termux-api
pkg install -y termux-api 2>/dev/null || true

# Pastikan Node.js terpasang
if ! command -v node >/dev/null 2>&1; then
    echo ">> Memasang Node.js LTS..."
    pkg install -y nodejs-lts || true
fi

NODE_VER=$(node -v 2>/dev/null || echo "Belum terpasang")
echo -e "${GREEN}✓ Node.js Host: $NODE_VER${NC}"

# -----------------------------------------------------------------------------
# 3. INSTALASI UBUNTU LINUX VPS (RESMI PROOT-DISTRO)
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[3/5] Menyiapkan Distro Ubuntu VPS via proot-distro...${NC}"

PROOT_DISTRO_UBUNTU="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"

if [ ! -d "$PROOT_DISTRO_UBUNTU" ]; then
    echo ">> Mengunduh dan memasang Ubuntu Rootfs resmi Termux..."
    proot-distro install ubuntu || {
        echo -e "${RED}⚠️ Instalasi Ubuntu via proot-distro mengalami kendala. Mencoba mirror ulang...${NC}"
        proot-distro install ubuntu || true
    }
else
    echo -e "${GREEN}✓ Distro Ubuntu sudah terpasang di proot-distro.${NC}"
fi

# Inisialisasi OpenSSH di dalam Ubuntu
if [ -d "$PROOT_DISTRO_UBUNTU" ]; then
    echo ">> Mengonfigurasi OpenSSH & password di dalam Ubuntu VPS..."
    proot-distro login ubuntu -- bash -c "
        mkdir -p /usr/sbin /etc/ssh /run/sshd /var/run/sshd
        echo -e '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d
        chmod +x /usr/sbin/policy-rc.d
        dpkg --configure -a 2>/dev/null || true
        apt-get update -y 2>/dev/null || true
        apt-get install -y --no-install-recommends openssh-server sudo curl wget nano 2>/dev/null || true
        
        # Konfigurasi SSH Port 2222
        cat << 'EOF' > /etc/ssh/sshd_config
Port 2222
ListenAddress 0.0.0.0
PermitRootLogin yes
PasswordAuthentication yes
PermitEmptyPasswords no
UsePAM no
StrictModes no
Subsystem sftp /usr/lib/openssh/sftp-server
EOF
        # Set password default
        echo 'root:ubuntu123' | chpasswd 2>/dev/null || true
        id -u ubuntu >/dev/null 2>&1 || useradd -m -s /bin/bash ubuntu 2>/dev/null || true
        echo 'ubuntu:ubuntu123' | chpasswd 2>/dev/null || true
        usermod -aG sudo ubuntu 2>/dev/null || true
        ssh-keygen -A 2>/dev/null || true
        apt-get clean 2>/dev/null || true
    " 2>/dev/null || true
    echo -e "${GREEN}✓ Ubuntu VPS & OpenSSH (Port 2222) siap!${NC}"
fi

# -----------------------------------------------------------------------------
# 4. MEMASANG HELPER COMMANDS & PERIZINAN SCRIPT
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[4/5] Memasang pintasan perintah CLI Termux...${NC}"

chmod +x "$BASE_DIR"/*.sh "$BASE_DIR/scripts"/*.sh 2>/dev/null || true

PREFIX_BIN="$PREFIX/bin"
if [ -d "$PREFIX_BIN" ]; then
    for cmd in tms-server:start.sh tms-start:start.sh tms-stop:stop.sh tms-restart:scripts/restart.sh tms-status:status.sh tms-update:update.sh tms-fix:scripts/fix-server.sh tms-app:scripts/app-manager.sh tms-backup:scripts/backup.sh tms-restore:scripts/restore.sh ubuntu:scripts/start-ubuntu.sh; do
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

# Setup Autostart Termux:Boot jika aplikasi terpasang
BOOT_DIR="$HOME/.termux/boot"
mkdir -p "$BOOT_DIR"
cat << EOF > "$BOOT_DIR/start-tms.sh"
#!/data/data/com.termux/files/usr/bin/bash
sleep 10
termux-wake-lock 2>/dev/null || true
bash "$BASE_DIR/start.sh" >/dev/null 2>&1 &
EOF
chmod +x "$BOOT_DIR/start-tms.sh"


# -----------------------------------------------------------------------------
# 5. PEMBERSIHAN CACHE & FINISHING
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[5/5] Membersihkan cache instalasi untuk hemat memori...${NC}"
pkg clean 2>/dev/null || true
apt-get clean 2>/dev/null || true
rm -rf "$HOME/.cache"/* 2>/dev/null || true

echo ""
echo -e "${GREEN}┌─────────────────────────────────────────────────────────────┐${NC}"
echo -e "${GREEN}│         ✅ INSTALASI TERMUX MINI SERVER SELESAI!            │${NC}"
echo -e "${GREEN}├─────────────────────────────────────────────────────────────┤${NC}"
echo -e " • Panel Web Server : Port 8080 (Node.js)"
echo -e " • Ubuntu VPS (SSH) : Port 2222 (User: root / Pass: ubuntu123)"
echo -e " • Akses Jarak Jauh : Mendukung Tailscale Otomatis"
echo -e ""
echo -e " 📌 Perintah Cepat di Termux:"
echo -e "   - Jalankan server : ${CYAN}tms-start${NC} (atau ${CYAN}tms-server${NC})"
echo -e "   - Hentikan server : ${CYAN}tms-stop${NC}"
echo -e "   - Restart server  : ${CYAN}tms-restart${NC}"
echo -e "   - Cek status/IP   : ${CYAN}tms-status${NC}"
echo -e "   - Update server   : ${CYAN}tms-update${NC}"
echo -e "   - Auto-repair     : ${CYAN}tms-fix${NC}"
echo -e "   - Masuk ke Ubuntu : ${CYAN}ubuntu${NC}"
echo -e "${GREEN}└─────────────────────────────────────────────────────────────┘${NC}"
echo ""

# Menjalankan server secara otomatis
echo -e "${YELLOW}>> Meluncurkan server sekarang...${NC}"
sleep 1
exec bash "$BASE_DIR/start.sh"
