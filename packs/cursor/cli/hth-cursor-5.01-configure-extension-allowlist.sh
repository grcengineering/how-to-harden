#!/usr/bin/env bash
# HTH Cursor Control 5.01: Audit and Restrict VSCode Extensions
# Profile: L1 | NIST: CM-7
# https://howtoharden.com/guides/cursor/#51-audit-and-restrict-vscode-extensions

set -euo pipefail

# --------------------------------------------------------------------------
# Configure extension allowlist (Cursor Business required for enforcement)
# Apply to: ~/Library/Application Support/Cursor/User/settings.json (macOS)
#           %APPDATA%\Cursor\User\settings.json (Windows)
#           ~/.config/Cursor/User/settings.json (Linux)
# --------------------------------------------------------------------------

# HTH Guide Excerpt: begin cli-extension-allowlist
# Restrict extensions to approved list and disable auto-update
CURSOR_SETTINGS_DIR="${HOME}/Library/Application Support/Cursor/User"
SETTINGS_FILE="${CURSOR_SETTINGS_DIR}/settings.json"

jq '. + {
  "extensions.allowedExtensions": [
    "github.copilot",
    "ms-python.python",
    "esbenp.prettier-vscode"
  ],
  "extensions.autoUpdate": false
}' "${SETTINGS_FILE}" > "${SETTINGS_FILE}.tmp" \
  && mv "${SETTINGS_FILE}.tmp" "${SETTINGS_FILE}"

echo "Extension allowlist configured"
# HTH Guide Excerpt: end cli-extension-allowlist
