#!/usr/bin/env bash
# HTH Cloudflare Control 4.3: Configure Split Tunnel Settings
# Profile: L2 | NIST: SC-7 | CIS: 13.5
# https://howtoharden.com/guides/cloudflare/#43-configure-split-tunnel-settings
source "$(dirname "$0")/common.sh"

banner "4.3: Configure Split Tunnel Settings"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "4.3 Auditing split tunnel configuration..."

# HTH Guide Excerpt: begin api-audit-split-tunnel
# Audit split tunnel exclude list
EXCLUDE_LIST=$(cf_get "/accounts/${CF_ACCOUNT_ID}/devices/policy/exclude") || {
  fail "4.3 Unable to retrieve split tunnel exclude list"
  increment_failed
  summary
  exit 0
}

EXCLUDE_COUNT=$(echo "${EXCLUDE_LIST}" | jq '.result | length')
info "4.3 Found ${EXCLUDE_COUNT} split tunnel exclusion(s)"

if [ "${EXCLUDE_COUNT}" -gt 20 ]; then
  warn "4.3 ${EXCLUDE_COUNT} exclusions is excessive -- review and minimize exceptions"
else
  pass "4.3 Split tunnel exclusion count (${EXCLUDE_COUNT}) is within reasonable range"
fi

echo "${EXCLUDE_LIST}" | jq -r '.result[] | "  - \(.address // .host // "unknown"): \(.description // "no description")"'
# HTH Guide Excerpt: end api-audit-split-tunnel

info "4.3 For maximum security (L3), consider switching to Include mode"
increment_applied

summary
