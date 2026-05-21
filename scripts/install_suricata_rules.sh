#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo bash scripts/install_suricata_rules.sh"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SURICATA_CONF="${SURICATA_CONF:-/etc/suricata/suricata.yaml}"
RULE_NAME="mws-local.rules"

rule_path_from_config() {
  if [ ! -f "$SURICATA_CONF" ]; then
    return 0
  fi

  awk '
    /^[[:space:]]*default-rule-path:[[:space:]]*/ {
      sub(/^[^:]*:[[:space:]]*/, "", $0)
      gsub(/[[:space:]"]/, "", $0)
      gsub(/\047/, "", $0)
      print
      exit
    }
  ' "$SURICATA_CONF"
}

RULE_PATH="$(rule_path_from_config)"
if [ -z "$RULE_PATH" ]; then
  RULE_PATH="/etc/suricata/rules"
fi

RULE_DEST="$RULE_PATH/$RULE_NAME"
mkdir -p "$RULE_PATH"
cp "$REPO_DIR/config/suricata_mws_local.rules" "$RULE_DEST"
chmod 0644 "$RULE_DEST"

# Keep the conventional /etc path available for admins even when the packaged
# Suricata config loads rules from /var/lib/suricata/rules.
mkdir -p /etc/suricata/rules
if [ "/etc/suricata/rules/$RULE_NAME" != "$RULE_DEST" ]; then
  ln -sf "$RULE_DEST" "/etc/suricata/rules/$RULE_NAME"
fi

# Add the rule file to suricata.yaml if it is not already present.
if [ -f "$SURICATA_CONF" ]; then
  if ! grep -q "$RULE_NAME" "$SURICATA_CONF"; then
    if grep -q '^[[:space:]]*rule-files:[[:space:]]*' "$SURICATA_CONF"; then
      sed -i "/^[[:space:]]*rule-files:[[:space:]]*/a\\  - $RULE_NAME" "$SURICATA_CONF"
    else
      printf '\nrule-files:\n  - %s\n' "$RULE_NAME" >> "$SURICATA_CONF"
    fi
  fi
fi

echo "[DONE] Installed MWS Suricata rules at $RULE_DEST"
