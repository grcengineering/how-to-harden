#!/usr/bin/env bash
# HTH Cloudflare Control 4.1: Configure WARP Client Settings
# Profile: L1 | NIST: CM-7, SC-7 | CIS: 4.1
# https://howtoharden.com/guides/cloudflare/#41-configure-warp-client-settings
source "$(dirname "$0")/common.sh"

banner "4.1: Configure WARP Client Settings"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "4.1 Checking WARP client device settings..."

# HTH Guide Excerpt: begin api-configure-warp
# Configure default WARP device settings
CURRENT=$(cf_get "/accounts/${CF_ACCOUNT_ID}/devices/policy") || {
  fail "4.1 Unable to retrieve device policy"
  increment_failed
  summary
  exit 0
}

info "4.1 Current device policy settings:"
echo "${CURRENT}" | jq '.result | {
  auto_connect: .auto_connect,
  captive_portal: .captive_portal,
  allow_mode_switch: .allow_mode_switch,
  switch_locked: .switch_locked,
  tunnel_protocol: .tunnel_protocol
}'

# Apply hardened settings
RESPONSE=$(cf_patch "/accounts/${CF_ACCOUNT_ID}/devices/policy" '{
  "auto_connect": 0,
  "captive_portal": 180,
  "allow_mode_switch": false,
  "tunnel_protocol": "wireguard"
}') || {
  fail "4.1 Failed to update device policy"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-configure-warp

SUCCESS=$(echo "${RESPONSE}" | jq -r '.success')
if [ "${SUCCESS}" = "true" ]; then
  pass "4.1 WARP client settings updated"
  increment_applied
else
  fail "4.1 Failed to update WARP settings"
  echo "${RESPONSE}" | jq '.errors'
  increment_failed
fi

summary
