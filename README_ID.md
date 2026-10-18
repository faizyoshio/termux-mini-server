# 🚀 Termux Mini Server & Ubuntu VPS (Tailscale Edition)

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20Termux-22c55e?style=for-the-badge&logo=android" alt="Platform" />
  <img src="https://img.shields.io/badge/Node.js-Tanpa%20Dependensi-0284c7?style=for-the-badge&logo=nodedotjs" alt="Node.js" />
  <img src="https://img.shields.io/badge/VPN-Tailscale%20Mesh-6366f1?style=for-the-badge&logo=tailscale" alt="Tailscale" />
  <img src="https://img.shields.io/badge/Distro-Ubuntu%20PRoot-e11d48?style=for-the-badge&logo=ubuntu" alt="Ubuntu" />
  <img src="https://img.shields.io/badge/Lisensi-MIT-f59e0b?style=for-the-badge" alt="Lisensi" />
</p>

<p align="center">
  <strong>Ubah smartphone Android lama maupun baru menjadi Mini Server Rumah & Distro Linux Ubuntu VPS berkinerja tinggi.</strong><br>
  Dapat diakses secara aman dari mana saja melalui Tailscale VPN Mesh Pribadi — tanpa IP publik statis, tanpa port forwarding modem, dan bebas blokir.
</p>

<p align="center">
  <a href="README.md">English</a> | <strong>Bahasa Indonesia</strong>
</p>

---

## 📖 Gambaran Umum (Overview)

**Termux Mini Server** adalah solusi server mandiri, ringan, dan modern yang dirancang khusus untuk berjalan di perangkat Android menggunakan **Termux**.

Berbeda dengan skrip komunitas lama yang sering rusak akibat tunnel biner yang tidak terawat (seperti error biner Cloudflare pada Android Bionic libc) atau dependensi modul paket yang rentan, proyek ini dibangun dari nol dengan fokus pada **stabilitas maksimal, anti-gagal kompilasi, dan akses remote yang aman**:
- **Tailscale Mesh VPN**: Akses terenkripsi *end-to-end* langsung ke Web Dashboard dan SSH Ubuntu di HP Anda dari laptop, PC, atau perangkat lain, bahkan saat menggunakan data seluler (4G/5G) di balik CGNAT operator.
- **Backend Node.js Murni (Zero Dependencies)**: Dibuat 100% menggunakan modul standar bawaan Node.js (`http`, `fs`, `os`, `child_process`, `crypto`, `net`). **Sama sekali tidak memerlukan kompilasi paket npm eksternal**, sehingga kebal dari error *node-gyp* di arsitektur ARM/ARM64 dan hanya menggunakan RAM ~25–35 MB.
- **Ubuntu Resmi via `proot-distro`**: Memanfaatkan pengelola distribusi resmi dari Termux untuk keandalan jangka panjang, pembaruan paket yang bersih, serta kunci GPG yang selalu valid.

---

## ✨ Fitur Utama

* 🌐 **Web Dashboard Modern Dark Mode (Port 8080)**
  * Tampilan antarmuka gelap yang elegan dan responsif di layar HP, tablet, maupun monitor laptop/PC.
  * Pemantauan telemetri perangkat secara *real-time*: Beban CPU %, Penggunaan RAM, Kapasitas Penyimpanan Disk, Sensor Suhu SoC/CPU, serta Status & Suhu Baterai HP.
* 🔒 **Akses Jarak Jauh Tailscale Terintegrasi**
  * Deteksi otomatis IP Tailscale perangkat (`100.x.y.z`) beserta status koneksinya.
  * Tombol 1-klik untuk menyalin tautan akses Web Dashboard dan perintah terminal SSH jarak jauh.
* 🖥️ **Ubuntu Linux VPS Penuh (Port 2222)**
  * Lingkungan sistem operasi Ubuntu Linux asli berjalan via PRoot tanpa perlu akses *root*.
  * Dilengkapi OpenSSH Server aktif di port `2222` dengan akun user `root` dan `ubuntu`.
  * Masuk langsung ke terminal root Ubuntu dari Termux dengan mengetik perintah `ubuntu`.
* 📁 **Web File Manager Bawaan**
  * Jelajahi direktori lokal Termux (`~`) maupun penyimpanan internal Android (`/sdcard`).
  * Buka, ubah, dan simpan kode atau berkas teks langsung melalui editor browser.
  * Unggah berkas (*upload*) secara streaming dan unduh berkas/folder (otomatis dikompresi ZIP).
* 💻 **Web Bash Console / Streaming Terminal**
  * Jalankan perintah bash Termux langsung dari peramban web.
  * Tampilan *live streaming output* dengan dukungan penghentian perintah **Ctrl + C**.
* ⚡ **Manajer Proses (PM2)**
  * Pantau dan kelola proses aplikasi Node.js serta berkas log server.
