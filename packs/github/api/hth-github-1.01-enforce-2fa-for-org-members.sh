#!/usr/bin/env bash
# HTH GitHub Control 1.01: Enforce Two-Factor Authentication for All Organization Members
# Profile: L1 | NIST: IA-2(1), IA-2(2)
# https://howtoharden.com/guides/github/#11-enforce-two-factor-authentication
source "$(dirname "$0")/common.sh"

banner "1.01: Enforce 2FA for Org Members"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.01 Checking two-factor authentication enforcement..."

# Idempotency check -- verify org already requires 2FA
ORG_DATA=$(gh_get "/orgs/${GITHUB_ORG}") || {
  fail "1.01 Unable to retrieve org settings for ${GITHUB_ORG}"
  increment_failed
  summary
  exit 0
}

TFA_ENABLED=$(echo "${ORG_DATA}" | jq -r '.two_factor_requirement_enabled // false')

if [ "${TFA_ENABLED}" = "true" ]; then
  pass "1.01 Two-factor authentication is already enforced"
  # Check for members without 2FA
  MEMBERS_NO_2FA=$(gh_get "/orgs/${GITHUB_ORG}/members?filter=2fa_disabled" \
    | jq '. | length' 2>/dev/null || echo "-1")
  if [ "${MEMBERS_NO_2FA}" = "0" ]; then
    pass "1.01 All members have 2FA enabled"
  elif [ "${MEMBERS_NO_2FA}" = "-1" ]; then
    warn "1.01 Unable to query members without 2FA (may require admin scope)"
  else
    warn "1.01 ${MEMBERS_NO_2FA} member(s) still without 2FA (will be removed on next login)"
  fi
  increment_applied
  summary
  exit 0
fi

# HTH Guide Excerpt: begin api-enforce-2fa
# Enable two-factor authentication requirement for the organization
info "1.01 Enabling 2FA requirement for org ${GITHUB_ORG}..."
RESPONSE=$(gh_patch "/orgs/${GITHUB_ORG}" '{
  "two_factor_requirement_enabled": true
}') || {
  fail "1.01 Failed to enable 2FA requirement -- may require owner permissions"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-enforce-2fa

RESULT=$(echo "${RESPONSE}" | jq -r '.two_factor_requirement_enabled // false')
if [ "${RESULT}" = "true" ]; then
  pass "1.01 Two-factor authentication enforcement enabled"
  increment_applied
else
  fail "1.01 2FA enforcement not confirmed after update"
  increment_failed
fi

summary
