#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Termux Mini Server — 1-Click App & Service Manager
# Mengelola instalasi dan kontrol layanan: AdGuard Home, MariaDB, PostgreSQL, Caddy, Syncthing, Aria2
# ==============================================================================

export PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
[ -z "$HOME" ] || [ "$HOME" = "/" ] || [ "$HOME" = "/root" ] && [ -d "/data/data/com.termux/files/home" ] && export HOME="/data/data/com.termux/files/home"
export PATH="/data/data/com.termux/files/usr/bin:$PREFIX/bin:$PREFIX/bin/applets:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

APP="$1"
ACTION="$2"

if [ -z "$APP" ] || [ -z "$ACTION" ]; then
    echo "Penggunaan: bash scripts/app-manager.sh <adguard|mariadb|postgresql|caddy|syncthing|aria2> <install|start|stop|status>"
    exit 1
fi

is_port_active() {
    local port="$1"
    netstat -tuln 2>/dev/null | grep -q ":${port} " && return 0
    ss -tuln 2>/dev/null | grep -q ":${port} " && return 0
    return 1
}

case "$APP" in
    adguard)
        case "$ACTION" in
            install)
                echo ">> Memasang AdGuard Home..."
                mkdir -p "$HOME/AdGuardHome"
                ARCH=$(uname -m)
                AG_ARCH="arm64"
                case "$ARCH" in
                    aarch64|arm64*) AG_ARCH="arm64" ;;
                    armv7*|armhf)   AG_ARCH="armv7" ;;
                    x86_64|amd64)   AG_ARCH="amd64" ;;
                esac
                curl -sL "https://static.adguard.com/adguardhome/release/AdGuardHome_linux_${AG_ARCH}.tar.gz" -o "$HOME/ag.tar.gz"
                tar -xzf "$HOME/ag.tar.gz" -C "$HOME"
                rm -f "$HOME/ag.tar.gz"
                chmod +x "$HOME/AdGuardHome/AdGuardHome"
                echo "✓ AdGuard Home berhasil dipasang di $HOME/AdGuardHome"
                ;;
            start)
                if is_port_active 3000; then
                    echo "✓ AdGuard Home sudah berjalan di port 3000."
                elif [ -f "$HOME/AdGuardHome/AdGuardHome" ]; then
                    nohup "$HOME/AdGuardHome/AdGuardHome" -w "$HOME/AdGuardHome" > "$HOME/AdGuardHome/adguard.log" 2>&1 &
                    sleep 1
                    echo "✓ AdGuard Home dijalankan (Web UI: http://<IP>:3000)"
                else
                    echo "❌ AdGuard Home belum terpasang. Jalankan install terlebih dahulu."
                fi
                ;;
            stop)
                pkill -f "AdGuardHome" 2>/dev/null || true
                echo "✓ AdGuard Home dihentikan."
                ;;
            status)
                is_port_active 3000 && echo "RUNNING" || echo "STOPPED"
                ;;
        esac
        ;;

    mariadb)
        case "$ACTION" in
            install)
                echo ">> Memasang MariaDB Server di Ubuntu VPS..."
                proot-distro login ubuntu -- bash -c "
                    export DEBIAN_FRONTEND=noninteractive
                    apt-get update -y && apt-get install -y mariadb-server
                    service mariadb start || true
                    mysql -e 'CREATE DATABASE IF NOT EXISTS appdb;' 2>/dev/null || true
                "
                echo "✓ MariaDB Server berhasil dipasang (Port 3306)."
                ;;
            start)
                proot-distro login ubuntu -- service mariadb start 2>/dev/null || true
                echo "✓ MariaDB dimulai."
                ;;
            stop)
                proot-distro login ubuntu -- service mariadb stop 2>/dev/null || true
                echo "✓ MariaDB dihentikan."
                ;;
            status)
                is_port_active 3306 && echo "RUNNING" || echo "STOPPED"
                ;;
        esac
        ;;

    postgresql)
        case "$ACTION" in
            install)
                echo ">> Memasang PostgreSQL di Ubuntu VPS..."
                proot-distro login ubuntu -- bash -c "
                    export DEBIAN_FRONTEND=noninteractive
                    apt-get update -y && apt-get install -y postgresql postgresql-contrib
                    service postgresql start || true
                "
                echo "✓ PostgreSQL Server berhasil dipasang (Port 5432)."
                ;;
            start)
                proot-distro login ubuntu -- service postgresql start 2>/dev/null || true
                echo "✓ PostgreSQL dimulai."
                ;;
            stop)
                proot-distro login ubuntu -- service postgresql stop 2>/dev/null || true
                echo "✓ PostgreSQL dihentikan."
                ;;
            status)
                is_port_active 5432 && echo "RUNNING" || echo "STOPPED"
                ;;
        esac
        ;;

    caddy)
        case "$ACTION" in
            install)
                echo ">> Memasang Caddy Web Server..."
                pkg install -y caddy
                echo "✓ Caddy berhasil dipasang."
                ;;
            start)
                if is_port_active 2019 || is_port_active 80; then
                    echo "✓ Caddy sudah aktif."
                else
                    nohup caddy run > "$HOME/caddy.log" 2>&1 &
                    sleep 1
                    echo "✓ Caddy berjalan."
                fi
                ;;
            stop)
                caddy stop 2>/dev/null || pkill -f "caddy" 2>/dev/null || true
                echo "✓ Caddy dihentikan."
                ;;
            status)
                (is_port_active 2019 || is_port_active 80) && echo "RUNNING" || echo "STOPPED"
                ;;
        esac
        ;;

    syncthing)
        case "$ACTION" in
            install)
                echo ">> Memasang Syncthing File Sync..."
                pkg install -y syncthing
                echo "✓ Syncthing berhasil dipasang."
                ;;
            start)
                if is_port_active 8384; then
                    echo "✓ Syncthing sudah aktif di port 8384."
                else
                    nohup syncthing -no-browser -gui-address="0.0.0.0:8384" > "$HOME/syncthing.log" 2>&1 &
                    sleep 1
                    echo "✓ Syncthing berjalan (Web UI: http://<IP>:8384)."
                fi
                ;;
            stop)
                pkill -f "syncthing" 2>/dev/null || true
                echo "✓ Syncthing dihentikan."
                ;;
            status)
                is_port_active 8384 && echo "RUNNING" || echo "STOPPED"
                ;;
        esac
        ;;

    aria2)
        case "$ACTION" in
            install)
                echo ">> Memasang Aria2 RPC Download Daemon..."
                pkg install -y aria2
                mkdir -p "$HOME/downloads"
                echo "✓ Aria2 berhasil dipasang."
                ;;
            start)
                if is_port_active 6800; then
                    echo "✓ Aria2 RPC sudah aktif di port 6800."
                else
                    nohup aria2c --enable-rpc --rpc-listen-all --rpc-allow-origin-all --dir="$HOME/downloads" --max-connection-per-server=16 > "$HOME/aria2.log" 2>&1 &
                    sleep 1
                    echo "✓ Aria2 RPC berjalan (Port 6800)."
                fi
                ;;
            stop)
                pkill -f "aria2c" 2>/dev/null || true
                echo "✓ Aria2 dihentikan."
                ;;
            status)
                is_port_active 6800 && echo "RUNNING" || echo "STOPPED"
                ;;
        esac
        ;;

    *)
        echo "Aplikasi tidak dikenal: $APP"
        exit 1
        ;;
esac
