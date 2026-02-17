#!/usr/bin/env bash
# HTH Cloudflare Control 3.4: Enable Browser Isolation
# Profile: L3 | NIST: SI-3 | CIS: 10.5
# https://howtoharden.com/guides/cloudflare/#34-enable-browser-isolation-l3
source "$(dirname "$0")/common.sh"

banner "3.4: Enable Browser Isolation"
should_apply 3 || { increment_skipped; summary; exit 0; }
info "3.4 Checking Browser Isolation policies..."

# HTH Guide Excerpt: begin api-create-isolation-policy
# Create Gateway HTTP policy with isolate action for risky sites
EXISTING=$(cf_get "/accounts/${CF_ACCOUNT_ID}/gateway/rules") || {
  fail "3.4 Unable to retrieve Gateway rules"
  increment_failed
  summary
  exit 0
}

ISOLATE_RULES=$(echo "${EXISTING}" | jq '[.result[] | select(.action == "isolate")] | length')

if [ "${ISOLATE_RULES}" -gt 0 ]; then
  pass "3.4 Found ${ISOLATE_RULES} browser isolation rule(s) already configured"
  increment_applied
  summary
  exit 0
fi

info "3.4 Creating browser isolation policy for risky sites..."
RESPONSE=$(cf_post "/accounts/${CF_ACCOUNT_ID}/gateway/rules" '{
  "name": "HTH: Isolate Risky Websites",
  "action": "isolate",
  "filters": ["http"],
  "traffic": "any(http.request.uri.content_category[*] in {68 155})",
  "enabled": true,
  "precedence": 5,
  "rule_settings": {
    "biso_admin_controls": {
      "dcp": true,
      "dd": true,
      "du": true,
      "dp": true,
      "dk": false
    }
  }
}') || {
  fail "3.4 Failed to create browser isolation rule"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-create-isolation-policy

SUCCESS=$(echo "${RESPONSE}" | jq -r '.success')
if [ "${SUCCESS}" = "true" ]; then
  pass "3.4 Browser isolation policy created"
  increment_applied
else
  fail "3.4 Isolation rule creation failed (requires Browser Isolation license)"
  echo "${RESPONSE}" | jq '.errors'
  increment_failed
fi

summary
