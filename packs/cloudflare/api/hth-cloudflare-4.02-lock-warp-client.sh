#!/usr/bin/env bash
# HTH Cloudflare Control 4.2: Lock WARP Client
# Profile: L2 | NIST: CM-7 | CIS: 4.1
# https://howtoharden.com/guides/cloudflare/#42-lock-warp-client
source "$(dirname "$0")/common.sh"

banner "4.2: Lock WARP Client"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "4.2 Checking WARP lock settings..."

CURRENT=$(cf_get "/accounts/${CF_ACCOUNT_ID}/devices/policy") || {
  fail "4.2 Unable to retrieve device policy"
  increment_failed
  summary
  exit 0
}

LOCKED=$(echo "${CURRENT}" | jq -r '.result.switch_locked // false')
LEAVE=$(echo "${CURRENT}" | jq -r '.result.allowed_to_leave // true')

if [ "${LOCKED}" = "true" ] && [ "${LEAVE}" = "false" ]; then
  pass "4.2 WARP client is already locked"
  increment_applied
  summary
  exit 0
fi

# HTH Guide Excerpt: begin api-lock-warp
# Lock WARP client to prevent users from disabling
info "4.2 Locking WARP client..."
RESPONSE=$(cf_patch "/accounts/${CF_ACCOUNT_ID}/devices/policy" '{
  "switch_locked": true,
  "allowed_to_leave": false,
  "allow_mode_switch": false
}') || {
  fail "4.2 Failed to lock WARP client"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-lock-warp

SUCCESS=$(echo "${RESPONSE}" | jq -r '.success')
if [ "${SUCCESS}" = "true" ]; then
  pass "4.2 WARP client locked successfully"
  increment_applied
else
  fail "4.2 Failed to lock WARP"
  echo "${RESPONSE}" | jq '.errors'
  increment_failed
fi

summary
