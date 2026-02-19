#!/usr/bin/env bash
# HTH Cursor Control 7.01: Enable Cursor Usage Logging
# Profile: L2 | NIST: AU-2
# https://howtoharden.com/guides/cursor/#71-enable-cursor-usage-logging

set -euo pipefail

# --------------------------------------------------------------------------
# Step 1: Enable built-in logging for AI interactions
# Apply to: ~/Library/Application Support/Cursor/User/settings.json (macOS)
#           %APPDATA%\Cursor\User\settings.json (Windows)
#           ~/.config/Cursor/User/settings.json (Linux)
# --------------------------------------------------------------------------

# HTH Guide Excerpt: begin cli-enable-logging
# Enable built-in logging for audit and compliance
CURSOR_SETTINGS_DIR="${HOME}/Library/Application Support/Cursor/User"
SETTINGS_FILE="${CURSOR_SETTINGS_DIR}/settings.json"

jq '. + {
  "cursor.logging.enabled": true,
  "cursor.logging.level": "info",
  "cursor.logging.outputChannel": true
}' "${SETTINGS_FILE}" > "${SETTINGS_FILE}.tmp" \
  && mv "${SETTINGS_FILE}.tmp" "${SETTINGS_FILE}"

echo "Cursor usage logging enabled"
# HTH Guide Excerpt: end cli-enable-logging

# --------------------------------------------------------------------------
# Step 2: Export logs to SIEM
# Parse Cursor logs and forward AI request events to a SIEM endpoint
# --------------------------------------------------------------------------

# HTH Guide Excerpt: begin cli-export-logs-to-siem
# Parse Cursor logs and send to SIEM
tail -f ~/Library/Logs/Cursor/main.log | grep "ai.request" | \
  while read line; do
    curl -X POST https://siem.company.com/cursor-logs \
      -H "Content-Type: application/json" \
      -d "$line"
  done
# HTH Guide Excerpt: end cli-export-logs-to-siem
