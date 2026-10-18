#!/bin/bash
# ==============================================================================
# Inisialisasi Ubuntu VPS Pertama Kali
# Mengonfigurasi OpenSSH (Port 2222), User Root & Ubuntu, dan Kebijakan Paket
# ==============================================================================

set -e
export DEBIAN_FRONTEND=noninteractive

echo ">> Menyiapkan konfigurasi OpenSSH & Policy di dalam Ubuntu VPS..."

# Mencegah hang pada systemd/service policy di dalam PRoot
mkdir -p /usr/sbin /etc/ssh /var/run/sshd /run/sshd
cat << 'EOF' > /usr/sbin/policy-rc.d
#!/bin/sh
exit 101
EOF
chmod +x /usr/sbin/policy-rc.d

# Setup DNS resolver yang andal
echo -e "nameserver 1.1.1.1\nnameserver 8.8.8.8" > /etc/resolv.conf

# Perbarui paket dasar jika perlu
dpkg --configure -a 2>/dev/null || true
apt-get update -y 2>/dev/null || true
apt-get install -y --no-install-recommends openssh-server sudo curl wget nano 2>/dev/null || true

# Konfigurasi SSH Daemon Port 2222
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

# Setel password root ke: ubuntu123
echo 'root:ubuntu123' | chpasswd 2>/dev/null || true

# Buat user biasa 'ubuntu' dengan sudo
if ! id -u ubuntu >/dev/null 2>&1; then
    useradd -m -s /bin/bash ubuntu 2>/dev/null || true
fi
echo 'ubuntu:ubuntu123' | chpasswd 2>/dev/null || true
usermod -aG sudo ubuntu 2>/dev/null || true

# Generate host keys jika belum ada
ssh-keygen -A 2>/dev/null || true

# Bersihkan cache apt
apt-get clean 2>/dev/null || true
rm -rf /var/cache/apt/archives/* 2>/dev/null || true

echo "✓ Inisialisasi Ubuntu VPS Selesai! SSH siap di port 2222 (User: root / ubuntu, Pass: ubuntu123)"
