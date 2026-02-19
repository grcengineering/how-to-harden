#!/usr/bin/env bash
# HTH Cursor Control 2.01: Disable Privacy Mode for Sensitive Codebases
# Profile: L1 | NIST: SC-4
# https://howtoharden.com/guides/cursor/#21-disable-privacy-mode-for-sensitive-codebases

set -euo pipefail

# --------------------------------------------------------------------------
# Option 1: Global Privacy Settings
# Apply to: ~/Library/Application Support/Cursor/User/settings.json (macOS)
#           %APPDATA%\Cursor\User\settings.json (Windows)
#           ~/.config/Cursor/User/settings.json (Linux)
# --------------------------------------------------------------------------

# HTH Guide Excerpt: begin cli-global-privacy-config
# Global settings — disables cloud AI providers and enables privacy mode
CURSOR_SETTINGS_DIR="${HOME}/Library/Application Support/Cursor/User"
SETTINGS_FILE="${CURSOR_SETTINGS_DIR}/settings.json"

# Merge privacy settings into existing config (requires jq)
jq '. + {
  "cursor.privacyMode": true,
  "cursor.telemetry": false,
  "cursor.aiProviders.allowOpenAI": false,
  "cursor.aiProviders.allowAnthropic": false
}' "${SETTINGS_FILE}" > "${SETTINGS_FILE}.tmp" \
  && mv "${SETTINGS_FILE}.tmp" "${SETTINGS_FILE}"

echo "Global privacy mode enabled for Cursor"
# HTH Guide Excerpt: end cli-global-privacy-config

# --------------------------------------------------------------------------
# Option 2: Workspace Privacy Settings
# Apply to: .vscode/settings.json in each repository root
# --------------------------------------------------------------------------

# HTH Guide Excerpt: begin cli-workspace-privacy-config
# Workspace settings — commit to repo to enforce per-project privacy
mkdir -p .vscode
cat > .vscode/settings.json << 'EOF'
{
  "cursor.privacyMode": true,
  "cursor.chat.enabled": false,
  "cursor.autocomplete.enabled": false
}
EOF

echo "Workspace privacy settings written to .vscode/settings.json"
# HTH Guide Excerpt: end cli-workspace-privacy-config

# --------------------------------------------------------------------------
# Option 3: Policy Enforcement Script
# Enforce privacy mode across all Cursor installations
# --------------------------------------------------------------------------

# HTH Guide Excerpt: begin cli-enforce-privacy-policy
# Enforce Privacy Mode for all Cursor workspaces
CURSOR_SETTINGS_DIR="${HOME}/Library/Application Support/Cursor/User"
SETTINGS_FILE="${CURSOR_SETTINGS_DIR}/settings.json"

# Enable global privacy mode
jq '.["cursor.privacyMode"] = true' "${SETTINGS_FILE}" > tmp.json \
  && mv tmp.json "${SETTINGS_FILE}"

echo "Privacy Mode enabled globally for Cursor"
# HTH Guide Excerpt: end cli-enforce-privacy-policy