* 📱 **Pintasan Kontrol Hardware HP**
  * Kendalikan fitur perangkat: sakelar CPU wake-lock, senter/torch, uji getar, dan penjaga server aktif 24 jam.

---

## 📸 Tampilan Antarmuka (UI/UX Preview)

| 🖥️ Tampilan Dashboard Desktop (Telemetri & Tailscale) | 📱 Tampilan Mobile HP (Layout Responsif) |
| :---: | :---: |
| <img src="screenshots/dashboard_desktop.png" alt="Tampilan Dashboard Desktop" width="100%" /> | <img src="screenshots/dashboard_mobile.png" alt="Tampilan Dashboard Mobile" width="280px" /> |

| 💻 Web Bash Console & Terminal | 📁 Web File Explorer & Text Editor |
| :---: | :---: |
| <img src="screenshots/terminal_desktop.png" alt="Tampilan Web Terminal" width="100%" /> | <img src="screenshots/files_desktop.png" alt="Tampilan File Manager" width="100%" /> |

---

## 🛠️ Spesifikasi & Persyaratan Sistem

| Komponen | Spesifikasi Minimal | Rekomendasi Ideal |
| :--- | :--- | :--- |
| **Sistem Operasi** | Android 7.0 (Nougat / SDK 24) | Android 10 s/d 14+ |
| **Arsitektur CPU** | ARM32 (`armhf`), ARM64 (`aarch64`), x86_64 | ARM64 (`aarch64`) |
| **RAM Fisik HP** | 512 MB | 2 GB atau lebih |
| **Penyimpanan Bebas** | Minimal 1.5 GB | 3 GB+ (untuk aplikasi & data) |
| **Status Root** | **Tanpa Root (Non-Root)** | Mendukung HP Non-Root maupun Root |

