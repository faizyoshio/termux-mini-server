/**
 * Termux Mini Server — Web Dashboard & Server Manager (Tailscale Edition)
 * Zero external npm dependencies — Pure Node.js standard library.
 * Sangat hemat RAM (~25-35MB), 100% kompatibel di Android ARM32/ARM64/x86_64.
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { spawn, exec, execSync } = require('child_process');
const crypto = require('crypto');
const net = require('net');

// ------------------------------------------------------------------
// KONFIGURASI & PATHS
// ------------------------------------------------------------------
const BASE_DIR = path.resolve(__dirname, '..');
const LOG_DIR = path.join(BASE_DIR, 'logs');
const AUTH_CONFIG_FILE = path.join(__dirname, 'auth-config.json');

const PORT = parseInt(process.env.PANEL_PORT || process.env.PORT || '8080', 10);
const TERMUX_HOME = process.env.HOME || '/data/data/com.termux/files/home';
const DEFAULT_ROOT_DIR = fs.existsSync(TERMUX_HOME) ? TERMUX_HOME : BASE_DIR;

// Pastikan direktori log tersedia
if (!fs.existsSync(LOG_DIR)) {
  try { fs.mkdirSync(LOG_DIR, { recursive: true }); } catch (e) {}
}

// ------------------------------------------------------------------
// AUTENTIKASI & SESI
// ------------------------------------------------------------------
let authConfig = { username: 'admin', password: 'admin123' };

function loadAuthConfig() {
  try {
    if (fs.existsSync(AUTH_CONFIG_FILE)) {
      const data = JSON.parse(fs.readFileSync(AUTH_CONFIG_FILE, 'utf8'));
      if (data.username) authConfig.username = data.username.trim();
      if (data.password) authConfig.password = data.password.trim();
    }
  } catch (e) {
    console.error('Error loading auth-config.json:', e.message);
  }
}
loadAuthConfig();

function saveAuthConfig(username, password) {
  authConfig.username = username;
  authConfig.password = password;
  try {
    fs.writeFileSync(AUTH_CONFIG_FILE, JSON.stringify(authConfig, null, 2), 'utf8');
    return true;
  } catch (e) {
    console.error('Error saving auth-config.json:', e.message);
    return false;
  }
}

const activeSessions = new Map(); // token -> { user, expiresAt, ip }

function createSession(user, ip) {
  const token = crypto.randomBytes(24).toString('hex');
  const expiresAt = Date.now() + 7 * 24 * 60 * 60 * 1000; // 7 hari
  activeSessions.set(token, { user, expiresAt, ip });
  return token;
}

function validateSession(token) {
  if (!token || !activeSessions.has(token)) return null;
  const sess = activeSessions.get(token);
  if (Date.now() > sess.expiresAt) {
    activeSessions.delete(token);
    return null;
  }
  return sess;
}

function parseCookies(req) {
  const list = {};
  const rc = req.headers.cookie;
  if (rc) {
    rc.split(';').forEach((cookie) => {
      const parts = cookie.split('=');
      list[parts.shift().trim()] = decodeURI(parts.join('='));
    });
  }
  return list;
}

function checkAuth(req) {
  const cookies = parseCookies(req);
  const token = cookies.tms_session;
  return validateSession(token);
}

// ------------------------------------------------------------------
// DETEKSI JARINGAN & TAILSCALE IP
// ------------------------------------------------------------------
function getNetworkInfo() {
  const interfaces = os.networkInterfaces();
  const localIps = [];
  let tailscaleIp = null;

  for (const name of Object.keys(interfaces)) {
    for (const netIf of interfaces[name]) {
      if (netIf.family === 'IPv4' && !netIf.internal) {
        // Cek range Tailscale: 100.64.0.0 - 100.127.255.255 atau nama interface tailscale/tun
        const parts = netIf.address.split('.').map(Number);
        const isTailscaleCgnat = parts[0] === 100 && parts[1] >= 64 && parts[1] <= 127;
        const isTailscaleName = name.toLowerCase().includes('tailscale') || name.toLowerCase().includes('tun');

        if (isTailscaleCgnat || (isTailscaleName && parts[0] === 100)) {
          tailscaleIp = netIf.address;
        } else {
          localIps.push({ iface: name, address: netIf.address });
        }
      }
    }
  }

  // Fallback: jalankan ip addr show
  if (!tailscaleIp) {
    try {
      const ipOutput = execSync('ip -4 addr show 2>/dev/null || ifconfig 2>/dev/null', { timeout: 1500 }).toString();
      const match = ipOutput.match(/inet\s+(100\.(?:6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.\d+\.\d+)/);
      if (match && match[1]) {
        tailscaleIp = match[1];
      }
    } catch (e) {}
  }

  // Coba cek tailscale status CLI jika terpasang
  let tailscaleDeviceName = null;
  let tailscaleStatus = false;
  try {
    const tsOut = execSync('tailscale status --json 2>/dev/null', { timeout: 1500 }).toString();
    const tsData = JSON.parse(tsOut);
    if (tsData && tsData.Self) {
      tailscaleStatus = tsData.BackendState === 'Running';
      tailscaleDeviceName = tsData.Self.HostName || tsData.Self.DNSName;
      if (!tailscaleIp && tsData.Self.TailscaleIPs && tsData.Self.TailscaleIPs.length > 0) {
        tailscaleIp = tsData.Self.TailscaleIPs[0];
      }
    }
  } catch (e) {}

  if (tailscaleIp && !tailscaleStatus) {
    tailscaleStatus = true;
  }

  return {
    localIps,
    primaryLocalIp: localIps.length > 0 ? localIps[0].address : '127.0.0.1',
    tailscale: {
      connected: !!tailscaleIp,
      ip: tailscaleIp || null,
      deviceName: tailscaleDeviceName || os.hostname(),
      status: tailscaleStatus ? 'Online' : 'Offline'
    }
  };
}

// ------------------------------------------------------------------
// MONITORING SISTEM & HARDWARE ANDROID
// ------------------------------------------------------------------
function getCpuUsagePercent() {
  const cpus = os.cpus();
  let totalIdle = 0;
  let totalTick = 0;
  for (let i = 0; i < cpus.length; i++) {
    const cpu = cpus[i];
    for (const type in cpu.times) {
      totalTick += cpu.times[type];
    }
    totalIdle += cpu.times.idle;
  }
  const idle = totalIdle / cpus.length;
  const total = totalTick / cpus.length;
  return { idle, total };
}

let lastCpuSample = getCpuUsagePercent();
let currentCpuPercent = 0;

setInterval(() => {
  const newSample = getCpuUsagePercent();
  const idleDiff = newSample.idle - lastCpuSample.idle;
  const totalDiff = newSample.total - lastCpuSample.total;
  if (totalDiff > 0) {
    currentCpuPercent = Math.max(0, Math.min(100, Math.round((1 - idleDiff / totalDiff) * 100)));
  }
  lastCpuSample = newSample;
}, 2000);

// Hitung Throughput Jaringan (RX / TX KB/s) via /proc/net/dev
let lastNetSample = { rx: 0, tx: 0, time: Date.now() };
let currentNetSpeed = { rxKbps: 0, txKbps: 0 };

function readProcNetDev() {
  let totalRx = 0;
  let totalTx = 0;
  try {
    if (fs.existsSync('/proc/net/dev')) {
      const data = fs.readFileSync('/proc/net/dev', 'utf8');
      const lines = data.split('\n');
      for (const line of lines) {
        if (!line.includes(':')) continue;
        const [iface, stats] = line.split(':');
        const name = iface.trim();
        if (name === 'lo') continue;
        const cols = stats.trim().split(/\s+/);
        if (cols.length >= 9) {
          totalRx += parseInt(cols[0], 10) || 0;
          totalTx += parseInt(cols[8], 10) || 0;
        }
      }
    }
  } catch (e) {}
  return { rx: totalRx, tx: totalTx };
}

setInterval(() => {
  const current = readProcNetDev();
  const now = Date.now();
  const dt = (now - lastNetSample.time) / 1000;
  if (dt > 0 && lastNetSample.rx > 0) {
    currentNetSpeed = {
      rxKbps: Math.max(0, Math.round(((current.rx - lastNetSample.rx) / 1024 / dt) * 10) / 10),
      txKbps: Math.max(0, Math.round(((current.tx - lastNetSample.tx) / 1024 / dt) * 10) / 10)
    };
  }
  lastNetSample = { rx: current.rx, tx: current.tx, time: now };
}, 2000);

function getThermalInfo() {
  const temps = [];
  const thermalBase = '/sys/class/thermal';
  if (fs.existsSync(thermalBase)) {
    try {
      const dirs = fs.readdirSync(thermalBase).filter(d => d.startsWith('thermal_zone'));
      for (const dir of dirs) {
        const tempPath = path.join(thermalBase, dir, 'temp');
        const typePath = path.join(thermalBase, dir, 'type');
        if (fs.existsSync(tempPath)) {
          let raw = parseInt(fs.readFileSync(tempPath, 'utf8').trim(), 10);
          if (raw > 1000) raw = Math.round(raw / 1000); // millidegree ke Celsius
          let type = dir;
          if (fs.existsSync(typePath)) {
            type = fs.readFileSync(typePath, 'utf8').trim();
          }
          if (raw > 0 && raw < 120) {
            temps.push({ zone: dir, type, temp: raw });
          }
        }
      }
    } catch (e) {}
  }

  let primaryTemp = null;
  const priorityTypes = ['soc_thermal', 'cpu', 'cpu-1', 'tsens_tz_sensor', 'mtktscpu', 'battery'];
  for (const prio of priorityTypes) {
    const found = temps.find(t => t.type.toLowerCase().includes(prio));
    if (found) {
      primaryTemp = found.temp;
      break;
    }
  }
  if (!primaryTemp && temps.length > 0) {
    primaryTemp = temps[0].temp;
  }

  return { primaryTemp: primaryTemp || 0, all: temps };
}

function getBatteryInfo() {
  try {
    const raw = execSync('termux-battery-status 2>/dev/null', { timeout: 1000 }).toString();
    const data = JSON.parse(raw);
    return {
      percentage: data.percentage !== undefined ? data.percentage : null,
      status: data.status || 'Unknown',
      plugged: data.plugged || 'UNPLUGGED',
      temperature: data.temperature ? Math.round(data.temperature * 10) / 10 : null,
      health: data.health || 'GOOD'
    };
  } catch (e) {}

  const pwrBase = '/sys/class/power_supply/battery';
  if (fs.existsSync(pwrBase)) {
    try {
      let cap = null;
      let status = 'Unknown';
      let temp = null;
      if (fs.existsSync(path.join(pwrBase, 'capacity'))) {
        cap = parseInt(fs.readFileSync(path.join(pwrBase, 'capacity'), 'utf8').trim(), 10);
      }
      if (fs.existsSync(path.join(pwrBase, 'status'))) {
        status = fs.readFileSync(path.join(pwrBase, 'status'), 'utf8').trim();
      }
      if (fs.existsSync(path.join(pwrBase, 'temp'))) {
        temp = parseInt(fs.readFileSync(path.join(pwrBase, 'temp'), 'utf8').trim(), 10);
        if (temp > 100) temp = Math.round(temp / 10);
      }
      return { percentage: cap, status, plugged: 'Unknown', temperature: temp, health: 'GOOD' };
    } catch (e) {}
  }

  return { percentage: null, status: 'N/A', plugged: 'N/A', temperature: null, health: 'N/A' };
}

function getDiskInfo() {
  try {
    const out = execSync("df -P -k /data/data/com.termux/files 2>/dev/null || df -P -k . 2>/dev/null", { timeout: 1500 }).toString();
    const lines = out.trim().split('\n');
    if (lines.length >= 2) {
      const parts = lines[1].replace(/\s+/g, ' ').split(' ');
      const totalKB = parseInt(parts[1], 10);
      const usedKB = parseInt(parts[2], 10);
      const availKB = parseInt(parts[3], 10);
      const percent = parseInt(parts[4].replace('%', ''), 10);
      return {
        totalGB: (totalKB / 1024 / 1024).toFixed(1),
        usedGB: (usedKB / 1024 / 1024).toFixed(1),
        freeGB: (availKB / 1024 / 1024).toFixed(1),
        percent
      };
    }
  } catch (e) {}
  return { totalGB: '0', usedGB: '0', freeGB: '0', percent: 0 };
}

function getTopProcesses() {
  if (os.platform() === 'win32') return [];
  try {
    const out = execSync('ps -A -o pid,user,%cpu,%mem,comm 2>/dev/null | sort -k3 -nr 2>/dev/null | head -n 6', { timeout: 1000 }).toString();
    const lines = out.trim().split('\n');
    const procs = [];
    for (let i = 0; i < lines.length; i++) {
      const parts = lines[i].trim().split(/\s+/);
      if (parts.length >= 5 && parts[0] !== 'PID') {
        procs.push({
          pid: parts[0],
          user: parts[1],
          cpu: parseFloat(parts[2]) || 0,
          mem: parseFloat(parts[3]) || 0,
          name: parts.slice(4).join(' ')
        });
      }
    }
    return procs;
  } catch (e) {
    return [];
  }
}

function isPortActive(port) {
  return new Promise((resolve) => {
    const tester = net.createConnection({ port, host: '127.0.0.1' }, () => {
      tester.destroy();
      resolve(true);
    });
    tester.on('error', () => resolve(false));
    tester.setTimeout(800, () => {
      tester.destroy();
      resolve(false);
    });
  });
}

// ------------------------------------------------------------------
// UBUNTU VPS CONTROLLER
// ------------------------------------------------------------------
const UBUNTU_SCRIPTS_DIR = path.join(BASE_DIR, 'scripts');
const START_UBUNTU_SCRIPT = path.join(UBUNTU_SCRIPTS_DIR, 'start-ubuntu.sh');

async function getVpsStatus() {
  const sshRunning = await isPortActive(2222);
  return {
    sshRunning,
    port: 2222,
    distro: 'Ubuntu (PRoot)',
    user: 'root / ubuntu',
    scriptExists: fs.existsSync(START_UBUNTU_SCRIPT)
  };
}

function startVpsService() {
  if (fs.existsSync(START_UBUNTU_SCRIPT)) {
    try {
      exec(`bash "${START_UBUNTU_SCRIPT}" --daemon 2>&1`, { cwd: BASE_DIR });
      return { ok: true, message: 'Layanan Ubuntu OpenSSH (Port 2222) sedang dijalankan...' };
    } catch (e) {
      return { ok: false, message: 'Gagal menjalankan Ubuntu: ' + e.message };
    }
  } else {
    try {
      exec('proot-distro login ubuntu -- bash -c "service ssh start" >/dev/null 2>&1 &');
      return { ok: true, message: 'Memulai SSH via proot-distro ubuntu...' };
    } catch (e) {
      return { ok: false, message: 'Skrip Ubuntu tidak ditemukan: ' + e.message };
    }
  }
}

function stopVpsService() {
  try {
    execSync('pkill -f "sshd -D" 2>/dev/null || pkill -f "/usr/sbin/sshd" 2>/dev/null || true');
    try { execSync('proot-distro login ubuntu -- service ssh stop 2>/dev/null || true'); } catch (e) {}
    return { ok: true, message: 'Layanan OpenSSH VPS telah dihentikan.' };
  } catch (e) {
    return { ok: false, message: 'Gagal menghentikan VPS: ' + e.message };
  }
}

// ------------------------------------------------------------------
// FILE MANAGER ENGINE
// ------------------------------------------------------------------
function resolveSafePath(userPath) {
  if (!userPath || userPath === '~' || userPath === '/') {
    return DEFAULT_ROOT_DIR;
  }
  let target = userPath;
  if (target.startsWith('~/')) {
    target = path.join(DEFAULT_ROOT_DIR, target.substring(2));
  }
  return path.resolve(target);
}

function listDirectory(targetPath) {
  const resolved = resolveSafePath(targetPath);
  if (!fs.existsSync(resolved)) {
    throw new Error('Direktori tidak ditemukan: ' + targetPath);
  }
  const stat = fs.statSync(resolved);
  if (!stat.isDirectory()) {
    throw new Error('Jalur bukan merupakan folder: ' + targetPath);
  }

  const entries = fs.readdirSync(resolved, { withFileTypes: true });
  const items = [];

  for (const entry of entries) {
    try {
      const full = path.join(resolved, entry.name);
      const s = fs.statSync(full);
      items.push({
        name: entry.name,
        path: full,
        isDir: entry.isDirectory(),
        size: s.size,
        mtime: s.mtime.toISOString(),
        permissions: (s.mode & 0o777).toString(8)
      });
    } catch (e) {}
  }

  items.sort((a, b) => {
    if (a.isDir && !b.isDir) return -1;
    if (!a.isDir && b.isDir) return 1;
    return a.name.localeCompare(b.name);
  });

  return {
    currentPath: resolved,
    parentPath: resolved !== '/' ? path.dirname(resolved) : null,
    items
  };
}

// ------------------------------------------------------------------
// TERMINAL STREAMING ENGINE
// ------------------------------------------------------------------
const activeJobs = new Map();

// ------------------------------------------------------------------
// HTTP SERVER & API ROUTES
// ------------------------------------------------------------------
function sendJSON(res, status, data) {
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-cache'
  });
  res.end(JSON.stringify(data));
}

function parseJSONBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', chunk => {
      body += chunk;
      if (body.length > 5 * 1024 * 1024) {
        reject(new Error('Payload terlalu besar'));
      }
    });
    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch (e) {
        reject(new Error('Format JSON tidak valid'));
      }
    });
    req.on('error', reject);
  });
}

const server = http.createServer(async (req, res) => {
  const parsedUrl = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const pathname = parsedUrl.pathname;

  // -------------------------
  // PUBLIC ROUTES
  // -------------------------
  if (pathname === '/api/auth/login' && req.method === 'POST') {
    try {
      const body = await parseJSONBody(req);
      const user = (body.username || '').trim();
      const pass = (body.password || '').trim();

      if (user === authConfig.username && pass === authConfig.password) {
        const ip = req.socket.remoteAddress;
        const token = createSession(user, ip);
        res.writeHead(200, {
          'Content-Type': 'application/json',
          'Set-Cookie': `tms_session=${token}; Path=/; HttpOnly; SameSite=Lax; Max-Age=${7 * 86400}`
        });
        res.end(JSON.stringify({ ok: true, message: 'Login berhasil!' }));
      } else {
        sendJSON(res, 401, { ok: false, message: 'Username atau Password salah!' });
      }
    } catch (e) {
      sendJSON(res, 400, { ok: false, message: e.message });
    }
    return;
  }

  if (pathname === '/api/auth/logout' && req.method === 'POST') {
    const cookies = parseCookies(req);
    if (cookies.tms_session) activeSessions.delete(cookies.tms_session);
    res.writeHead(200, {
      'Content-Type': 'application/json',
      'Set-Cookie': 'tms_session=; Path=/; HttpOnly; Max-Age=0'
    });
    res.end(JSON.stringify({ ok: true, message: 'Logout berhasil.' }));
    return;
  }

  // -------------------------
  // PROTECTED API ROUTES
  // -------------------------
  if (pathname.startsWith('/api/')) {
    const session = checkAuth(req);
    if (!session) {
      sendJSON(res, 401, { ok: false, error: 'Unauthorized', message: 'Sesi login tidak valid atau telah kedaluwarsa.' });
      return;
    }

    // 1. Enhanced System & Telemetry Stats
    if (pathname === '/api/system/stats' && req.method === 'GET') {
      const memTotal = os.totalmem();
      const memFree = os.freemem();
      const memUsed = memTotal - memFree;
      const memPercent = Math.round((memUsed / memTotal) * 100);

      const netInfo = getNetworkInfo();
      const thermal = getThermalInfo();
      const battery = getBatteryInfo();
      const disk = getDiskInfo();
      const topProcs = getTopProcesses();
      const vps = await getVpsStatus();

      sendJSON(res, 200, {
        ok: true,
        cpu: {
          percent: currentCpuPercent,
          cores: os.cpus().length,
          model: os.cpus()[0]?.model || 'ARM Cortex Processor',
          loadAvg: os.loadavg().map(x => Math.round(x * 100) / 100)
        },
        memory: {
          totalMB: Math.round(memTotal / 1024 / 1024),
          usedMB: Math.round(memUsed / 1024 / 1024),
          freeMB: Math.round(memFree / 1024 / 1024),
          percent: memPercent
        },
        disk,
        thermal,
        battery,
        network: netInfo,
        netSpeed: currentNetSpeed,
        topProcesses: topProcs,
        vps,
        uptime: os.uptime(),
        hostname: os.hostname(),
        platform: os.platform() + ' ' + os.arch()
      });
      return;
    }

    // 2. Tailscale Status & IP
    if (pathname === '/api/tailscale/status' && req.method === 'GET') {
      const netInfo = getNetworkInfo();
      sendJSON(res, 200, { ok: true, tailscale: netInfo.tailscale, primaryLocalIp: netInfo.primaryLocalIp });
      return;
    }

    // 3. VPS Status & Controls
    if (pathname === '/api/vps/status' && req.method === 'GET') {
      const vps = await getVpsStatus();
      sendJSON(res, 200, { ok: true, vps });
      return;
    }

    if (pathname === '/api/vps/start' && req.method === 'POST') {
      const result = startVpsService();
      sendJSON(res, 200, result);
      return;
    }

    if (pathname === '/api/vps/stop' && req.method === 'POST') {
      const result = stopVpsService();
      sendJSON(res, 200, result);
      return;
    }

    if (pathname === '/api/vps/restart' && req.method === 'POST') {
      stopVpsService();
      setTimeout(() => {
        const result = startVpsService();
        sendJSON(res, 200, result);
      }, 1000);
      return;
    }

    // 4. File Manager Endpoints
    if (pathname === '/api/files/list' && req.method === 'GET') {
      try {
        const target = parsedUrl.searchParams.get('path') || DEFAULT_ROOT_DIR;
        const data = listDirectory(target);
        sendJSON(res, 200, { ok: true, data });
      } catch (e) {
        sendJSON(res, 400, { ok: false, message: e.message });
      }
      return;
    }

    if (pathname === '/api/files/read' && req.method === 'GET') {
      try {
        const filePath = resolveSafePath(parsedUrl.searchParams.get('path'));
        if (!fs.existsSync(filePath)) throw new Error('File tidak ditemukan');
        const content = fs.readFileSync(filePath, 'utf8');
        sendJSON(res, 200, { ok: true, content, path: filePath });
      } catch (e) {
        sendJSON(res, 400, { ok: false, message: e.message });
      }
      return;
    }

    if (pathname === '/api/files/save' && req.method === 'POST') {
      try {
        const body = await parseJSONBody(req);
        const filePath = resolveSafePath(body.path);
        fs.writeFileSync(filePath, body.content || '', 'utf8');
        sendJSON(res, 200, { ok: true, message: 'File berhasil disimpan!' });
      } catch (e) {
        sendJSON(res, 400, { ok: false, message: e.message });
      }
      return;
    }

    if (pathname === '/api/files/create' && req.method === 'POST') {
      try {
        const body = await parseJSONBody(req);
        const targetPath = resolveSafePath(body.path);
        if (body.type === 'folder') {
          fs.mkdirSync(targetPath, { recursive: true });
        } else {
          fs.writeFileSync(targetPath, '', 'utf8');
        }
        sendJSON(res, 200, { ok: true, message: 'Berhasil dibuat!' });
      } catch (e) {
        sendJSON(res, 400, { ok: false, message: e.message });
      }
      return;
    }

    if (pathname === '/api/files/delete' && req.method === 'POST') {
      try {
        const body = await parseJSONBody(req);
        const targetPath = resolveSafePath(body.path);
        if (!fs.existsSync(targetPath)) throw new Error('File/folder tidak ditemukan');
        fs.rmSync(targetPath, { recursive: true, force: true });
        sendJSON(res, 200, { ok: true, message: 'Berhasil dihapus!' });
      } catch (e) {
        sendJSON(res, 400, { ok: false, message: e.message });
      }
      return;
    }

    if (pathname === '/api/files/rename' && req.method === 'POST') {
      try {
        const body = await parseJSONBody(req);
        const oldPath = resolveSafePath(body.oldPath);
        const newPath = resolveSafePath(body.newPath);
        fs.renameSync(oldPath, newPath);
        sendJSON(res, 200, { ok: true, message: 'Berhasil diubah nama!' });
      } catch (e) {
        sendJSON(res, 400, { ok: false, message: e.message });
      }
      return;
    }

    if (pathname === '/api/files/download' && req.method === 'GET') {
      try {
        const filePath = resolveSafePath(parsedUrl.searchParams.get('path'));
        if (!fs.existsSync(filePath)) {
          res.writeHead(404, { 'Content-Type': 'text/plain' });
          res.end('File tidak ditemukan');
          return;
        }
        const stat = fs.statSync(filePath);
        if (stat.isDirectory()) {
          const zipName = path.basename(filePath) + '.zip';
          res.writeHead(200, {
            'Content-Type': 'application/zip',
            'Content-Disposition': `attachment; filename="${encodeURIComponent(zipName)}"`
          });
          const zip = spawn('zip', ['-r', '-', path.basename(filePath)], { cwd: path.dirname(filePath) });
          zip.stdout.pipe(res);
          return;
        } else {
          res.writeHead(200, {
            'Content-Type': 'application/octet-stream',
            'Content-Length': stat.size,
            'Content-Disposition': `attachment; filename="${encodeURIComponent(path.basename(filePath))}"`
          });
          fs.createReadStream(filePath).pipe(res);
          return;
        }
      } catch (e) {
        sendJSON(res, 400, { ok: false, message: e.message });
        return;
      }
    }

    // 5. Terminal Interactive Stream
    if (pathname === '/api/terminal/stream' && req.method === 'POST') {
      try {
        const body = await parseJSONBody(req);
        const command = (body.command || '').trim();
        const jobId = 'job_' + Date.now();
        const cwd = body.cwd ? resolveSafePath(body.cwd) : DEFAULT_ROOT_DIR;

        if (!command) {
          sendJSON(res, 400, { ok: false, message: 'Perintah kosong' });
          return;
        }

        const isWin = os.platform() === 'win32';
        const termuxBash = '/data/data/com.termux/files/usr/bin/bash';
        const shell = isWin ? 'cmd.exe' : (fs.existsSync(termuxBash) ? termuxBash : 'bash');
        const shellArgs = isWin ? ['/c', command] : ['-c', command];

        res.writeHead(200, {
          'Content-Type': 'text/plain; charset=utf-8',
          'Transfer-Encoding': 'chunked',
          'X-Content-Type-Options': 'nosniff',
          'Cache-Control': 'no-cache'
        });

        const child = spawn(shell, shellArgs, {
          cwd,
          env: Object.assign({}, process.env, { TERM: 'xterm-256color', FORCE_COLOR: '1' })
        });

        activeJobs.set(jobId, child);

        res.write(JSON.stringify({ type: 'init', jobId }) + '\n');

        child.stdout.on('data', chunk => {
          res.write(JSON.stringify({ type: 'stdout', data: chunk.toString() }) + '\n');
        });

        child.stderr.on('data', chunk => {
          res.write(JSON.stringify({ type: 'stderr', data: chunk.toString() }) + '\n');
        });

        child.on('close', code => {
          activeJobs.delete(jobId);
          res.write(JSON.stringify({ type: 'exit', code }) + '\n');
          res.end();
        });

        req.on('close', () => {
          if (activeJobs.has(jobId)) {
            try { child.kill('SIGTERM'); } catch (e) {}
            activeJobs.delete(jobId);
          }
        });
      } catch (e) {
        sendJSON(res, 500, { ok: false, message: e.message });
      }
      return;
    }

    if (pathname === '/api/terminal/kill' && req.method === 'POST') {
      try {
        const body = await parseJSONBody(req);
        const job = activeJobs.get(body.jobId);
        if (job) {
          job.kill('SIGINT');
          activeJobs.delete(body.jobId);
          sendJSON(res, 200, { ok: true, message: 'Perintah dihentikan (Ctrl+C)' });
        } else {
          sendJSON(res, 404, { ok: false, message: 'Job ID tidak ditemukan' });
        }
      } catch (e) {
        sendJSON(res, 400, { ok: false, message: e.message });
      }
      return;
    }

    // 6. Kill Process Endpoint
    if (pathname === '/api/process/kill' && req.method === 'POST') {
      try {
        const body = await parseJSONBody(req);
        const pid = parseInt(body.pid, 10);
        if (!pid || pid <= 1) {
          sendJSON(res, 400, { ok: false, message: 'PID tidak valid atau dilindungi.' });
          return;
        }
        process.kill(pid, 'SIGTERM');
        sendJSON(res, 200, { ok: true, message: `Proses PID ${pid} berhasil dihentikan.` });
      } catch (e) {
        sendJSON(res, 500, { ok: false, message: 'Gagal menghentikan proses: ' + e.message });
      }
      return;
    }

    // 7. PM2 & Process Status
    if (pathname === '/api/pm2/status' && req.method === 'GET') {
      try {
        const out = execSync('pm2 jlist 2>/dev/null', { timeout: 2500 }).toString();
        const list = JSON.parse(out);
        sendJSON(res, 200, { ok: true, pm2Installed: true, processes: list });
      } catch (e) {
        sendJSON(res, 200, { ok: true, pm2Installed: false, processes: [], message: 'PM2 belum terpasang atau tidak aktif' });
      }
      return;
    }

    // 8. Device Controls (Termux-API)
    if (pathname === '/api/device/action' && req.method === 'POST') {
      try {
        const body = await parseJSONBody(req);
        const action = body.action;
        let cmd = '';
        if (action === 'wakelock_on') cmd = 'termux-wake-lock';
        else if (action === 'wakelock_off') cmd = 'termux-wake-unlock';
        else if (action === 'torch_on') cmd = 'termux-torch on';
        else if (action === 'torch_off') cmd = 'termux-torch off';
        else if (action === 'vibrate') cmd = 'termux-vibrate -d 400';

        if (cmd) {
          exec(cmd + ' 2>/dev/null');
          sendJSON(res, 200, { ok: true, message: `Aksi ${action} berhasil dikirim.` });
        } else {
          sendJSON(res, 400, { ok: false, message: 'Aksi tidak dikenal.' });
        }
      } catch (e) {
        sendJSON(res, 500, { ok: false, message: e.message });
      }
      return;
    }

    // 9. Account Settings
    if (pathname === '/api/settings/account' && req.method === 'POST') {
      try {
        const body = await parseJSONBody(req);
        const currentPass = (body.currentPassword || '').trim();
        const newUsername = (body.newUsername || '').trim();
        const newPassword = (body.newPassword || '').trim();

        if (currentPass !== authConfig.password) {
          sendJSON(res, 400, { ok: false, message: 'Password saat ini salah!' });
          return;
        }
        if (!newUsername && !newPassword) {
          sendJSON(res, 400, { ok: false, message: 'Tidak ada perubahan username/password.' });
          return;
        }
        if (newUsername && newUsername.length < 3) {
          sendJSON(res, 400, { ok: false, message: 'Username baru minimal 3 karakter!' });
          return;
        }
        if (newPassword && newPassword.length < 5) {
          sendJSON(res, 400, { ok: false, message: 'Password baru minimal 5 karakter!' });
          return;
        }

        saveAuthConfig(newUsername || authConfig.username, newPassword || authConfig.password);
        sendJSON(res, 200, { ok: true, message: 'Pengaturan akun berhasil diperbarui!' });
      } catch (e) {
        sendJSON(res, 500, { ok: false, message: e.message });
      }
      return;
    }

    sendJSON(res, 404, { ok: false, message: 'API endpoint tidak ditemukan' });
    return;
  }

  // -------------------------
  // STATIC ASSETS (Frontend)
  // -------------------------
  const publicDir = path.join(__dirname, 'public');
  let filePath = path.join(publicDir, pathname === '/' ? 'index.html' : pathname);

  if (!fs.existsSync(filePath)) {
    filePath = path.join(publicDir, 'index.html');
  }

  const ext = path.extname(filePath);
  const mimeTypes = {
    '.html': 'text/html; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.js': 'application/javascript; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.svg': 'image/svg+xml'
  };

  try {
    const content = fs.readFileSync(filePath);
    res.writeHead(200, { 'Content-Type': mimeTypes[ext] || 'application/octet-stream' });
    res.end(content);
  } catch (e) {
    res.writeHead(500, { 'Content-Type': 'text/plain' });
    res.end('Gagal memuat halaman: ' + e.message);
  }
});

server.listen(PORT, '0.0.0.0', () => {
  const netInfo = getNetworkInfo();
  console.log(`\n======================================================`);
  console.log(`🚀 Termux Mini Server (Tailscale Edition) Berjalan!`);
  console.log(`======================================================`);
  console.log(`📡 Port Lokal       : http://localhost:${PORT}`);
  console.log(`🌐 Akses Wi-Fi/LAN  : http://${netInfo.primaryLocalIp}:${PORT}`);
  if (netInfo.tailscale.connected) {
    console.log(`🔒 Akses Tailscale  : http://${netInfo.tailscale.ip}:${PORT}`);
  } else {
    console.log(`ℹ️  Akses Tailscale  : [Belum Terhubung] (Buka aplikasi Tailscale di HP)`);
  }
  console.log(`🔑 Login Default    : Username: ${authConfig.username} | Password: ${authConfig.password}`);
  console.log(`======================================================\n`);
});
