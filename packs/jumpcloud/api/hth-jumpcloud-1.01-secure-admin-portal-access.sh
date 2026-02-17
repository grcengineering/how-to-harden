#!/usr/bin/env bash
# HTH JumpCloud Control 1.1: Secure Admin Portal Access
# Profile: L1 | NIST: AC-6(1) | CIS: 5.4
# https://howtoharden.com/guides/jumpcloud/#11-secure-admin-portal-access
source "$(dirname "$0")/common.sh"

banner "1.1: Secure Admin Portal Access"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.1 Enforcing admin MFA requirement..."

# HTH Guide Excerpt: begin api-enforce-admin-mfa
# Require MFA for all admin portal logins
ORG_ID=$(jc_get_v1 "/organizations" | jq -r '.[0].id // empty')
if [ -z "${ORG_ID}" ]; then
  fail "1.1 Unable to determine organization ID"
  increment_failed; summary; exit 0
fi

CURRENT=$(jc_get_v1 "/organizations/${ORG_ID}" | jq -r '.settings.requireAdminMFA')
info "1.1 Current admin MFA requirement: ${CURRENT}"

if [ "${CURRENT}" = "true" ]; then
  pass "1.1 Admin MFA already required"
  increment_applied
else
  info "1.1 Enabling admin MFA requirement..."
  RESPONSE=$(jc_put_v1 "/organizations/${ORG_ID}" '{
    "settings": {
      "requireAdminMFA": true
    }
  }') || {
    fail "1.1 Failed to enable admin MFA"
    increment_failed; summary; exit 0
  }
  RESULT=$(echo "${RESPONSE}" | jq -r '.settings.requireAdminMFA')
  [ "${RESULT}" = "true" ] && { pass "1.1 Admin MFA requirement enabled"; increment_applied; } || { fail "1.1 Admin MFA not confirmed"; increment_failed; }
fi
# HTH Guide Excerpt: end api-enforce-admin-mfa

summary
