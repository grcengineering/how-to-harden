#!/usr/bin/env bash
# HTH Auth0 Control 1.1: Enable Brute Force Protection
# Profile: L1 | NIST: AC-7, SI-4 | CIS: 4.10
# https://howtoharden.com/guides/auth0/#11-enable-brute-force-protection
source "$(dirname "$0")/common.sh"

banner "1.1: Enable Brute Force Protection"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.1 Checking brute force protection settings..."

CURRENT=$(a0_get "/attack-protection/brute-force-protection") || {
  fail "1.1 Unable to retrieve brute force protection settings"
  increment_failed; summary; exit 0
}

ENABLED=$(echo "${CURRENT}" | jq -r '.enabled')
MAX_ATTEMPTS=$(echo "${CURRENT}" | jq -r '.max_attempts')

if [ "${ENABLED}" = "true" ]; then
  pass "1.1 Brute force protection is enabled (max_attempts: ${MAX_ATTEMPTS})"
  if [ "${MAX_ATTEMPTS}" -gt 5 ]; then
    warn "1.1 max_attempts (${MAX_ATTEMPTS}) is higher than recommended (5)"
  fi
  increment_applied; summary; exit 0
fi

# HTH Guide Excerpt: begin api-enable-brute-force
# Enable brute force protection with hardened thresholds
info "1.1 Enabling brute force protection..."
RESPONSE=$(a0_patch "/attack-protection/brute-force-protection" '{
  "enabled": true,
  "shields": ["block", "user_notification"],
  "mode": "count_per_identifier_and_ip",
  "max_attempts": 5
}') || {
  fail "1.1 Failed to enable brute force protection"
  increment_failed; summary; exit 0
}
# HTH Guide Excerpt: end api-enable-brute-force

RESULT=$(echo "${RESPONSE}" | jq -r '.enabled')
if [ "${RESULT}" = "true" ]; then
  pass "1.1 Brute force protection enabled"
  increment_applied
else
  fail "1.1 Brute force protection not confirmed"
  increment_failed
fi
summary
