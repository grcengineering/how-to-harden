#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cursor-9.1
#   guide:   https://howtoharden.com/guides/cursor/#91-disable-telemetry-and-crash-reporting
#   profile: L2
#   mode:    read-only
#   requires: grep
# =============================================================================
# HTH Cursor Control 9.1: Disable Telemetry and Crash Reporting
# Profile Level: L2 (Walk) | NIST 800-53: SC-4
# Source: https://howtoharden.com/guides/cursor/#91-disable-telemetry-and-crash-reporting
#
# `telemetry.telemetryLevel` is the documented VS Code telemetry setting
# (https://code.visualstudio.com/docs/configure/telemetry): "off" sends no crash
# reports, no error telemetry and no usage data. The older
# `telemetry.enableTelemetry` / `telemetry.enableCrashReporter` booleans do not
# appear on that page, and Cursor documents no `cursor.general.*` telemetry key —
# earlier revisions of this pack wrote keys that no current doc defines.
#
# Exit codes: 0 telemetryLevel is "off" in every settings file found |
# 1 missing or not "off" | 2 no Cursor settings file found
# =============================================================================

# HTH Guide Excerpt: begin cli-telemetry-settings
# Add to Cursor user settings.json:
cat <<'SETTINGS'
{
  "telemetry.telemetryLevel": "off"
}
SETTINGS
# HTH Guide Excerpt: end cli-telemetry-settings

# HTH Guide Excerpt: begin cli-verify-telemetry
echo "=== Telemetry setting ==="
FOUND=0
FAILS=0
for f in \
  "${HOME}/Library/Application Support/Cursor/User/settings.json" \
  "${HOME}/.config/Cursor/User/settings.json" \
  "${APPDATA:-/nonexistent}/Cursor/User/settings.json"; do
  [ -f "$f" ] || continue
  FOUND=$((FOUND + 1))
  LEVEL=$(grep -o '"telemetry.telemetryLevel"[[:space:]]*:[[:space:]]*"[^"]*"' "$f" | sed 's/.*:[[:space:]]*"\([^"]*\)"/\1/' | tail -1)
  if [ "$LEVEL" = "off" ]; then
    echo "  PASS: $f — telemetryLevel=off"
  else
    echo "  FAIL: $f — telemetryLevel=${LEVEL:-unset}"
    FAILS=$((FAILS + 1))
  fi
done
if [ "$FOUND" -eq 0 ]; then
  echo "  ERROR: no Cursor user settings.json found — nothing to verify"
  exit 2
fi
[ "$FAILS" -eq 0 ] || exit 1
# HTH Guide Excerpt: end cli-verify-telemetry
