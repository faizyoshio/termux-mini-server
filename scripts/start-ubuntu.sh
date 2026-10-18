#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Script Launcher Ubuntu Linux VPS di Termux
# Mendukung mode interaktif dan mode daemon (OpenSSH Port 2222)
# ==============================================================================

export PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
[ -z "$HOME" ] || [ "$HOME" = "/" ] || [ "$HOME" = "/root" ] && [ -d "/data/data/com.termux/files/home" ] && export HOME="/data/data/com.termux/files/home"
export PATH="/data/data/com.termux/files/usr/bin:$PREFIX/bin:$PREFIX/bin/applets:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

UBUNTU_DIR="$HOME/ubuntu-fs"
PROOT_DISTRO_DIR="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"

is_port_listening() {
    local port="$1"
    netstat -tuln 2>/dev/null | grep -q ":${port} " && return 0
    ss -tuln 2>/dev/null | grep -q ":${port} " && return 0
    return 1
}

# Mode 1: Menjalankan SSH Server di background (--daemon)
if [ "$1" = "--daemon" ]; then
    if is_port_listening 2222; then
        echo "✓ VPS OpenSSH sudah aktif di port 2222."
        exit 0
    fi

    echo ">> Menjalankan OpenSSH Server di dalam Ubuntu VPS (Port 2222)..."

    # Jika menggunakan proot-distro resmi
    if command -v proot-distro >/dev/null 2>&1 && [ -d "$PROOT_DISTRO_DIR" ]; then
        nohup proot-distro login ubuntu -- bash -c "
            mkdir -p /run/sshd /var/run/sshd
            chmod 0755 /run/sshd /var/run/sshd
            /usr/sbin/sshd -D
        " >/dev/null 2>&1 &
        sleep 1
        echo "✓ OpenSSH Server berhasil dijalankan via proot-distro (Port 2222)."
        exit 0
    fi

    # Jika menggunakan direktori rootfs mandiri ($UBUNTU_DIR)
    if [ -d "$UBUNTU_DIR" ]; then
        unset LD_PRELOAD
        export PROOT_NO_SECCOMP=1
        nohup proot \
            --link2symlink \
            -0 \
            -r "$UBUNTU_DIR" \
            -b /dev \
            -b /dev/pts \
            -b /proc \
            -b /sys \
            -b /sdcard \
            -b /data/data/com.termux/files:/data/data/com.termux/files \
            -w /root \
            /usr/sbin/sshd -D >/dev/null 2>&1 &
        sleep 1
        echo "✓ OpenSSH Server berhasil dijalankan via proot (Port 2222)."
        exit 0
    fi

    echo "❌ Direktori Ubuntu VPS belum terpasang. Jalankan install.sh terlebih dahulu!"
    exit 1
fi

# Mode 2: Masuk ke Terminal Interaktif Ubuntu
if command -v proot-distro >/dev/null 2>&1 && [ -d "$PROOT_DISTRO_DIR" ]; then
    exec proot-distro login ubuntu "$@"
elif [ -d "$UBUNTU_DIR" ]; then
    unset LD_PRELOAD
    export PROOT_NO_SECCOMP=1
    exec proot \
        --link2symlink \
        -0 \
        -r "$UBUNTU_DIR" \
        -b /dev \
        -b /dev/pts \
        -b /proc \
        -b /sys \
        -b /sdcard \
        -b /data/data/com.termux/files:/data/data/com.termux/files \
        -w /root \
        /bin/bash --login "$@"
else
    echo "❌ Ubuntu VPS belum terpasang. Jalankan bash install.sh!"
    exit 1
fi
