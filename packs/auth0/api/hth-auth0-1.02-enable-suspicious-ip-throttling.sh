#!/usr/bin/env bash
# HTH Auth0 Control 1.2: Enable Suspicious IP Throttling
# Profile: L1 | NIST: SI-4 | CIS: 4.10
# https://howtoharden.com/guides/auth0/#12-enable-suspicious-ip-throttling
source "$(dirname "$0")/common.sh"

banner "1.2: Enable Suspicious IP Throttling"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.2 Checking suspicious IP throttling..."

CURRENT=$(a0_get "/attack-protection/suspicious-ip-throttling") || {
  fail "1.2 Unable to retrieve suspicious IP throttling settings"
  increment_failed; summary; exit 0
}

ENABLED=$(echo "${CURRENT}" | jq -r '.enabled')

if [ "${ENABLED}" = "true" ]; then
  pass "1.2 Suspicious IP throttling is enabled"
  increment_applied; summary; exit 0
fi

# HTH Guide Excerpt: begin api-enable-ip-throttling
# Enable suspicious IP throttling
info "1.2 Enabling suspicious IP throttling..."
RESPONSE=$(a0_patch "/attack-protection/suspicious-ip-throttling" '{
  "enabled": true,
  "shields": ["admin_notification", "block"],
  "stage": {
    "pre-login": { "max_attempts": 100, "rate": 864000 },
    "pre-user-registration": { "max_attempts": 50, "rate": 1200000 }
  }
}') || {
  fail "1.2 Failed to enable suspicious IP throttling"
  increment_failed; summary; exit 0
}
# HTH Guide Excerpt: end api-enable-ip-throttling

RESULT=$(echo "${RESPONSE}" | jq -r '.enabled')
[ "${RESULT}" = "true" ] && { pass "1.2 Suspicious IP throttling enabled"; increment_applied; } || { fail "1.2 Not confirmed"; increment_failed; }
summary
