#!/usr/bin/env bash
# HTH Cloudflare Control 3.1: Configure DNS Filtering
# Profile: L1 | NIST: SC-7, SI-3 | CIS: 9.2
# https://howtoharden.com/guides/cloudflare/#31-configure-dns-filtering
source "$(dirname "$0")/common.sh"

banner "3.1: Configure DNS Filtering"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "3.1 Checking Gateway DNS policies..."

# HTH Guide Excerpt: begin api-create-dns-policy
# Create Gateway DNS policy to block security threats
EXISTING=$(cf_get "/accounts/${CF_ACCOUNT_ID}/gateway/rules") || {
  fail "3.1 Unable to retrieve Gateway rules"
  increment_failed
  summary
  exit 0
}

DNS_BLOCK_RULES=$(echo "${EXISTING}" | jq '[.result[] | select(.filters == ["dns"] and .action == "block")] | length')

if [ "${DNS_BLOCK_RULES}" -gt 0 ]; then
  pass "3.1 Found ${DNS_BLOCK_RULES} DNS blocking rule(s) already configured"
  echo "${EXISTING}" | jq -r '.result[] | select(.filters == ["dns"] and .action == "block") | "  - \(.name)"'
  increment_applied
  summary
  exit 0
fi

info "3.1 Creating DNS security threat blocking rule..."
RESPONSE=$(cf_post "/accounts/${CF_ACCOUNT_ID}/gateway/rules" '{
  "name": "HTH: Block Security Threats (DNS)",
  "action": "block",
  "filters": ["dns"],
  "traffic": "any(dns.security_category[*] in {80 83 176 178})",
  "enabled": true,
  "precedence": 10,
  "rule_settings": {
    "block_page_enabled": true,
    "block_reason": "Blocked: malware, phishing, spyware, or C2 domain"
  }
}') || {
  fail "3.1 Failed to create DNS blocking rule"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-create-dns-policy

SUCCESS=$(echo "${RESPONSE}" | jq -r '.success')
if [ "${SUCCESS}" = "true" ]; then
  pass "3.1 DNS security threat blocking rule created"
  increment_applied
else
  fail "3.1 DNS rule creation failed"
  echo "${RESPONSE}" | jq '.errors'
  increment_failed
fi

summary
