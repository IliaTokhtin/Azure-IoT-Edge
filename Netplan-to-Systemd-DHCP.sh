#!/bin/sh

# Update system
sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y && sudo apt -o=APT::Get::HideAutoRemove=1 upgrade -y
sudo DEBIAN_FRONTEND=noninteractive apt install net-tools

# Remove old crap netplan setup
sudo apt remove -y --purge netplan.io

# Enable and setup systemd-networkd and systemd-resolved
sudo systemctl disable network-manager
sudo systemctl stop network-manager
sudo systemctl enable systemd-networkd
sudo systemctl start systemd-networkd
sudo systemctl start systemd-resolved
sudo systemctl enable systemd-resolved
sudo rm /etc/resolv.conf
sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf

# Parse network device for system
NetworkInt=`ip -br l | awk '$1 !~ "lo|vir|wl" { print $1}'`

# Create systemd-networkd dhcp ip config
sudo tee /etc/systemd/network/20-dhcp.network << END
[Match]
Name=$NetworkInt

[Network]
DHCP=yes
END

sudo reboot