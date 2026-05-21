#!/usr/bin/env bash
set -euo pipefail

STATIC_IP="192.168.1.74/24"
GATEWAY="192.168.1.1"
DNS1="8.8.8.8"
DNS2="1.1.1.1"
HOSTNAME="mws-ids01"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo bash scripts/apply_static_ip.sh"
  exit 1
fi

IFACE="${1:-$(ip route | awk '/default/ {print $5; exit}')}"
if [ -z "$IFACE" ]; then
  IFACE="$(ls /sys/class/net | grep -E '^(en|eth)' | head -n 1 || true)"
fi
if [ -z "$IFACE" ]; then
  echo "[ERROR] Could not detect network interface. Pass it manually: sudo bash scripts/apply_static_ip.sh enp0s3"
  exit 1
fi

echo "[INFO] Setting hostname to $HOSTNAME"
hostnamectl set-hostname "$HOSTNAME"

echo "[INFO] Writing static IP config for interface $IFACE -> $STATIC_IP"
cat > /etc/netplan/01-mws-static.yaml <<YAML
network:
  version: 2
  ethernets:
    $IFACE:
      dhcp4: false
      addresses:
        - $STATIC_IP
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
        addresses:
          - $DNS1
          - $DNS2
YAML

chmod 600 /etc/netplan/01-mws-static.yaml
netplan generate
netplan apply
ip addr show "$IFACE" | sed -n '1,8p'
