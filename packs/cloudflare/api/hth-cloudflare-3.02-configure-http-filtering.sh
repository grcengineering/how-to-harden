#!/usr/bin/env bash
# HTH Cloudflare Control 3.2: Configure HTTP Filtering
# Profile: L1 | NIST: SC-7, SI-4 | CIS: 9.2, 13.3
# https://howtoharden.com/guides/cloudflare/#32-configure-http-filtering
source "$(dirname "$0")/common.sh"

banner "3.2: Configure HTTP Filtering"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "3.2 Checking Gateway HTTP policies..."

# HTH Guide Excerpt: begin api-create-http-policy
# Create Gateway HTTP policy to block malware downloads
EXISTING=$(cf_get "/accounts/${CF_ACCOUNT_ID}/gateway/rules") || {
  fail "3.2 Unable to retrieve Gateway rules"
  increment_failed
  summary
  exit 0
}

HTTP_BLOCK_RULES=$(echo "${EXISTING}" | jq '[.result[] | select(.filters == ["http"] and .action == "block")] | length')

if [ "${HTTP_BLOCK_RULES}" -gt 0 ]; then
  pass "3.2 Found ${HTTP_BLOCK_RULES} HTTP blocking rule(s) already configured"
  increment_applied
  summary
  exit 0
fi

info "3.2 Creating HTTP malware download blocking rule..."
RESPONSE=$(cf_post "/accounts/${CF_ACCOUNT_ID}/gateway/rules" '{
  "name": "HTH: Block Malware Downloads (HTTP)",
  "action": "block",
  "filters": ["http"],
  "traffic": "any(http.request.uri.content_category[*] in {80 83})",
  "enabled": true,
  "precedence": 10,
  "rule_settings": {
    "block_page_enabled": true,
    "block_reason": "Blocked: malware risk detected in download"
  }
}') || {
  fail "3.2 Failed to create HTTP blocking rule"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-create-http-policy

SUCCESS=$(echo "${RESPONSE}" | jq -r '.success')
if [ "${SUCCESS}" = "true" ]; then
  pass "3.2 HTTP malware blocking rule created"
  increment_applied
else
  fail "3.2 HTTP rule creation failed"
  echo "${RESPONSE}" | jq '.errors'
  increment_failed
fi

summary
