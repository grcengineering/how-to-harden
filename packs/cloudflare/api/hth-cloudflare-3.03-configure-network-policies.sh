#!/usr/bin/env bash
# HTH Cloudflare Control 3.3: Configure Network Policies
# Profile: L2 | NIST: SC-7, AC-4 | CIS: 4.4, 13.4
# https://howtoharden.com/guides/cloudflare/#33-configure-network-policies
source "$(dirname "$0")/common.sh"

banner "3.3: Configure Network Policies"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "3.3 Checking Gateway network (L4) policies..."

# HTH Guide Excerpt: begin api-create-network-policy
# Create Gateway network policy to block risky protocols
EXISTING=$(cf_get "/accounts/${CF_ACCOUNT_ID}/gateway/rules") || {
  fail "3.3 Unable to retrieve Gateway rules"
  increment_failed
  summary
  exit 0
}

L4_RULES=$(echo "${EXISTING}" | jq '[.result[] | select(.filters == ["l4"])] | length')

if [ "${L4_RULES}" -gt 0 ]; then
  pass "3.3 Found ${L4_RULES} network (L4) rule(s) already configured"
  increment_applied
  summary
  exit 0
fi

info "3.3 Creating network policy to block external SSH..."
RESPONSE=$(cf_post "/accounts/${CF_ACCOUNT_ID}/gateway/rules" '{
  "name": "HTH: Block External SSH",
  "action": "block",
  "filters": ["l4"],
  "traffic": "net.dst.port == 22 and net.dst.ip !in {10.0.0.0/8 172.16.0.0/12 192.168.0.0/16}",
  "enabled": true,
  "precedence": 10
}') || {
  fail "3.3 Failed to create network blocking rule"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-create-network-policy

SUCCESS=$(echo "${RESPONSE}" | jq -r '.success')
if [ "${SUCCESS}" = "true" ]; then
  pass "3.3 Network policy (block external SSH) created"
  increment_applied
else
  fail "3.3 Network rule creation failed"
  echo "${RESPONSE}" | jq '.errors'
  increment_failed
fi

summary
