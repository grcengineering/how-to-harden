#!/usr/bin/env bash
# HTH Cursor Control 8.01: Deploy Cursor Business for Centralized Management
# Profile: L2
# https://howtoharden.com/guides/cursor/#81-deploy-cursor-business-for-centralized-management

set -euo pipefail

# --------------------------------------------------------------------------
# Deploy organization-wide managed settings via MDM (Jamf, Intune, etc.)
# Apply to: ~/Library/Application Support/Cursor/User/settings.json (macOS)
#           %APPDATA%\Cursor\User\settings.json (Windows)
#           ~/.config/Cursor/User/settings.json (Linux)
# --------------------------------------------------------------------------

# HTH Guide Excerpt: begin cli-deploy-managed-settings
# Organization-wide managed settings for Cursor Business
# Deploy via MDM (Jamf, Intune, etc.) to all developer machines
CURSOR_SETTINGS_DIR="${HOME}/Library/Application Support/Cursor/User"
SETTINGS_FILE="${CURSOR_SETTINGS_DIR}/settings.json"

jq '. + {
  "cursor.privacyMode": true,
  "cursor.aiProviders.openai.enabled": true,
  "cursor.aiProviders.anthropic.enabled": false,
  "cursor.telemetry.enabled": false,
  "security.workspace.trust.enabled": true
}' "${SETTINGS_FILE}" > "${SETTINGS_FILE}.tmp" \
  && mv "${SETTINGS_FILE}.tmp" "${SETTINGS_FILE}"

echo "Organization-wide managed settings deployed"
# HTH Guide Excerpt: end cli-deploy-managed-settings
