#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cursor-7.1
#   guide:   https://howtoharden.com/guides/cursor/#71-enable-workspace-trust-for-all-repositories
#   profile: L1
#   mode:    read-only
#   requires: grep
# =============================================================================
# HTH Cursor Control 7.1: Enable Workspace Trust for All Repositories
# Profile Level: L1 (Crawl) | NIST 800-53: CM-7
# Source: https://howtoharden.com/guides/cursor/#71-enable-workspace-trust-for-all-repositories
#
# `security.workspace.trust.*` and `task.allowAutomaticTasks` are VS Code
# settings that Cursor inherits; `security.workspace.trust.enabled` is also the
# client setting behind Cursor's `WorkspaceTrustEnabled` MDM policy
# (https://cursor.com/docs/enterprise/deployment-patterns,
# https://code.visualstudio.com/docs/editor/workspace-trust).
#
# Exit codes: 0 Workspace Trust enabled in every settings file found |
# 1 disabled or unset in at least one (Cursor's default is OFF)
# =============================================================================

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

FAILS=0
for f in "${SETTINGS_PATHS[@]}"; do
  if [ -f "$f" ]; then
    TRUST=$(grep -o '"security.workspace.trust.enabled"[[:space:]]*:[[:space:]]*[a-z]*' "$f" 2>/dev/null || echo "not set")
    TASKS=$(grep -o '"task.allowAutomaticTasks"[[:space:]]*:[[:space:]]*"[^"]*"' "$f" 2>/dev/null || echo "not set")
    echo "  $f:"
    echo "    Workspace Trust: $TRUST"
    echo "    Auto Tasks: $TASKS"

    if echo "$TRUST" | grep -q "false" || echo "$TRUST" | grep -q "not set"; then
      echo "    FAIL: Workspace Trust is disabled — repos with malicious .vscode/tasks.json can auto-execute code"
      FAILS=$((FAILS + 1))
    fi
  fi
done

# Non-zero exit when trust is off anywhere, so CI and fleet checks can gate on it.
[ "$FAILS" -eq 0 ] || exit 1
# HTH Guide Excerpt: end cli-verify-workspace-trust
