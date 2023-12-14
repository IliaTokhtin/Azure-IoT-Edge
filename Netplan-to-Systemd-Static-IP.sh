#!/bin/sh
if [ $# -eq 2 ]
then
  echo "Missing required variables: Address(eg. 10.0.0.2/24), Gateway(eg. 10.0.0.1), DNS(eg. 1.1.1.1), ./script.sh 10.0.0.2/24 10.0.0.1 1.1.1.1"
else
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

  # Create systemd-networkd static ip config
  sudo tee /etc/systemd/network/20-dhcp.network << END
[Match]
Name=$NetworkInt

[Network]
Address=$1
Gateway=$2
DNS=$3
END

  sudo reboot
fi