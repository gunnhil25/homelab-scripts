🛠️ Homelab Scripts
Automated provisioning and baseline configuration scripts for fresh Proxmox LXC containers (Debian / Ubuntu). Eliminates repetitive post-creation setup tasks and standardizes SSH configuration, core utilities, and optional services.
---
🔑 Pre-Flight: SSH Key Setup (Optional)
If you also want key-based SSH access in addition to root password login, Proxmox VE natively injects your public SSH key into `/root/.ssh/authorized_keys` (`700`/`600` permissions) when pasted into the SSH public key(s) field during container creation.
1. Grab Your Public Key
Windows (PowerShell)
```powershell
# Generate an Ed25519 key pair (skip if ~\.ssh\id_ed25519.pub already exists)
ssh-keygen -t ed25519 -C "kilhi-workstation"

# Copy the public key straight to your clipboard
Get-Content ~\.ssh\id_ed25519.pub | Set-Clipboard
```
macOS / Linux
```bash
cat ~/.ssh/id_ed25519.pub
```
2. Inject in Proxmox VE
Paste your public key(s) into the SSH public key(s) box on the General tab during LXC creation (one key per line if adding both workstation and MacBook keys).
Boot the container and SSH directly in:
```bash
ssh root@<lxc-ip>
```
---
🚀 Quick Start
Run as `root` inside the new LXC (uses `wget`, which comes pre-installed on minimal Debian/Ubuntu LXC templates):
```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/gunnhil25/homelab-scripts/main/lxc-init.sh)"
```
Bypass GitHub CDN Cache (use immediately after pushing script updates to skip the 5-minute raw cache):
```bash
bash -c "$(wget -qO- "https://raw.githubusercontent.com/gunnhil25/homelab-scripts/main/lxc-init.sh?t=$(date +%s)")"
```
---
📋 What `lxc-init.sh` Does
⚙️ Phase 1: Automatic Baseline Setup (Unattended)
📦 System Update & Upgrade
Refreshes package indexes and upgrades pre-installed packages non-interactively without prompting on modified config files:
```bash
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
```
🧰 Core Baseline Packages
Installs essential CLI tools, TLS certificates, `whiptail` for dialog menus, and OpenSSH:
```bash
apt-get install -y ca-certificates curl wget git gnupg sudo htop net-tools whiptail openssh-server
```
🔓 SSH Daemon Configuration
Writes a priority drop-in config (`/etc/ssh/sshd_config.d/00-lxc-ssh.conf`) to allow root login with either a password or an SSH key (overriding Debian/Ubuntu and cloud-init defaults):
```bash
mkdir -p /etc/ssh/sshd_config.d /run/sshd
rm -f /etc/ssh/sshd_config.d/00-lxc-hardening.conf
cat << 'EOF' > /etc/ssh/sshd_config.d/00-lxc-ssh.conf
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication yes
EOF

sshd -t
systemctl enable --now ssh
systemctl restart ssh
```
---
🎛️ Phase 2: Optional Packages (Interactive `whiptail` Menu)
Use Space to toggle selections and Enter to confirm:
- 🐳 Docker (`docker`) — Installs Docker Engine and the Compose plugin (`get.docker.com`) and enables the service.
  > ⚠️ **Proxmox Prerequisite:** Enable **Nesting** under **Options > Features** in Proxmox before running Docker inside an unprivileged LXC.
- 🌐 Tailscale (`tailscale`) — Installs the Tailscale mesh VPN client (`tailscale.com/install.sh`).
  > ⚠️ **Proxmox Prerequisite:** Unprivileged LXCs require `/dev/net/tun` passthrough in the container `.conf` (or `--tun=userspace-networking`) for Tailscale.
- 📊 Prometheus Node Exporter (`node_exporter`) — Installs and enables `prometheus-node-exporter` for host/container metrics.
- 🔍 `nmap` — Network discovery and port scanner.
- 🧩 `jq` — Lightweight command-line JSON processor.
- 🖥️ `tmux` — Terminal multiplexer.
- 💾 `ncdu` — NCurses disk usage analyzer.
---
🧹 Phase 3: Cleanup
Removes unused dependencies and cached `.deb` archives to minimize container disk usage:
```bash
apt-get autoremove -y && apt-get clean
```
