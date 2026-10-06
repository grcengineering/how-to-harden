#!/usr/bin/env bash
# HTH Cloudflare Control 4.2: Lock WARP Client
# Profile: L2 | NIST: CM-7 | CIS: 4.1
# https://howtoharden.com/guides/cloudflare/#42-lock-warp-client
#
# Reads the default device profile; locks the client switch only with
# HTH_APPLY=1.
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

# Compare explicitly: jq's `//` treats false as missing, so
# `.allowed_to_leave // true` turns a real false into true. An absent field
# counts as the unsafe value (unlocked / allowed to leave).
LOCKED=$(echo "${CURRENT}" | jq -r 'if .result.switch_locked == true then "true" else "false" end')
LEAVE=$(echo "${CURRENT}" | jq -r 'if .result.allowed_to_leave == false then "false" else "true" end')

if [ "${LOCKED}" = "true" ] && [ "${LEAVE}" = "false" ]; then
  pass "4.2 WARP client is already locked"
  increment_applied
  summary
  exit 0
fi

may_write "lock the WARP client in the default device profile" || {
  fail "4.2 WARP client is not locked (switch_locked=${LOCKED}, allowed_to_leave=${LEAVE})"
  increment_failed
  summary
  exit 0
}

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
