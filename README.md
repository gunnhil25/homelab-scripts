# Homelab Scripts

Automated provisioning and baseline configuration scripts for fresh Proxmox LXC containers.

## Quick Start

Run the following command as `root` on a newly created Debian or Ubuntu LXC container (uses `wget`, which is pre-installed on minimal LXC templates):

```bash
bash -c "$(wget -qO- [https://raw.githubusercontent.com/gunnhil25/homelab-scripts/main/lxc-init.sh](https://raw.githubusercontent.com/gunnhil25/homelab-scripts/main/lxc-init.sh))"
