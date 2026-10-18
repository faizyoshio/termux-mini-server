# 🚀 Termux Mini Server & Ubuntu VPS (Tailscale Edition)

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20Termux-22c55e?style=for-the-badge&logo=android" alt="Platform" />
  <img src="https://img.shields.io/badge/Node.js-Zero%20Dependency-0284c7?style=for-the-badge&logo=nodedotjs" alt="Node.js" />
  <img src="https://img.shields.io/badge/VPN-Tailscale%20Mesh-6366f1?style=for-the-badge&logo=tailscale" alt="Tailscale" />
  <img src="https://img.shields.io/badge/Distro-Ubuntu%20PRoot-e11d48?style=for-the-badge&logo=ubuntu" alt="Ubuntu" />
  <img src="https://img.shields.io/badge/License-MIT-f59e0b?style=for-the-badge" alt="License" />
</p>

<p align="center">
  <strong>Transform any Android smartphone into a high-performance, energy-efficient Home Server & Ubuntu Linux VPS.</strong><br>
  Accessible securely from anywhere in the world via Tailscale private mesh VPN — no static public IP, port forwarding, or domain required.
</p>

<p align="center">
  <strong>English</strong> | <a href="README_ID.md">Bahasa Indonesia</a>
</p>

---

## 📖 Overview

**Termux Mini Server** is a complete, lightweight, and modern server solution designed to run seamlessly on Android devices using **Termux**. 

Unlike legacy community scripts that often break due to unmaintained binary tunnels (such as broken Cloudflare binaries on Android Bionic libc) or fragile package dependencies, this project is built from the ground up for **maximum stability, zero native build errors, and secure remote access**:
- **Tailscale Mesh VPN**: Direct, end-to-end encrypted access to your phone's web dashboard and Ubuntu SSH from your PC, laptop, or second phone, even behind cellular carrier CGNAT (4G/5G).
- **Zero-Dependency Node.js Backend**: Built strictly using Node.js core modules (`http`, `fs`, `os`, `child_process`, `crypto`, `net`). It requires **zero external npm compilations**, eliminating all ARM/ARM64 node-gyp build failures and consuming only ~25–35 MB of RAM.
- **Official `proot-distro` Ubuntu**: Employs Termux's official distribution manager for rock-solid stability, verified GPG keys, and clean updates.

---

## ✨ Features

* 🌐 **Modern Dark-Mode & AMOLED Web Dashboard (Port 8080)**
  * Sleek, mobile-friendly interface designed with high-contrast dark aesthetics and **AMOLED Pitch Black (`#000000`)** toggle for maximum battery conservation.
  * Real-time hardware telemetry: CPU load %, RAM usage, Disk storage, SoC/CPU thermal sensors, battery status, and active network speed (RX/TX KB/s) rendered via zero-dependency HTML5 Canvas sparklines.
  * Live **Internet Ping Latency** to Cloudflare (`1.1.1.1`) and automatic **Overheat Safety Banner** when thermal levels exceed 45°C.
* 🔒 **Seamless Tailscale Remote Access**
  * Automatic detection of your Tailscale IP (`100.x.y.z`) and connection state.
  * One-click copying of remote Web Dashboard and SSH terminal URLs without port-forwarding or public IP exposure.
* 🖥️ **Full Ubuntu Linux VPS (Port 2222)**
  * Genuine Ubuntu environment running via PRoot (no root required).
  * Pre-configured OpenSSH Server listening on port `2222` with `root` and `ubuntu` user accounts.
  * Built-in **SSH Public Key Manager** (`authorized_keys`) for passwordless SSH logins from your PC.
  * Instant interactive terminal entry with the `ubuntu` command.
* 📦 **1-Click Self-Hosted App Store & Services**
  * Install and control popular server packages directly from the web panel or CLI:
    * **AdGuard Home**: Network-wide DNS ad-blocker & privacy protector (Port `3000`).
    * **MariaDB Server**: Production-grade MySQL-compatible relational database (Port `3306`).
    * **PostgreSQL Server**: Robust object-relational database engine (Port `5432`).
    * **Caddy Web Server**: Automated HTTPS reverse proxy and static site host (Port `80`).
    * **Syncthing**: Decentralized, encrypted continuous file synchronization (Port `8384`).
    * **Aria2 RPC**: Multi-source high-speed downloader and torrent engine (Port `6800`).
