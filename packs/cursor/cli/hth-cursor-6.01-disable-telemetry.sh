#!/usr/bin/env bash
# HTH Cursor Control 6.01: Disable Telemetry and Crash Reporting
# Profile: L2 | NIST: SC-4
# https://howtoharden.com/guides/cursor/#61-disable-telemetry-and-crash-reporting

set -euo pipefail

# --------------------------------------------------------------------------
# Disable all telemetry data collection and crash reporting
# Apply to: ~/Library/Application Support/Cursor/User/settings.json (macOS)
#           %APPDATA%\Cursor\User\settings.json (Windows)
#           ~/.config/Cursor/User/settings.json (Linux)
# --------------------------------------------------------------------------

# HTH Guide Excerpt: begin cli-disable-telemetry
# Disable all telemetry — prevents code snippets and metadata from being sent
CURSOR_SETTINGS_DIR="${HOME}/Library/Application Support/Cursor/User"
SETTINGS_FILE="${CURSOR_SETTINGS_DIR}/settings.json"

jq '. + {
  "telemetry.telemetryLevel": "off",
  "cursor.telemetry.enabled": false,
  "redhat.telemetry.enabled": false
}' "${SETTINGS_FILE}" > "${SETTINGS_FILE}.tmp" \
  && mv "${SETTINGS_FILE}.tmp" "${SETTINGS_FILE}"

echo "Telemetry and crash reporting disabled"
# HTH Guide Excerpt: end cli-disable-telemetry
