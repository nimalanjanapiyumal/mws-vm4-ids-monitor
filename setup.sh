#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo bash setup.sh"
  exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLY_STATIC_IP="${APPLY_STATIC_IP:-yes}"
IFACE="${MWS_IFACE:-${1:-}}"

detect_iface() {
  local iface
  iface="$(ip route | awk '/default/ {print $5; exit}')" || true
  if [ -z "$iface" ]; then
    iface="$(ls /sys/class/net | grep -E '^(en|eth)' | head -n 1 || true)"
  fi
  printf '%s\n' "$iface"
}

configure_suricata_interface() {
  local iface="$1"
  local conf="/etc/suricata/suricata.yaml"
  local defaults="/etc/default/suricata"
  local tmp

  if [ -f "$conf" ]; then
    # Keep HOME_NET inside vars.address-groups. The previous unanchored replacement
    # could remove YAML indentation and prevent Suricata from starting.
    sed -i -E 's|^[[:space:]]*HOME_NET:[[:space:]]*.*|    HOME_NET: "[192.168.1.0/24]"|' "$conf"

    tmp="$(mktemp)"
    awk -v iface="$iface" '
      /^[^[:space:]#][^:]*:/ {
        in_af_packet = ($0 ~ /^af-packet:[[:space:]]*($|#)/)
      }
      in_af_packet && !updated && /^[[:space:]]*-[[:space:]]*interface:[[:space:]]*/ {
        sub(/interface:[[:space:]]*.*/, "interface: " iface)
        updated = 1
      }
      { print }
    ' "$conf" > "$tmp"
    cat "$tmp" > "$conf"
    rm -f "$tmp"
  fi

  if [ -f "$defaults" ]; then
    if grep -q '^IFACE=' "$defaults"; then
      sed -i "s|^IFACE=.*|IFACE=$iface|" "$defaults"
    else
      printf '\nIFACE=%s\n' "$iface" >> "$defaults"
    fi

    if grep -q '^LISTENMODE=' "$defaults"; then
      sed -i 's|^LISTENMODE=.*|LISTENMODE=af-packet|' "$defaults"
    else
      printf '\nLISTENMODE=af-packet\n' >> "$defaults"
    fi
  fi
}

if [ -z "$IFACE" ]; then
  IFACE="$(detect_iface)"
fi
if [ -z "$IFACE" ]; then
  echo "[ERROR] Could not detect network interface. Pass it manually: sudo bash setup.sh enp0s3"
  exit 1
fi

if [ "$APPLY_STATIC_IP" = "yes" ]; then
  bash "$REPO_DIR/scripts/apply_static_ip.sh" "$IFACE"
else
  hostnamectl set-hostname mws-ids01
fi

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y suricata python3 jq tcpdump netcat-openbsd

bash "$REPO_DIR/scripts/install_suricata_rules.sh"
mkdir -p /opt/mws-ids
cp "$REPO_DIR/src/ids_log_watcher.py" /opt/mws-ids/ids_log_watcher.py
chmod +x /opt/mws-ids/ids_log_watcher.py
cp "$REPO_DIR/systemd/mws-ids-watch.service" /etc/systemd/system/mws-ids-watch.service

configure_suricata_interface "$IFACE"

if [ -f /etc/suricata/suricata.yaml ]; then
  suricata -T -c /etc/suricata/suricata.yaml
fi

systemctl daemon-reload
systemctl enable suricata mws-ids-watch
systemctl restart suricata
systemctl restart mws-ids-watch
sleep 2
systemctl --no-pager status suricata
systemctl --no-pager status mws-ids-watch

echo "[DONE] VM4 IDS setup complete."
echo "Verify with: bash verify.sh"
