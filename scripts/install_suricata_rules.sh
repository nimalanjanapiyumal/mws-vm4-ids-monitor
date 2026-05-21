#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo bash scripts/install_suricata_rules.sh"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RULE_DEST="/etc/suricata/rules/mws-local.rules"
mkdir -p /etc/suricata/rules
cp "$REPO_DIR/config/suricata_mws_local.rules" "$RULE_DEST"

# Add the rule file to suricata.yaml if it is not already present.
if [ -f /etc/suricata/suricata.yaml ]; then
  if ! grep -q "mws-local.rules" /etc/suricata/suricata.yaml; then
    sed -i '/rule-files:/a\  - mws-local.rules' /etc/suricata/suricata.yaml || true
  fi
fi

echo "[DONE] Installed MWS Suricata rules at $RULE_DEST"
