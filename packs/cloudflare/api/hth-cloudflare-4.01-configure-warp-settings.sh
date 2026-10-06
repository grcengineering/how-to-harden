#!/usr/bin/env bash
# HTH Cloudflare Control 4.1: Configure WARP Client Settings
# Profile: L1 | NIST: CM-7, SC-7 | CIS: 4.1
# https://howtoharden.com/guides/cloudflare/#41-configure-warp-client-settings
#
# Checks the default device profile against the guide's Step 2 and PATCHes
# only the fields that are out of range, and only with HTH_APPLY=1.
#   auto_connect      60-900 -- seconds (the API unit), the guide's Timeout of
#                               1-15 minutes. 0 lets a switched-off client stay
#                               off indefinitely.
#   captive_portal    > 0    -- captive portal detection enabled (seconds)
#   allow_mode_switch false
# A write only ever moves a field toward the stricter side: auto_connect that is
# 0, absent, or above 900 becomes 900; captive_portal that is 0 or absent
# becomes 180; allow_mode_switch becomes false. A value already in range is
# never touched, so a stricter setting such as auto_connect 300 is left alone.
# An auto_connect below 60 seconds is reported but never raised, because
# raising it would lengthen the window a switched-off client stays off.
# The tunnel protocol is left at the account's setting: MASQUE is the default
# and the FIPS 140-3 compliant option.
source "$(dirname "$0")/common.sh"

banner "4.1: Configure WARP Client Settings"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "4.1 Checking WARP client device settings..."

# HTH Guide Excerpt: begin api-configure-warp
# Check the default device profile; fix only out-of-range fields
CURRENT=$(cf_get "/accounts/${CF_ACCOUNT_ID}/devices/policy") || {
  fail "4.1 Unable to retrieve device policy"
  increment_failed
  summary
  exit 0
}

info "4.1 Current: $(echo "${CURRENT}" | jq -r '.result
  | "auto_connect=\(.auto_connect // "unset"), captive_portal=\(.captive_portal // "unset"), allow_mode_switch=\(.allow_mode_switch)"')"

# Fields to write, each set to its hardened value only when out of range
CHANGES=$(echo "${CURRENT}" | jq -c '.result as $c | {}
  + (if ($c.auto_connect | type) != "number" or $c.auto_connect <= 0 or $c.auto_connect > 900
     then {auto_connect: 900} else {} end)
  + (if ($c.captive_portal | type) != "number" or $c.captive_portal <= 0
     then {captive_portal: 180} else {} end)
  + (if $c.allow_mode_switch != false then {allow_mode_switch: false} else {} end)')
# Below the guide's 1-minute floor: out of range, but on the stricter side
TOO_SHORT=$(echo "${CURRENT}" | jq -r '.result.auto_connect as $a
  | if ($a | type) == "number" and $a > 0 and $a < 60 then "true" else "false" end')

if [ "${CHANGES}" = "{}" ] && [ "${TOO_SHORT}" = "false" ]; then
  pass "4.1 Default device profile is within the hardened settings"
  increment_applied
  summary
  exit 0
fi

if [ "${TOO_SHORT}" = "true" ]; then
  warn "4.1 auto_connect is below 60 seconds -- users may not finish captive-portal logins; set a Timeout of 1-15 minutes in the dashboard (not raised here: that would lengthen the off window)"
fi
if [ "${CHANGES}" = "{}" ]; then
  fail "4.1 auto_connect is outside the guide's 1-15 minute range"
  increment_failed
  summary
  exit 0
fi

info "4.1 Fields outside the hardened settings:"
echo "${CHANGES}" | jq -r 'to_entries[] | "  - \(.key) -> \(.value)"'

may_write "update the default device profile" || {
  fail "4.1 Default device profile is not hardened"
  increment_failed
  summary
  exit 0
}

RESPONSE=$(cf_patch "/accounts/${CF_ACCOUNT_ID}/devices/policy" "${CHANGES}") || {
  fail "4.1 Failed to update device policy"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-configure-warp

SUCCESS=$(echo "${RESPONSE}" | jq -r '.success')
if [ "${SUCCESS}" != "true" ]; then
  fail "4.1 Failed to update WARP settings"
  echo "${RESPONSE}" | jq '.errors'
  increment_failed
elif [ "${TOO_SHORT}" = "true" ]; then
  fail "4.1 Out-of-range fields updated, but auto_connect is still below the 1-minute floor"
  increment_failed
else
  pass "4.1 WARP client settings updated"
  increment_applied
fi

summary
