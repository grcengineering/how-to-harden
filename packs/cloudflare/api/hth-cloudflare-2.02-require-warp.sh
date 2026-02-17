#!/usr/bin/env bash
# HTH Cloudflare Control 2.2: Require WARP for Application Access
# Profile: L2 | NIST: AC-2(11) | CIS: 4.1, 6.4
# https://howtoharden.com/guides/cloudflare/#22-require-warp-for-application-access
source "$(dirname "$0")/common.sh"

banner "2.2: Require WARP for Application Access"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "2.2 Checking device posture rules for WARP requirement..."

# HTH Guide Excerpt: begin api-check-warp-posture
# Check for a WARP device posture rule
POSTURE_RULES=$(cf_get "/accounts/${CF_ACCOUNT_ID}/devices/posture") || {
  fail "2.2 Unable to retrieve device posture rules"
  increment_failed
  summary
  exit 0
}

WARP_RULES=$(echo "${POSTURE_RULES}" | jq '[.result[] | select(.type == "warp")] | length')

if [ "${WARP_RULES}" -gt 0 ]; then
  pass "2.2 WARP device posture rule exists (${WARP_RULES} rule(s))"
  echo "${POSTURE_RULES}" | jq -r '.result[] | select(.type == "warp") | "  - \(.name): \(.type)"'
else
  warn "2.2 No WARP device posture rule found -- create one to require WARP for app access"
fi
# HTH Guide Excerpt: end api-check-warp-posture

increment_applied
summary
