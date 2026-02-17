#!/usr/bin/env bash
# HTH LaunchDarkly Control 1.1: Enforce SSO with MFA
# Profile: L1 | NIST: IA-2(1)
# https://howtoharden.com/guides/launchdarkly/#11-enforce-sso-with-mfa
source "$(dirname "$0")/common.sh"

banner "1.1: Enforce SSO with MFA"
should_apply 1 || { increment_skipped; summary; exit 0; }

# SSO/SAML and MFA enforcement are GUI-only in LaunchDarkly.
# This script validates that all members have MFA enabled.
info "1.1 SSO/SAML configuration is GUI-only (Account Settings > Security > SAML)"
info "1.1 MFA enforcement is GUI-only (Account Settings > Security > Require MFA)"
info "1.1 Auditing member MFA status via API..."

# HTH Guide Excerpt: begin api-audit-mfa-status
# Audit all members for MFA enrollment
MEMBERS=$(ld_get "/members?limit=100") || {
  fail "1.1 Unable to retrieve member list"
  increment_failed; summary; exit 0
}

TOTAL=$(echo "${MEMBERS}" | jq '.totalCount')
NO_MFA=$(echo "${MEMBERS}" | jq '[.items[] | select(.mfa == false)] | length')
info "1.1 Total members: ${TOTAL}, without MFA: ${NO_MFA}"

if [ "${NO_MFA}" -gt 0 ]; then
  warn "1.1 Members without MFA:"
  echo "${MEMBERS}" | jq -r '.items[] | select(.mfa == false) | "  - \(.email) (role: \(.role))"'
  fail "1.1 ${NO_MFA} member(s) do not have MFA enabled"
  increment_failed
else
  pass "1.1 All members have MFA enabled"
  increment_applied
fi
# HTH Guide Excerpt: end api-audit-mfa-status

summary
