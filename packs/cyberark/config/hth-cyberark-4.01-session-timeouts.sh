#!/usr/bin/env bash
# HTH CyberArk Control 4.1: Configure PSM Session Security — Timeouts
# Profile: L1 | NIST: AC-12, AU-14
# https://howtoharden.com/guides/cyberark/#41-configure-psm-session-security
#
# CyberArk Platform configuration values for PSM session-security policy.
# Apply via the CyberArk PVWA UI or the Platform Management API.
# (No first-party CyberArk CLI exists for PSM platform config.)

set -euo pipefail

OUT_FILE="${OUT_FILE:-./psm-session-timeouts.platform.conf}"

# HTH Guide Excerpt: begin config-session-timeouts
cat > "${OUT_FILE}" <<'CONF'
MaxSessionDuration=480  # 8 hours maximum
IdleSessionTimeout=30   # 30 minutes idle
WarningBeforeTimeout=5  # 5 minute warning
CONF
# HTH Guide Excerpt: end config-session-timeouts

echo "Wrote PSM session-timeout config to ${OUT_FILE}"
echo "Apply these values to the target Platform via PVWA → Platform Management."
