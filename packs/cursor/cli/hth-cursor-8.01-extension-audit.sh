#!/usr/bin/env bash
# HTH Cursor Control 8.1: Audit and Restrict VSCode Extensions
# Profile: L1 | NIST: CM-7
# https://howtoharden.com/guides/cursor/#81-audit-and-restrict-extensions

# HTH Guide Excerpt: begin cli-extension-audit
# List all installed extensions with install counts and publisher info
echo "=== Installed Extension Audit ==="
if command -v cursor &>/dev/null; then
  cursor --list-extensions --show-versions 2>/dev/null | while IFS= read -r ext; do
    echo "  $ext"
  done
  echo ""
  TOTAL=$(cursor --list-extensions 2>/dev/null | wc -l | tr -d ' ')
  echo "Total extensions: $TOTAL"
else
  echo "Cursor CLI not found in PATH"
  echo "Check: /Applications/Cursor.app/Contents/MacOS/Cursor --list-extensions"
fi

echo ""
echo "=== Extension Risk Checklist ==="
echo "  [ ] Remove extensions not updated in >1 year"
echo "  [ ] Remove extensions with <10K installs (less vetted)"
echo "  [ ] Verify publisher identity for all security-relevant extensions"
echo "  [ ] Check that no extensions were side-loaded from .vsix files"
echo "  [ ] Confirm extensions come from Open VSX with verified publishers"
# HTH Guide Excerpt: end cli-extension-audit
