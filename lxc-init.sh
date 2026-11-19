#!/usr/bin/env bash
set -euo pipefail

# --- CONFIGURATION ---
GITHUB_USER="gunnhil25"
# ---------------------

# Ensure the script runs as root
if [[ "$EUID" -ne 0 ]]; then
  echo "Please run this script as root."
  exit 1
fi

echo "==> Updating system and installing core baseline tools..."
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get upgrade -y
apt-get install -y sudo curl wget git htop net-tools ca-certificates gnupg whiptail openssh-server

echo "==> Configuring SSH access..."
mkdir -p /root/.ssh
chmod 700 /root/.ssh

# Fetch public keys from GitHub and append without duplicating existing keys
curl -fsSL "https://github.com/${GITHUB_USER}.keys" -o /tmp/gh_keys
if [[ -s /tmp/gh_keys ]]; then
  touch /root/.ssh/authorized_keys
  grep -qxFf /root/.ssh/authorized_keys /tmp/gh_keys || cat /tmp/gh_keys >> /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  rm -f /tmp/gh_keys
  echo "    Imported SSH keys for GitHub user: ${GITHUB_USER}"
else
  echo "    Warning: No public keys found at https://github.com/${GITHUB_USER}.keys"
fi

# Harden sshd via drop-in config (key-only root login, no password auth)
mkdir -p /etc/ssh/sshd_config.d
cat << 'EOF' > /etc/ssh/sshd_config.d/99-lxc-baseline.conf
PermitRootLogin prohibit-password
PasswordAuthentication no
PubkeyAuthentication yes
EOF

systemctl enable --now ssh

# Interactive checklist menu
CHOICES=$(whiptail --title "LXC Baseline Setup" --checklist \
"Use SPACE to select optional packages and ENTER to install:" 16 65 6 \
"DOCKER" "Docker Engine & Compose plugin" OFF \
"TAILSCALE" "Tailscale mesh VPN client" OFF \
"NODE_EXPORTER" "Prometheus node_exporter for monitoring" OFF \
"EXTRA_CLI" "Diagnostic & network tools (nmap, jq, tmux, ncdu)" OFF \
3>&1 1>&2 2>&3) || {
  echo "Optional installation cancelled. Core tools & SSH are ready."
  exit 0
}

# Parse selections
for CHOICE in $CHOICES; do
  case "$CHOICE" in
    "\"DOCKER\"")
      echo "==> Installing Docker..."
      curl -fsSL https://get.docker.com | sh
      systemctl enable --now docker
      ;;
    "\"TAILSCALE\"")
      echo "==> Installing Tailscale..."
      curl -fsSL https://tailscale.com/install.sh | sh
      ;;
    "\"NODE_EXPORTER\"")
      echo "==> Installing Prometheus Node Exporter..."
      apt-get install -y prometheus-node-exporter
      systemctl enable --now prometheus-node-exporter
      ;;
    "\"EXTRA_CLI\"")
      echo "==> Installing extra CLI utilities..."
      apt-get install -y nmap jq tmux ncdu
      ;;
  esac
done

echo "==> Cleaning up apt cache..."
apt-get autoremove -y && apt-get clean

echo "==> Setup complete! You can now SSH into this container as root."