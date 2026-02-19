#!/usr/bin/env bash
# HTH Cursor Control 2.02: Configure AI Provider Restrictions
# Profile: L2 | NIST: SC-7
# https://howtoharden.com/guides/cursor/#22-configure-ai-provider-restrictions

set -euo pipefail

# --------------------------------------------------------------------------
# Restrict Cursor to approved AI providers only
# Apply to: ~/Library/Application Support/Cursor/User/settings.json (macOS)
#           %APPDATA%\Cursor\User\settings.json (Windows)
#           ~/.config/Cursor/User/settings.json (Linux)
# --------------------------------------------------------------------------

# HTH Guide Excerpt: begin cli-restrict-ai-providers
# Restrict to approved AI providers — disable unapproved vendors
CURSOR_SETTINGS_DIR="${HOME}/Library/Application Support/Cursor/User"
SETTINGS_FILE="${CURSOR_SETTINGS_DIR}/settings.json"

jq '. + {
  "cursor.aiProviders.openai.enabled": true,
  "cursor.aiProviders.anthropic.enabled": false,
  "cursor.aiProviders.allowCustom": false
}' "${SETTINGS_FILE}" > "${SETTINGS_FILE}.tmp" \
  && mv "${SETTINGS_FILE}.tmp" "${SETTINGS_FILE}"

echo "AI provider restrictions applied"
# HTH Guide Excerpt: end cli-restrict-ai-providers
