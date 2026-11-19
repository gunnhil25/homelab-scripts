# Homelab Scripts

Automated provisioning and baseline configuration scripts for fresh Proxmox LXC containers (Debian / Ubuntu). Designed to eliminate repetitive post-creation setup tasks and standardize SSH access, core utilities, and optional services.

## Quick Start (BLUF)

Run the following command as `root` inside a fresh LXC console (uses `wget`, which is pre-installed on minimal Debian/Ubuntu LXC templates):

```bash
bash -c "$(wget -qO- [https://raw.githubusercontent.com/gunnhil25/homelab-scripts/main/lxc-init.sh](https://raw.githubusercontent.com/gunnhil25/homelab-scripts/main/lxc-init.sh))"
```

*(Optional)* Append a timestamp query parameter to bypass GitHub's 5-minute raw CDN cache immediately after pushing script updates:

```bash
bash -c "$(wget -qO- "[https://raw.githubusercontent.com/gunnhil25/homelab-scripts/main/lxc-init.sh?t=$(date](https://raw.githubusercontent.com/gunnhil25/homelab-scripts/main/lxc-init.sh?t=$(date) +%s)")"
```

---

## What `lxc-init.sh` Does

### Phase 1: Automatic Baseline Setup (Runs Unattended)

Before displaying the interactive menu, the script automatically updates the container and configures core packages and SSH access:

* **System Update & Upgrade**
  Refreshes package lists and upgrades all pre-installed packages non-interactively:
  ```bash
  export DEBIAN_FRONTEND=noninteractive
  apt-get update && apt-get upgrade -y
  ```

* **Core Baseline Packages**
  Installs essential CLI tools, certificate authorities, terminal dialog UI (`whiptail`), and the OpenSSH server:
  ```bash
  apt-get install -y sudo curl wget git htop net-tools ca-certificates gnupg whiptail openssh-server
  ```

* **SSH Key Provisioning & Hardening**
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

### Phase 2: Optional Packages (Interactive `whiptail` Menu)

After Phase 1 completes, an interactive checklist appears. Use **Space** to toggle selections and **Enter** to confirm:

* **Docker (`DOCKER`)**
  Installs Docker Engine and the Docker Compose plugin via the official convenience script and enables the service. *(Prerequisite: Enable **Nesting** under **Options > Features** in Proxmox before running Docker inside an unprivileged LXC).*
  ```bash
  curl -fsSL [https://get.docker.com](https://get.docker.com) | sh
  systemctl enable --now docker
  ```

* **Tailscale (`TAILSCALE`)**
  Installs the Tailscale mesh VPN client via the official installer script.
  ```bash
  curl -fsSL [https://tailscale.com/install.sh](https://tailscale.com/install.sh) | sh
  ```

* **Prometheus Node Exporter (`NODE_EXPORTER`)**
  Installs and starts `prometheus-node-exporter` to expose host/container metrics for monitoring.
  ```bash
  apt-get install -y prometheus-node-exporter
  systemctl enable --now prometheus-node-exporter
  ```

* **Extra CLI Utilities (`EXTRA_CLI`)**
  Installs additional network diagnostic, JSON parsing, terminal multiplexing, and disk usage tools (`nmap`, `jq`, `tmux`, `ncdu`).
  ```bash
  apt-get install -y
