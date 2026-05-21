#!/usr/bin/env bash
set -euo pipefail

echo "[CHECK] Hostname and IP"
hostnamectl --static
ip -4 addr | grep -E '192\.168\.1\.40|inet ' || true

echo "[CHECK] Suricata service"
if systemctl is-active --quiet suricata; then
  echo "active"
else
  echo "inactive or failed"
  echo "[CHECK] Suricata config test"
  sudo suricata -T -c /etc/suricata/suricata.yaml || true

  echo "[CHECK] Recent Suricata service errors"
  sudo journalctl -u suricata.service -n 30 --no-pager || true

  echo "[CHECK] Recent Suricata application log"
  sudo tail -n 30 /var/log/suricata/suricata.log 2>/dev/null || true
fi

echo "[CHECK] MWS local rule loaded"
grep -R "245000" /etc/suricata/rules /var/lib/suricata/rules 2>/dev/null | head || true

echo "[CHECK] Log watcher service"
systemctl is-active mws-ids-watch || true

echo "[CHECK] Recent IDS logs"
sudo tail -n 20 /var/log/suricata/fast.log 2>/dev/null || true

echo "[DONE] VM4 verification complete."
