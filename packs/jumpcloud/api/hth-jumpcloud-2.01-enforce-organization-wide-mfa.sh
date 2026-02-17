#!/usr/bin/env bash
# HTH JumpCloud Control 2.1: Enforce Organization-Wide MFA
# Profile: L1 | NIST: IA-2(1) | CIS: 6.5
# https://howtoharden.com/guides/jumpcloud/#21-enforce-organization-wide-mfa
source "$(dirname "$0")/common.sh"

banner "2.1: Enforce Organization-Wide MFA"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "2.1 Creating conditional access policy for user portal MFA..."

# HTH Guide Excerpt: begin api-enforce-user-mfa
# Create a conditional access policy requiring MFA for all user portal logins
EXISTING=$(jc_get_v2 "/authn/policies" | jq -r '.[] | select(.name == "HTH: Require MFA - All Users") | .id') || true

if [ -n "${EXISTING}" ]; then
  info "2.1 MFA policy already exists (id: ${EXISTING})"
  pass "2.1 User portal MFA policy configured"
  increment_applied
else
  info "2.1 Creating MFA enforcement policy..."
  RESPONSE=$(jc_post_v2 "/authn/policies" '{
    "name": "HTH: Require MFA - All Users",
    "type": "user_portal",
    "disabled": false,
    "effect": {
      "action": "allow",
      "obligations": {
        "mfa": { "required": true },
        "mfaFactors": ["TOTP", "WEBAUTHN", "PUSH"],
        "userVerification": { "requirement": "required" }
      }
    },
    "targets": {
      "resources": [{ "type": "user_portal" }]
    }
  }') || {
    fail "2.1 Failed to create MFA policy"
    increment_failed; summary; exit 0
  }
  POLICY_ID=$(echo "${RESPONSE}" | jq -r '.id')
  pass "2.1 MFA policy created (id: ${POLICY_ID})"
  increment_applied
fi

# Audit users without MFA enrolled
info "2.1 Auditing user MFA enrollment..."
USERS=$(jc_get_v1 "/systemusers?limit=100")
NO_MFA=$(echo "${USERS}" | jq '[.results[] | select(.totp_enabled == false and .enable_user_portal_multifactor == false)] | length')
TOTAL=$(echo "${USERS}" | jq '.totalCount')
info "2.1 Users without MFA: ${NO_MFA} / ${TOTAL}"

if [ "${NO_MFA}" -gt 0 ]; then
  warn "2.1 Users without MFA enrollment:"
  echo "${USERS}" | jq -r '.results[] | select(.totp_enabled == false and .enable_user_portal_multifactor == false) | "  - \(.email)"'
fi
# HTH Guide Excerpt: end api-enforce-user-mfa

summary
