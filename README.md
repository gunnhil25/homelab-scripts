# Homelab Scripts

Automated provisioning and baseline setup scripts for fresh Proxmox LXC containers (Debian / Ubuntu).

## 🚀 Quick Start

Run as `root` inside the new LXC container:

```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/gunnhil25/homelab-scripts/main/lxc-init.sh)"
```

To bypass GitHub's raw CDN cache immediately after pushing script updates:

```bash
bash -c "$(wget -qO- "https://raw.githubusercontent.com/gunnhil25/homelab-scripts/main/lxc-init.sh?t=$(date +%s)")"
```

## 🔑 Optional Pre-Flight: SSH Keys

If you want key-based SSH login in addition to root password login, paste or upload your public key(s) in the **SSH public key(s)** field on the **General** tab when creating the LXC in Proxmox VE. Proxmox injects them into `/root/.ssh/authorized_keys`.

To generate or copy a key from your workstation:

- **Windows (PowerShell):** `ssh-keygen -t ed25519` then `Get-Content ~\.ssh\id_ed25519.pub | Set-Clipboard`
- **macOS / Linux:** `ssh-keygen -t ed25519` then `cat ~/.ssh/id_ed25519.pub`

## 📋 What `lxc-init.sh` Does

### ⚙️ 1. Baseline Setup (Unattended)

- **System Update:** Runs `apt-get update` and non-interactive `apt-get upgrade` while keeping existing config files.
- **Core Packages:** Installs `ca-certificates`, `curl`, `wget`, `git`, `gnupg`, `sudo`, `htop`, `net-tools`, `whiptail`, and `openssh-server`.
- **SSH Configuration:** Writes `/etc/ssh/sshd_config.d/00-lxc-ssh.conf` with `PermitRootLogin yes`, `PubkeyAuthentication yes`, and `PasswordAuthentication yes`, then validates and restarts `ssh`.

### 🎛️ 2. Optional Packages (Interactive Menu)

Uses a `whiptail` checklist (`Space` to toggle, `Enter` to confirm) to install:

- `docker` — Docker Engine and Docker Compose plugin (`get.docker.com`). Requires **Nesting** enabled under **Options > Features** in Proxmox for unprivileged LXCs.
- `tailscale` — Tailscale mesh VPN client (`tailscale.com/install.sh`). Unprivileged LXCs require `/dev/net/tun` passthrough (or `--tun=userspace-networking`).
- `node_exporter` — Prometheus Node Exporter (`prometheus-node-exporter`).
- `nmap`, `jq`, `tmux`, `ncdu` — Extra CLI utilities.

### 🧹 3. Cleanup

Runs `apt-get autoremove -y` and `apt-get clean` to minimize container disk usage.
