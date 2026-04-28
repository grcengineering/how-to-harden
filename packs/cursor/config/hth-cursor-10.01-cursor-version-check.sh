#!/usr/bin/env bash
# HTH Cursor Control 10.1: Verify Cursor Version and Patch Status
# Profile: L1 | NIST: SI-2
# https://howtoharden.com/guides/cursor/#101-enable-cursor-usage-logging

# HTH Guide Excerpt: begin cli-version-check
# Verify Cursor is running a patched version (minimum 1.7+ for 2025 CVE fixes)
echo "=== Cursor Version Check ==="
CURSOR_VERSION=""
if command -v cursor &>/dev/null; then
  CURSOR_VERSION=$(cursor --version 2>/dev/null | head -1)
elif [ -f "/Applications/Cursor.app/Contents/Resources/app/package.json" ]; then
  CURSOR_VERSION=$(grep '"version"' "/Applications/Cursor.app/Contents/Resources/app/package.json" 2>/dev/null | head -1)
fi

if [ -n "$CURSOR_VERSION" ]; then
  echo "  Installed version: $CURSOR_VERSION"
  echo ""
  echo "  Minimum safe versions:"
  echo "    >= 1.3   Patches CVE-2025-54135 (CurXecute) and CVE-2025-54136 (MCPoison)"
  echo "    >= 1.7   Patches CVE-2025-59944, CVE-2025-61590 through CVE-2025-61593"
  echo "    >= 2.0   Adds agent sandbox (macOS), improved MCP approval"
  echo "    >= 2.5   Adds sandbox network access controls"
else
  echo "  Unable to determine Cursor version"
fi
# HTH Guide Excerpt: end cli-version-check
