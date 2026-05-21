#!/usr/bin/env bash
set -euo pipefail

echo "[CHECK] Hostname and IP"
hostnamectl --static
ip -4 addr | grep -E '192\.168\.1\.40|inet ' || true

echo "[CHECK] Suricata service"
systemctl is-active suricata || true

echo "[CHECK] MWS local rule loaded"
grep -R "245000" /etc/suricata/rules /var/lib/suricata/rules 2>/dev/null | head || true

echo "[CHECK] Log watcher service"
systemctl is-active mws-ids-watch || true

echo "[CHECK] Recent IDS logs"
sudo tail -n 20 /var/log/suricata/fast.log 2>/dev/null || true

echo "[DONE] VM4 verification complete."
