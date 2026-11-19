# 🛠️ Homelab Scripts

Automated provisioning and baseline configuration scripts for fresh Proxmox LXC containers (Debian / Ubuntu). Designed to eliminate repetitive post-creation setup tasks and standardize SSH access, core utilities, and optional services.

## Pre-Flight: SSH Key Setup (Before Creating the LXC)

Proxmox VE natively injects your public SSH key into `/root/.ssh/authorized_keys` (`700`/`600` permissions) when pasted into the **SSH public key(s)** field during container creation.

### Windows (PowerShell)
1. **Generate an Ed25519 key pair** (skip if `~\.ssh\id_ed25519.pub` already exists):
   ```powershell
   ssh-keygen -t ed25519 -C "kilhi-workstation"
   
## 🚀 Quick Start (BLUF)

⚡ **Run this command as `root` inside a fresh LXC console** (uses `wget`, which comes pre-installed on minimal Debian/Ubuntu LXC templates):

```bash
bash -c "$(wget -qO- [https://raw.githubusercontent.com/gunnhil25/homelab-scripts/main/lxc-init.sh](https://raw.githubusercontent.com/gunnhil25/homelab-scripts/main/lxc-init.sh))"
```

🔄 **Bypass GitHub CDN Cache** *(use immediately after pushing script updates to skip the 5-minute cache)*:

```bash
bash -c "$(wget -qO- "[https://raw.githubusercontent.com/gunnhil25/homelab-scripts/main/lxc-init.sh?t=$(date](https://raw.githubusercontent.com/gunnhil25/homelab-scripts/main/lxc-init.sh?t=$(date) +%s)")"
```

---

## 📋 What `lxc-init.sh` Does

### ⚙️ Phase 1: Automatic Baseline Setup (Runs Unattended)

Before displaying the interactive menu, the script automatically updates the container and configures core packages and SSH access:

* **📦 System Update & Upgrade**
  Refreshes package lists and upgrades all pre-installed packages non-interactively:
  ```bash
  export DEBIAN_FRONTEND=noninteractive
  apt-get update && apt-get upgrade -y
  ```

* **🧰 Core Baseline Packages**
  Installs essential CLI tools, certificate authorities, terminal dialog UI (`whiptail`), and the OpenSSH server:
  ```bash
  apt-get install -y sudo curl wget git htop net-tools ca-certificates gnupg whiptail openssh-server
  ```

* **🔑 SSH Key Provisioning & Hardening**
  Imports public keys from GitHub (`gunnhil25`), enforces strict file permissions, disables password logins, and starts the SSH daemon:
  ```bash
  mkdir -p /root/.ssh && chmod 700 /root/.ssh
  curl -fsSL "[https://github.com/gunnhil25.keys](https://github.com/gunnhil25.keys)" -o /tmp/gh_keys
  grep -qxFf /root/.ssh/authorized_keys /tmp/gh_keys || cat /tmp/gh_keys >> /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys && rm -f /tmp/gh_keys

  cat << 'EOF' > /etc/ssh/sshd_config.d/99-lxc-baseline.conf
  PermitRootLogin prohibit-password
  PasswordAuthentication no
  PubkeyAuthentication yes
  EOF

  systemctl enable --now ssh
  ```

---

### 🎛️ Phase 2: Optional Packages (Interactive `whiptail` Menu)

After Phase 1 completes, an interactive checklist appears. Use **Space** to toggle selections and **Enter** to confirm:

* **🐳 Docker (`DOCKER`)**
  Installs Docker Engine and the Docker Compose plugin via the official convenience script and enables the service.
  > ⚠️ **Proxmox Prerequisite:** Enable **Nesting** under **Options > Features** in Proxmox before running Docker inside an unprivileged LXC.
  ```bash
  curl -fsSL [https://get.docker.com](https://get.docker.com) | sh
  systemctl enable --now docker
  ```

* **🌐 Tailscale (`TAILSCALE`)**
  Installs the Tailscale mesh VPN client via the official installer script.
  ```bash
  curl -fsSL [https://tailscale.com/install.sh](https://tailscale.com/install.sh) | sh
  ```

* **📊 Prometheus Node Exporter (`NODE_EXPORTER`)**
  Installs and starts `prometheus-node-exporter` to expose host/container metrics for monitoring.
  ```bash
  apt-get install -y prometheus-node-exporter
  systemctl enable --now prometheus-node-exporter
  ```

* **💻 Extra CLI Utilities (`EXTRA_CLI`)**
  Installs additional network diagnostic, JSON parsing, terminal multiplexing, and disk usage tools (`nmap`, `jq`, `tmux`, `ncdu`).
  ```bash
  apt-get install -y nmap jq tmux ncdu
  ```

---

### 🧹 Phase 3: Cleanup

Once selected packages finish installing, unused dependencies and cached `.deb` archives are removed to keep the container footprint small:

```bash
apt-get autoremove -y && apt-get clean
```
