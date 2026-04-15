#!/usr/bin/env bash
# HTH Cursor Control 7.1: Enable Workspace Trust for All Repositories
# Profile: L1 | NIST: CM-7
# https://howtoharden.com/guides/cursor/#71-enable-workspace-trust

# HTH Guide Excerpt: begin cli-workspace-trust-settings
# Cursor user settings to enable Workspace Trust (disabled by default in Cursor)
# Add to user settings.json:
cat <<'SETTINGS'
{
  "security.workspace.trust.enabled": true,
  "security.workspace.trust.startupPrompt": "always",
  "security.workspace.trust.emptyWindow": false,
  "security.workspace.trust.untrustedFiles": "prompt",
  "task.allowAutomaticTasks": "off"
}
SETTINGS
# HTH Guide Excerpt: end cli-workspace-trust-settings

# HTH Guide Excerpt: begin cli-verify-workspace-trust
# Verify Workspace Trust is enabled (Cursor defaults it to OFF)
echo "=== Workspace Trust Verification ==="
SETTINGS_PATHS=(
  "${HOME}/Library/Application Support/Cursor/User/settings.json"
  "${HOME}/.config/Cursor/User/settings.json"
)

for f in "${SETTINGS_PATHS[@]}"; do
  if [ -f "$f" ]; then
    TRUST=$(grep -o '"security.workspace.trust.enabled"[[:space:]]*:[[:space:]]*[a-z]*' "$f" 2>/dev/null || echo "not set")
    TASKS=$(grep -o '"task.allowAutomaticTasks"[[:space:]]*:[[:space:]]*"[^"]*"' "$f" 2>/dev/null || echo "not set")
    echo "  $f:"
    echo "    Workspace Trust: $TRUST"
    echo "    Auto Tasks: $TASKS"

    if echo "$TRUST" | grep -q "false" || echo "$TRUST" | grep -q "not set"; then
      echo "    FAIL: Workspace Trust is disabled — repos with malicious .vscode/tasks.json can auto-execute code"
    fi
  fi
done
# HTH Guide Excerpt: end cli-verify-workspace-trust
