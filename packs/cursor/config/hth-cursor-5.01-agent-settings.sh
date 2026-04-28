#!/usr/bin/env bash
# HTH Cursor Control 5.1: Disable Auto-Run Mode for Agent Commands
# Profile: L1 | NIST: CM-7, AC-6
# https://howtoharden.com/guides/cursor/#51-disable-auto-run-mode

# HTH Guide Excerpt: begin cli-agent-settings
# Cursor settings to disable auto-run and enforce manual approval
# Add to .vscode/settings.json or user settings:
cat <<'SETTINGS'
{
  "cursor.agent.autoRun": false,
  "cursor.agent.enableSandbox": true,
  "cursor.agent.requireApprovalForCommands": true
}
SETTINGS
# HTH Guide Excerpt: end cli-agent-settings

# HTH Guide Excerpt: begin cli-verify-autorun-disabled
# Verify auto-run is disabled in all settings locations
echo "=== Checking Agent Auto-Run Status ==="
SETTINGS_PATHS=(
  "${HOME}/Library/Application Support/Cursor/User/settings.json"
  "${HOME}/.config/Cursor/User/settings.json"
  ".vscode/settings.json"
)

for f in "${SETTINGS_PATHS[@]}"; do
  if [ -f "$f" ]; then
    AUTORUN=$(grep -o '"cursor.agent.autoRun"[[:space:]]*:[[:space:]]*[a-z]*' "$f" 2>/dev/null || echo "not set")
    echo "  $f: $AUTORUN"
    if echo "$AUTORUN" | grep -q "true"; then
      echo "    WARN: Auto-run is ENABLED — this allows agent to execute commands without approval"
    fi
  fi
done
# HTH Guide Excerpt: end cli-verify-autorun-disabled
