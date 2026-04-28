#!/usr/bin/env bash
# HTH Cursor Control 9.1: Disable Telemetry and Crash Reporting
# Profile: L2 | NIST: SC-4
# https://howtoharden.com/guides/cursor/#91-disable-telemetry-and-crash-reporting

# HTH Guide Excerpt: begin cli-telemetry-settings
# Cursor/VSCode settings to disable all telemetry and data collection
# Add to user settings.json:
cat <<'SETTINGS'
{
  "telemetry.telemetryLevel": "off",
  "telemetry.enableCrashReporter": false,
  "telemetry.enableTelemetry": false,
  "cursor.general.enableShadowWorkspace": false,
  "cursor.general.allowAnonymousUsage": false
}
SETTINGS
# HTH Guide Excerpt: end cli-telemetry-settings
