#!/usr/bin/env bash
# HTH LaunchDarkly Control 3.1: Environment Segmentation
# Profile: L1 | NIST: CM-3
# https://howtoharden.com/guides/launchdarkly/#31-environment-segmentation
source "$(dirname "$0")/common.sh"

banner "3.1: Environment Segmentation"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "3.1 Hardening production environment settings..."

# HTH Guide Excerpt: begin api-harden-environment
# Enable require-comments, confirm-changes, and mark as critical
CURRENT=$(ld_get "/projects/${LD_PROJECT_KEY}/environments/production") || {
  fail "3.1 Unable to retrieve production environment"
  increment_failed; summary; exit 0
}

REQUIRE_COMMENTS=$(echo "${CURRENT}" | jq -r '.requireComments')
CONFIRM_CHANGES=$(echo "${CURRENT}" | jq -r '.confirmChanges')
IS_CRITICAL=$(echo "${CURRENT}" | jq -r '.critical')

INSTRUCTIONS="[]"

if [ "${REQUIRE_COMMENTS}" != "true" ]; then
  INSTRUCTIONS=$(echo "${INSTRUCTIONS}" | jq '. + [{"kind": "updateRequireComments", "value": true}]')
fi
if [ "${CONFIRM_CHANGES}" != "true" ]; then
  INSTRUCTIONS=$(echo "${INSTRUCTIONS}" | jq '. + [{"kind": "updateConfirmChanges", "value": true}]')
fi
if [ "${IS_CRITICAL}" != "true" ]; then
  INSTRUCTIONS=$(echo "${INSTRUCTIONS}" | jq '. + [{"kind": "updateCritical", "value": true}]')
fi

if [ "$(echo "${INSTRUCTIONS}" | jq 'length')" -gt 0 ]; then
  info "3.1 Applying environment hardening..."
  PAYLOAD=$(jq -n --argjson inst "${INSTRUCTIONS}" '{
    "comment": "HTH: Harden production environment controls",
    "instructions": $inst
  }')
  ld_semantic_patch "/projects/${LD_PROJECT_KEY}/environments/production" "${PAYLOAD}" || {
    fail "3.1 Failed to update production environment"
    increment_failed; summary; exit 0
  }
  pass "3.1 Production environment hardened"
  increment_applied
else
  pass "3.1 Production environment already hardened"
  increment_applied
fi
# HTH Guide Excerpt: end api-harden-environment

summary
