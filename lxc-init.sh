#!/usr/bin/env bash
set -euo pipefail

# Ensure script runs as root
if [[ "$EUID" -ne 0 ]]; then
    echo "Error: Run this script as root."
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "==> [1/4] Updating system packages..."
apt-get update -y
apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

echo "==> [2/4] Installing core baseline packages..."
apt-get install -y \
    ca-certificates \
    curl \
    wget \
    git \
    gnupg \
    sudo \
    htop \
    net-tools \
    whiptail \
    openssh-server

echo "==> [3/4] Configuring SSH server (allowing root password & key login)..."
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

echo "==> [4/4] Launching optional package selector..."
export TERM="${TERM:-xterm-256color}"
run_whiptail() {
    whiptail --title "Homelab LXC Bootstrap" \
        --checklist "Select optional packages to install (Space to toggle, Enter to confirm):" 18 72 8 \
        "docker" "Docker Engine + Docker Compose plugin" OFF \
        "tailscale" "Tailscale mesh VPN client" OFF \
        "node_exporter" "Prometheus Node Exporter for monitoring" OFF \
        "nmap" "Network discovery and port scanner" OFF \
        "jq" "Lightweight command-line JSON processor" OFF \
        "tmux" "Terminal multiplexer" OFF \
        "ncdu" "NCurses disk usage analyzer" OFF \
        3>&1 1>&2 2>&3
}

CHOICES=""
if [[ -t 0 ]]; then
    CHOICES=$(run_whiptail) || true
elif [[ -r /dev/tty ]]; then
    CHOICES=$(run_whiptail </dev/tty) || true
fi

for choice in $CHOICES; do
    case "${choice//\"/}" in
        docker)
            echo "--> Installing Docker..."
            curl -fsSL https://get.docker.com | sh
            systemctl enable --now docker
            ;;
        tailscale)
            echo "--> Installing Tailscale..."
            curl -fsSL https://tailscale.com/install.sh | sh
            ;;
        node_exporter)
            echo "--> Installing Prometheus Node Exporter..."
            apt-get install -y prometheus-node-exporter
            systemctl enable --now prometheus-node-exporter
            ;;
        nmap|jq|tmux|ncdu)
            echo "--> Installing ${choice//\"/}..."
            apt-get install -y "${choice//\"/}"
            ;;
    esac
done

echo "==> Cleaning up apt cache..."
apt-get autoremove -y && apt-get clean

echo "Bootstrap complete."
