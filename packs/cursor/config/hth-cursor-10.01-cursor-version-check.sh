#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cursor-10.1
#   guide:   https://howtoharden.com/guides/cursor/#101-enable-cursor-usage-logging
#   profile: L2
#   mode:    read-only
#   requires: sort -V; the cursor CLI shim or an installed Cursor.app; HTH_CURSOR_MIN_VERSION(optional, default 2.1)
# =============================================================================
# HTH Cursor Control 10.1: Enable Cursor Usage Logging — client version floor
# Profile Level: L2 (Walk) | NIST 800-53: AU-2, SI-2
# Source: https://howtoharden.com/guides/cursor/#101-enable-cursor-usage-logging
#
# Several controls in this guide only apply above a client version: dashboard
# extension restrictions need Cursor 2.1+ (8.1), Linux MDM policy files need
# 2.0+ (11.2). An endpoint below the floor silently lacks them. The default
# floor is 2.1; raise HTH_CURSOR_MIN_VERSION to your organization's minimum
# (Cursor also enforces its own "minimum allowed version",
# https://cursor.com/docs/enterprise/deployment-patterns#minimum-versions).
#
# Exit codes: 0 at or above the floor | 1 below the floor | 2 version could
# not be determined (not a pass: an unreadable fleet is an unverified fleet)
# =============================================================================

# HTH Guide Excerpt: begin cli-version-check
MIN_VERSION="${HTH_CURSOR_MIN_VERSION:-2.1}"
echo "=== Cursor Version Check (floor ${MIN_VERSION}) ==="
CURSOR_VERSION=""
if command -v cursor &>/dev/null; then
  CURSOR_VERSION=$(cursor --version 2>/dev/null | head -1)
fi
if [ -z "$CURSOR_VERSION" ]; then
  for PKG in \
    "${HTH_CURSOR_APP:-/Applications/Cursor.app}/Contents/Resources/app/package.json" \
    "${HOME}/Applications/Cursor.app/Contents/Resources/app/package.json"; do
    if [ -f "$PKG" ]; then
      CURSOR_VERSION=$(sed -n 's/^[[:space:]]*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$PKG" | head -1)
      [ -n "$CURSOR_VERSION" ] && break
    fi
  done
fi

# Keep only the leading numeric version (e.g. "2.1.3" from "2.1.3 abc123 arm64")
CURSOR_VERSION=$(printf '%s' "$CURSOR_VERSION" | grep -Eo '^[0-9]+(\.[0-9]+)*' | head -1)
if [ -z "$CURSOR_VERSION" ]; then
  echo "  ERROR: Cursor version could not be determined (no cursor CLI, no readable Cursor.app)"
  exit 2
fi

echo "  Installed version: $CURSOR_VERSION"
LOWEST=$(printf '%s\n%s\n' "$CURSOR_VERSION" "$MIN_VERSION" | sort -V | head -1)
if [ "$LOWEST" = "$MIN_VERSION" ]; then
  echo "  PASS: $CURSOR_VERSION >= $MIN_VERSION"
  exit 0
fi
echo "  FAIL: $CURSOR_VERSION is below the floor $MIN_VERSION — version-gated controls (8.1 extension restrictions) do not apply"
exit 1
# HTH Guide Excerpt: end cli-version-check
