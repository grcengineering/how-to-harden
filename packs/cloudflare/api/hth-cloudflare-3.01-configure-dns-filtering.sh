#!/usr/bin/env bash
# HTH Cloudflare Control 3.1: Configure DNS Filtering
# Profile: L1 | NIST: SC-7, SI-3 | CIS: 9.2
# https://howtoharden.com/guides/cloudflare/#31-configure-dns-filtering
#
# Reads Gateway rules and looks for an enabled DNS block rule covering the
# Malware (117) and Phishing (131) security categories. If none exists it
# reports the rule it would create; it creates it only with HTH_APPLY=1.
# Security category IDs: developers.cloudflare.com/cloudflare-one/traffic-policies/domain-categories/
#   80 Command and Control & Botnet   83 Cryptomining   117 Malware   131 Phishing
#   153 Spyware   175 DNS Tunneling   176 Domain Generation Algorithm   178 Brand Embedding
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

# An existing rule counts only if it is an enabled DNS block on the
# security-category selector that covers Malware (117) and Phishing (131),
# read from the non-negated part of its expression (common.sh positive_traffic)
THREAT_RULES=$(echo "${EXISTING}" | jq "${JQ_GATEWAY_DEFS}"'[.result[]
  | select(.filters == ["dns"] and .action == "block" and .enabled == true)
  | positive_traffic
  | select(test("dns\\.security_category"))
  | select(test("\\b117\\b") and test("\\b131\\b"))] | length')

if [ "${THREAT_RULES}" -gt 0 ]; then
  pass "3.1 Found ${THREAT_RULES} DNS rule(s) blocking malware and phishing categories"
  increment_applied
  summary
  exit 0
fi

may_write "create the DNS rule 'HTH: Block Security Threats (DNS)'" || {
  fail "3.1 No enabled DNS rule blocks the malware and phishing security categories"
  increment_failed
  summary
  exit 0
}

info "3.1 Creating DNS security threat blocking rule..."
RESPONSE=$(cf_post "/accounts/${CF_ACCOUNT_ID}/gateway/rules" '{
  "name": "HTH: Block Security Threats (DNS)",
  "action": "block",
  "filters": ["dns"],
  "traffic": "any(dns.security_category[*] in {80 83 117 131 153 175 176 178})",
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
