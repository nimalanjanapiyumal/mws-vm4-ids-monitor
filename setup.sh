#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo bash setup.sh"
  exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLY_STATIC_IP="${APPLY_STATIC_IP:-yes}"

if [ "$APPLY_STATIC_IP" = "yes" ]; then
  bash "$REPO_DIR/scripts/apply_static_ip.sh"
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

# Try to set HOME_NET to the lab range for better alert context.
if [ -f /etc/suricata/suricata.yaml ]; then
  sed -i 's|HOME_NET:.*|HOME_NET: "[192.168.1.0/24]"|g' /etc/suricata/suricata.yaml || true
fi

systemctl daemon-reload
systemctl enable suricata mws-ids-watch
systemctl restart suricata || true
systemctl restart mws-ids-watch
sleep 2
systemctl --no-pager status suricata || true
systemctl --no-pager status mws-ids-watch || true

echo "[DONE] VM4 IDS setup complete."
echo "Verify with: bash verify.sh"
