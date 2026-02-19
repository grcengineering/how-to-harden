#!/usr/bin/env bash
# HTH Cursor Control 4.01: Enable Workspace Trust for All Repositories
# Profile: L1 | NIST: CM-7
# https://howtoharden.com/guides/cursor/#41-enable-workspace-trust-for-all-repositories

set -euo pipefail

# --------------------------------------------------------------------------
# Configure Workspace Trust settings to prevent untrusted code execution
# Apply to: ~/Library/Application Support/Cursor/User/settings.json (macOS)
#           %APPDATA%\Cursor\User\settings.json (Windows)
#           ~/.config/Cursor/User/settings.json (Linux)
# --------------------------------------------------------------------------

# HTH Guide Excerpt: begin cli-enable-workspace-trust
# Enable Workspace Trust — prevent automatic code execution in untrusted repos
CURSOR_SETTINGS_DIR="${HOME}/Library/Application Support/Cursor/User"
SETTINGS_FILE="${CURSOR_SETTINGS_DIR}/settings.json"

jq '. + {
  "security.workspace.trust.enabled": true,
  "security.workspace.trust.startupPrompt": "always",
  "security.workspace.trust.emptyWindow": false,
  "security.workspace.trust.untrustedFiles": "restricted"
}' "${SETTINGS_FILE}" > "${SETTINGS_FILE}.tmp" \
  && mv "${SETTINGS_FILE}.tmp" "${SETTINGS_FILE}"

echo "Workspace Trust enabled"
# HTH Guide Excerpt: end cli-enable-workspace-trust

# --------------------------------------------------------------------------
# Configure Trusted Folders — restrict trust to known-good paths
# --------------------------------------------------------------------------

# HTH Guide Excerpt: begin cli-configure-trusted-folders
# Add trusted parent directories for company and personal code
CURSOR_SETTINGS_DIR="${HOME}/Library/Application Support/Cursor/User"
SETTINGS_FILE="${CURSOR_SETTINGS_DIR}/settings.json"

jq '. + {
  "security.workspace.trust.trustedFolders": [
    "~/work/company-name",
    "~/projects/personal"
  ]
}' "${SETTINGS_FILE}" > "${SETTINGS_FILE}.tmp" \
  && mv "${SETTINGS_FILE}.tmp" "${SETTINGS_FILE}"

echo "Trusted folders configured"
# HTH Guide Excerpt: end cli-configure-trusted-folders