* 🛡️ **Automated Backup & Restore Engine**
  * 1-Click creation of timestamped `.tar.gz` system archives saved to Android internal storage (`/sdcard/TMS_Backups`).
  * Easily preserve and migrate server configurations, user databases, and files across devices.
* 🔄 **Termux:Boot Autostart Integration**
  * Pre-configured script in `~/.termux/boot/start-tms.sh` to automatically launch your server whenever the phone reboots.
* 📁 **Built-in Web File Manager**
  * Browse Termux home (`~`) and Android shared storage (`/sdcard`).
  * In-browser code and text editor.
  * Multi-file streaming uploads and zipped directory downloads.
* 💻 **Web Bash Console / Streaming Terminal**
  * Execute bash commands directly from your browser.
  * Real-time chunked streaming output with interactive **Ctrl + C** job termination.
* ⚡ **Process Manager (PM2) & Anti-Brute Force Login**
  * Monitor and inspect background Node.js processes and server logs.
  * IP-based rate-limiter locks login attempts for 5 minutes after 5 consecutive failed credentials to stop dictionary attacks.
* 📱 **Hardware Quick Controls**
  * Toggle CPU wake-lock, flash torch, trigger vibration, and keep the phone awake 24/7.

---

## 📸 Interface Preview (UI/UX)

| 🖥️ Desktop Dashboard (Live Telemetry & Tailscale) | 📱 Mobile View (Responsive Layout) |
| :---: | :---: |
| <img src="screenshots/dashboard_desktop.png" alt="Desktop Dashboard View" width="100%" /> | <img src="screenshots/dashboard_mobile.png" alt="Mobile Dashboard View" width="280px" /> |

| 💻 Web Bash Console & Terminal | 📁 Web File Explorer & Text Editor |
| :---: | :---: |
| <img src="screenshots/terminal_desktop.png" alt="Web Terminal View" width="100%" /> | <img src="screenshots/files_desktop.png" alt="Web File Explorer View" width="100%" /> |

---

## 🛠️ System Requirements

| Specification | Minimum | Recommended |
| :--- | :--- | :--- |
| **Operating System** | Android 7.0 (Nougat / SDK 24) | Android 10 s/d 14+ |
| **CPU Architecture** | ARM32 (`armhf`), ARM64 (`aarch64`), x86_64 | ARM64 (`aarch64`) |
| **RAM** | 512 MB | 2 GB or more |
| **Free Storage** | 1.5 GB | 3 GB+ (for apps & files) |
| **Root Status** | **No Root Required** | Works on both Rooted & Non-Rooted |

