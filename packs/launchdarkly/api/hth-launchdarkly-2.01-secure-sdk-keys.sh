#!/usr/bin/env bash
# HTH LaunchDarkly Control 2.1: Secure SDK Keys
# Profile: L1 | NIST: IA-5
# https://howtoharden.com/guides/launchdarkly/#21-secure-sdk-keys
source "$(dirname "$0")/common.sh"

banner "2.1: Secure SDK Keys"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "2.1 Auditing SDK key exposure and environment secure mode..."

# HTH Guide Excerpt: begin api-audit-sdk-keys
# Check secure mode on all environments
ENVIRONMENTS=$(ld_get "/projects/${LD_PROJECT_KEY}/environments") || {
  fail "2.1 Unable to retrieve environments"
  increment_failed; summary; exit 0
}

ENVS_WITHOUT_SECURE=$(echo "${ENVIRONMENTS}" | jq '[.items[] | select(.secureMode == false)] | length')
TOTAL_ENVS=$(echo "${ENVIRONMENTS}" | jq '.items | length')
info "2.1 Total environments: ${TOTAL_ENVS}"

if [ "${ENVS_WITHOUT_SECURE}" -gt 0 ]; then
  warn "2.1 Environments without secure mode:"
  echo "${ENVIRONMENTS}" | jq -r '.items[] | select(.secureMode == false) | "  - \(.key)"'
fi

# Enable secure mode on production environment
PROD_SECURE=$(echo "${ENVIRONMENTS}" | jq -r '.items[] | select(.key == "production") | .secureMode')
if [ "${PROD_SECURE}" = "true" ]; then
  pass "2.1 Production environment has secure mode enabled"
  increment_applied
else
  info "2.1 Enabling secure mode on production..."
  ld_semantic_patch "/projects/${LD_PROJECT_KEY}/environments/production" '{
    "comment": "HTH: Enable secure mode to prevent client-side SDK user impersonation",
    "instructions": [
      {"kind": "updateSecureMode", "value": true}
    ]
  }' || {
    fail "2.1 Failed to enable secure mode on production"
    increment_failed; summary; exit 0
  }
  pass "2.1 Secure mode enabled on production"
  increment_applied
fi
# HTH Guide Excerpt: end api-audit-sdk-keys

summary