> ⚠️ **PERINGATAN PENTING**: **JANGAN** menginstal aplikasi Termux dari Google Play Store! Versi di Play Store sudah tidak diperbarui sejak tahun 2020 dan repositori paketnya sudah mati total. Selalu pasang Termux dari **[F-Droid](https://f-droid.org/packages/com.termux/)** atau **[GitHub Releases Resmi Termux](https://github.com/termux/termux-app/releases)**.

---

## 🚀 Panduan Instalasi Cepat (1-Klik)

Buka aplikasi **Termux** di HP Anda, lalu salin dan tempel perintah berikut:

```bash
pkg update -y && pkg install git -y
git clone https://github.com/faizyoshio/termux-mini-server.git ~/termux-mini-server
cd ~/termux-mini-server
bash install.sh
```

### Yang Dijalankan `install.sh` Secara Otomatis:
1. Meminta izin penyimpanan internal Android (`termux-setup-storage`) dan mengaktifkan CPU Wake-Lock (`termux-wake-lock`).
2. Memasang seluruh dependensi sistem: `nodejs`, `openssh`, `proot`, `proot-distro`, `curl`, `wget`, `zip`, `unzip`, `tar`, `net-tools`.
3. Mengunduh dan memasang distro Ubuntu resmi melalui `proot-distro` serta menyetel konfigurasi OpenSSH di port `2222`.
4. Membuat pintasan perintah terminal global (`tms-server`, `tms-stop`, `tms-status`, `ubuntu`).
5. Membersihkan sisa *cache* instalasi dan langsung menyalakan server secara otomatis.

---

## 🔒 Panduan Menghubungkan Akses Jarak Jauh (Tailscale)

Tailscale membuat jaringan privat terenkripsi (*mesh VPN WireGuard*) antar perangkat Anda, sehingga Anda dapat mengakses server Android dari mana saja tanpa perlu mengekspos port ke internet publik.

```
+------------------------------------------------------------+
|                   Tailscale Private Mesh                   |
|                                                            |
|   Laptop / PC (Klien)               HP Android (Server)    |
|   100.x.y.10                        100.x.y.20             |
|   [ Browser / SSH Client ]  =====>  [ Port 8080 (Web) ]    |
|                                     [ Port 2222 (SSH) ]    |
+------------------------------------------------------------+
```

### Langkah 1: Di HP Server (Android)
1. Pasang aplikasi resmi **[Tailscale di Google Play Store](https://play.google.com/store/apps/details?id=com.tailscale.ipn)** atau F-Droid.
2. Masuk (*Sign in*) menggunakan akun Google, GitHub, Microsoft, atau Apple Anda.
3. Geser tombol koneksi ke **Connected** (izinkan pembuatan profil VPN Android).
4. Catat alamat IP Tailscale yang diberikan (contoh: `100.85.12.34`).

### Langkah 2: Di Laptop / Komputer Klien (Windows, macOS, Linux)
1. Unduh dan pasang aplikasi Tailscale dari **[tailscale.com/download](https://tailscale.com/download)**.
2. Masuk menggunakan akun yang **sama persis** dengan yang digunakan di HP.
3. Sambungkan Tailscale di laptop Anda.

### Langkah 3: Akses Server Anda
* **Web Dashboard**: Buka browser di laptop dan kunjungi:
  ```text
  http://<IP-TAILSCALE-HP>:8080
  ```
  *(Contoh: `http://100.85.12.34:8080`)*
* **SSH Ubuntu VPS**: Buka terminal laptop Anda (PowerShell / Command Prompt / macOS Terminal) dan jalankan:
  ```bash
  ssh root@<IP-TAILSCALE-HP> -p 2222
  ```
  *(Password default: `ubuntu123`)*

---

## 🔑 Kredensial Default

| Layanan | Protokol / Port | Kredensial Default |
| :--- | :--- | :--- |
| **Web Dashboard** | HTTP / Port `8080` | **Username**: `admin`<br>**Password**: `admin123` |
| **Ubuntu VPS (SSH)** | SSH / Port `2222` | **User**: `root` atau `ubuntu`<br>**Password**: `ubuntu123` |

> 💡 *Password Web Dashboard dapat diganti kapan saja melalui tab **Pengaturan** di halaman panel.*

---

## ⌨️ Daftar Perintah Cepat (CLI Shortcuts)

Setelah instalasi selesai, Anda dapat menjalankan perintah singkat ini langsung dari mana saja di terminal Termux:

| Perintah | Deskripsi Fungsi |
| :--- | :--- |
| `tms-server` | Menjalankan Web Dashboard (port 8080) dan Ubuntu VPS SSH (port 2222). |
| `tms-status` | Memeriksa status port, menampilkan IP Wi-Fi lokal dan IP Tailscale aktif. |
| `tms-stop` | Menghentikan seluruh proses server dan Ubuntu VPS secara aman. |
| `ubuntu` | Masuk langsung ke sesi interaktif root di dalam distro Ubuntu Linux VPS. |

---

## 📁 Struktur Direktori Repositori

```text
termux-mini-server/
├── install.sh                # Skrip instalasi otomatis 1-klik
├── start.sh                  # Skrip peluncur layanan (Panel + VPS SSH)
├── stop.sh                   # Skrip penghenti layanan
├── status.sh                 # Skrip diagnostik status port & IP
├── README.md                 # Dokumentasi Bahasa Inggris (Utama)
├── README_ID.md              # Dokumentasi Bahasa Indonesia (Kedua)
├── panel/
│   ├── server.js             # Backend Node.js murni tanpa dependensi luar
│   ├── auth-config.json      # Berkas penyimpanan kredensial login
│   └── public/
│       └── index.html        # Antarmuka web panel modern responsif
└── scripts/
    ├── start-ubuntu.sh       # Wrapper eksekusi Ubuntu PRoot & daemon SSH
    ├── setup-tailscale.sh    # Alat bantu pengecekan koneksi Tailscale
    └── vps-init.sh           # Skrip konfigurasi awal internal Ubuntu
```

---

## ❄️ Panduan Stabilitas 24/7 (Non-Stop Server)

Jika smartphone Android digunakan sebagai server yang menyala terus menerus:

1. **Nonaktifkan Pembatasan Baterai Android**:
   * Buka *Pengaturan HP* -> *Aplikasi* -> *Termux* -> *Baterai* -> Pilih **Tidak Dibatasi / Unrestricted**.
   * Lakukan hal yang sama untuk aplikasi **Tailscale**.
2. **Pastikan CPU Wake-Lock Aktif**:
   * Skrip instalasi telah otomatis menyalakan wake-lock agar CPU HP tidak masuk ke mode *deep sleep* saat layar terkunci.
3. **Android 12+ (Solusi Phantom Process Killer)**:
   * Pada Android 12 ke atas, sistem dapat membunuh proses latar belakang Termux. Untuk mematikannya, jalankan perintah ADB ini sekali dari laptop/PC:
     ```bash
     adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"
     ```
4. **Manajemen Suhu Perangkat**:
   * Lepaskan *casing* pelindung HP.
   * Dirikan HP atau arahkan kipas mini USB kecil ke bodi belakang HP agar suhu tetap adem.
   * Gunakan kepala charger dan kabel yang berkualitas baik.

---

## 🤝 Kontribusi

Kontribusi, laporan *bug*, serta saran fitur baru sangat disambut baik! Silakan buat *issue* atau kirimkan *pull request* di [GitHub Repository](https://github.com/faizyoshio/termux-mini-server).

---

## 📄 Lisensi

Proyek ini bersifat sumber terbuka (*open-source*) di bawah lisensi [MIT License](LICENSE).  
Dikembangkan dengan ❤️ oleh [Faiz Yoshio](https://github.com/faizyoshio).