> ⚠️ **IMPORTANT**: Do **NOT** install Termux from Google Play Store! The Play Store build has been abandoned since 2020 and its package mirrors are completely non-functional. Always install Termux from **[F-Droid](https://f-droid.org/packages/com.termux/)** or **[GitHub Releases](https://github.com/termux/termux-app/releases)**.

---

## 🚀 Quick Start (1-Click Installation)

Open the **Termux** app on your phone, then copy and paste this command:

```bash
pkg update -y && pkg install git -y
git clone https://github.com/faizyoshio/termux-mini-server.git ~/termux-mini-server
cd ~/termux-mini-server
bash install.sh
```

### What `install.sh` Does Automatically:
1. Acquires Android storage permissions (`termux-setup-storage`) and enables CPU Wake-Lock (`termux-wake-lock`).
2. Installs essential host packages: `nodejs`, `openssh`, `proot`, `proot-distro`, `curl`, `wget`, `zip`, `unzip`, `tar`, `net-tools`.
3. Sets up the official Ubuntu rootfs via `proot-distro` and configures OpenSSH on port `2222`.
4. Installs global CLI helper shortcuts (`tms-server`, `tms-stop`, `tms-status`, `tms-fix`, `tms-update`, `ubuntu`, `tms-app`, `tms-backup`, `tms-restore`).
5. Cleans up package caches and automatically launches the server.

---

## 🔄 Updating Without Reinstallation

You do **NOT** need to reinstall Termux Mini Server or wipe your existing data when new features or bug fixes are published. You can update safely in-place:

### ⚡ Quick Shortcut (For Ongoing Updates):
Once installed or updated, simply open Termux from anywhere and run:
```bash
tms-update
```

### 🛠️ First-Time Update (If `tms-update` is Not Yet Installed):
If your current installation was cloned before `tms-update` was released, run this command to safely sync with the latest release and register `tms-update`:
```bash
cd ~/termux-mini-server && git fetch origin main && git reset --hard origin/main && bash update.sh
```
*After running this once, the `tms-update` command will be permanently available in your Termux terminal!*

> 🔒 **Safe & Non-Destructive**: The updater preserves your custom administrator credentials (`auth-config.json`), installed 1-Click Apps, and Ubuntu filesystem data. It pulls the latest codebase, refreshes file execution permissions, re-links all global CLI commands, and gracefully restarts the web panel if it is currently running.

---

## 🔒 Tailscale Remote Access Setup

Tailscale creates an encrypted private mesh network (WireGuard-based) between your devices, allowing you to access your Android server from anywhere without exposing ports to the public internet.

```
+------------------------------------------------------------+
|                    Tailscale Private Mesh                  |
|                                                            |
|   Laptop / PC (Client)              Android Phone (Server) |
|   100.x.y.10                        100.x.y.20             |
|   [ Browser / SSH Client ]  =====>  [ Port 8080 (Web) ]    |
|                                     [ Port 2222 (SSH) ]    |
+------------------------------------------------------------+
```

### Step 1: On Your Android Phone
1. Install the official **[Tailscale App from Google Play Store](https://play.google.com/store/apps/details?id=com.tailscale.ipn)** or F-Droid.
2. Sign in with your Google, GitHub, Microsoft, or Apple account.
3. Toggle the connection switch to **Connected** (allow the Android VPN configuration).
4. Note the assigned Tailscale IP address (e.g., `100.85.12.34`).

### Step 2: On Your Laptop / Computer (Windows, macOS, Linux)
1. Download and install Tailscale from **[tailscale.com/download](https://tailscale.com/download)**.
2. Sign in with the **exact same account** used on your Android phone.
3. Connect Tailscale.

### Step 3: Access Your Server
* **Web Dashboard**: Open your laptop browser and navigate to:
  ```text
  http://<PHONE-TAILSCALE-IP>:8080
  ```
  *(Example: `http://100.85.12.34:8080`)*
* **Ubuntu VPS SSH**: Open your terminal (PowerShell, Command Prompt, macOS Terminal) and run:
  ```bash
  ssh root@<PHONE-TAILSCALE-IP> -p 2222
  ```
  *(Default password: `ubuntu123`)*

---

## 🔑 Default Credentials

| Service | Protocol / Port | Default Credentials |
| :--- | :--- | :--- |
| **Web Dashboard** | HTTP / Port `8080` | **Username**: `admin`<br>**Password**: `admin123` |
| **Ubuntu VPS (SSH)** | SSH / Port `2222` | **User**: `root` or `ubuntu`<br>**Password**: `ubuntu123` |

> 💡 *You can change your Web Dashboard username and password anytime via the **Settings** tab in the web panel.*

---

## 🛡️ 24/7 Server Persistence & Anti-Kill Guide

Android smartphones aggressively suspend background tasks and kill processes to save battery. To ensure your Termux Mini Server runs **24/7 without interruption**:

### 1. Run Auto-Repair & Stabilizer (`tms-fix`)
If your server ever stops unexpectedly, ports fail to bind, or Termux is terminated by the system, simply run:
```bash
tms-fix
```
What `tms-fix` does automatically:
- Acquires an Android CPU Wake-Lock (`termux-wake-lock`) so CPU never enters deep sleep when the screen turns off.
- Mitigates the Android 12–14 **Phantom Process Killer** limit (`max_phantom_processes`).
- Verifies and restores all `$PREFIX/bin` CLI shortcuts (`tms-server`, `tms-fix`, `tms-update`, etc.).
- Verifies `Termux:Boot` auto-launch scripts.
- Cleans orphaned lockfiles and restarts crashed background services (Web Panel & Ubuntu VPS OpenSSH).

### 2. Android Battery Optimization Settings (Crucial)
1. Open phone **Settings > Apps > Termux > Battery** (or *App Battery Usage*).
2. Set battery policy to **Unrestricted** (or *Don't Optimize / Tidak Dibatasi*).
3. Open your phone's **Recent Apps / Multitasking Screen**, find Termux, and tap the **Lock Icon** 🔒 to prevent task cleaners from closing it.

---

## ⌨️ CLI Shortcut Commands

Once installed, you can execute these commands from anywhere in your Termux terminal:

| Command | Action |
| :--- | :--- |
| `tms-server` | Launches both the Web Dashboard (port 8080) and Ubuntu VPS SSH (port 2222). |
| `tms-status` | Displays live service status, active ports, Local Wi-Fi IP, and Tailscale IP. |
| `tms-fix` | **24/7 Anti-Kill & Auto-Repair**: Acquires wake-lock, mitigates phantom killer, and restarts dead services. |
| `tms-stop` | Safely terminates all panel and VPS processes. |
| `tms-update` | Updates the server codebase to latest GitHub version without losing data. |
| `tms-app` | Manage 1-Click Apps (`tms-app [adguard|mariadb|postgresql|caddy|syncthing|aria2] [install|start|stop|status]`). |
| `tms-backup` | Generates a timestamped `.tar.gz` archive of configurations, databases, and panel data. |
| `tms-restore` | Restores server data from a specified backup archive. |
| `ubuntu` | Drops directly into the root terminal of your Ubuntu Linux VPS. |

---

## 📁 Repository Structure

```text
termux-mini-server/
├── install.sh                # 1-Click interactive installer & Termux:Boot setup
├── update.sh                 # Safe in-place updater (pulls latest code & reloads panel)
├── start.sh                  # Service launcher (Panel + VPS SSH + Wake-Lock)
├── stop.sh                   # Graceful service shutdown
├── status.sh                 # Status & IP diagnosis script
├── README.md                 # English documentation (Primary)
├── README_ID.md              # Indonesian documentation (Secondary)
├── panel/
│   ├── server.js             # Pure Node.js zero-dependency backend
│   ├── auth-config.json      # Administrator credentials storage
│   └── public/
│       └── index.html        # Single-page modern responsive web panel
└── scripts/
    ├── fix-server.sh         # 24/7 Anti-kill stabilizer & auto-repair engine
    ├── app-manager.sh        # 1-Click App Store backend manager
    ├── backup.sh             # Automated system backup generator
    ├── restore.sh            # System restore utility
    ├── start-ubuntu.sh       # Ubuntu PRoot execution & SSH daemon script
    ├── setup-tailscale.sh    # Tailscale connectivity checker
    └── vps-init.sh           # Internal Ubuntu initial setup script
```

---

## ❄️ 24/7 Stability & Optimization Guide

If you intend to run your Android device as an uninterrupted, always-on server:

1. **Disable Android Battery Restrictions**:
   * Go to Android *Settings* -> *Apps* -> *Termux* -> *Battery* -> Select **Unrestricted / No Restrictions**.
   * Perform the same step for the **Tailscale** app.
2. **Ensure Wake-Lock is Active**:
   * The installer automatically enables wake-lock, preventing the Android OS from putting the CPU into deep sleep when the screen turns off.
3. **Android 12+ (Phantom Process Killer Fix)**:
   * Modern Android versions may kill background processes if they exceed a threshold. To prevent this, run this one-time ADB command from your PC:
     ```bash
     adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"
     ```
4. **Thermal Management**:
   * Remove any protective phone case.
   * Place the phone in an upright position or use a cheap 5V USB cooling fan blowing against the back cover.
   * Use a reliable, certified charging cable to preserve battery health.

---

## 🤝 Contributing

Contributions, bug reports, and feature suggestions are welcome! Feel free to open an issue or submit a pull request on the [GitHub Repository](https://github.com/faizyoshio/termux-mini-server).

---

## 📄 License

This project is open-source and released under the [MIT License](LICENSE).  
Developed with ❤️ by [Faiz Yoshio](https://github.com/faizyoshio).
