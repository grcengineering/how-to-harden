#!/usr/bin/env bash
# HTH Cursor Control 2.1: Enable Privacy Mode for Sensitive Codebases
# Profile: L1 | NIST: SC-4
# https://howtoharden.com/guides/cursor/#21-enable-privacy-mode-for-sensitive-codebases

# HTH Guide Excerpt: begin cli-workspace-privacy-settings
# .vscode/settings.json — per-workspace Privacy Mode enforcement
cat > .vscode/settings.json <<'SETTINGS'
{
  "cursor.general.privacyMode": "enabled",
  "cursor.general.enableShadowWorkspace": false,
  "cursor.general.allowAnonymousUsage": false
}
SETTINGS
echo "Privacy Mode workspace settings written to .vscode/settings.json"
# HTH Guide Excerpt: end cli-workspace-privacy-settings

# HTH Guide Excerpt: begin cli-verify-privacy-mode
# Verify Privacy Mode is active across all workspace settings files
echo "=== Checking for Privacy Mode in settings files ==="
for f in \
  "${HOME}/Library/Application Support/Cursor/User/settings.json" \
  "${HOME}/.config/Cursor/User/settings.json" \
  ".vscode/settings.json"; do
  if [ -f "$f" ]; then
    PRIVACY=$(grep -o '"cursor.general.privacyMode"[[:space:]]*:[[:space:]]*"[^"]*"' "$f" 2>/dev/null || echo "not set")
    echo "  $f: $PRIVACY"
  fi
done

echo ""
echo "=== Checking network traffic to AI provider APIs ==="
echo "Run one of these to verify no code leaks to cloud providers:"
echo "  macOS:  lsof -i -n -P | grep -i cursor | grep -E '(openai|anthropic)'"
echo "  Linux:  ss -tnp | grep cursor | grep -E '(openai|anthropic)'"
# HTH Guide Excerpt: end cli-verify-privacy-mode
