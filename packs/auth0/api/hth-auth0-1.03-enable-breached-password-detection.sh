#!/usr/bin/env bash
# HTH Auth0 Control 1.3: Enable Breached Password Detection
# Profile: L1 | NIST: IA-5 | CIS: 5.2
# https://howtoharden.com/guides/auth0/#13-enable-breached-password-detection
source "$(dirname "$0")/common.sh"

banner "1.3: Enable Breached Password Detection"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.3 Checking breached password detection..."

CURRENT=$(a0_get "/attack-protection/breached-password-detection") || {
  fail "1.3 Unable to retrieve breached password detection settings"
  increment_failed; summary; exit 0
}

ENABLED=$(echo "${CURRENT}" | jq -r '.enabled')

if [ "${ENABLED}" = "true" ]; then
  pass "1.3 Breached password detection is enabled"
  increment_applied; summary; exit 0
fi

# HTH Guide Excerpt: begin api-enable-breached-pw
# Enable breached password detection
info "1.3 Enabling breached password detection..."
RESPONSE=$(a0_patch "/attack-protection/breached-password-detection" '{
  "enabled": true,
  "method": "standard",
  "shields": ["admin_notification", "block"],
  "admin_notification_frequency": ["immediately"],
  "stage": {
    "pre-user-registration": { "shields": ["block"] }
  }
}') || {
  fail "1.3 Failed to enable breached password detection (may require Professional plan)"
  increment_failed; summary; exit 0
}
# HTH Guide Excerpt: end api-enable-breached-pw

RESULT=$(echo "${RESPONSE}" | jq -r '.enabled')
[ "${RESULT}" = "true" ] && { pass "1.3 Breached password detection enabled"; increment_applied; } || { fail "1.3 Not confirmed"; increment_failed; }
summary
