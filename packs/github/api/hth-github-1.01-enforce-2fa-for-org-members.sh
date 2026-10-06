#!/usr/bin/env bash
# HTH GitHub Control 1.01: Enforce Two-Factor Authentication for All Organization Members (audit)
# Profile: L1 | NIST: IA-2(1), IA-2(2)
# https://howtoharden.com/guides/github/#11-enforce-multi-factor-authentication-mfa-for-all-organization-members
#
# Audit only. The REST "Update an organization" endpoint accepts no parameter for
# the 2FA requirement (two_factor_requirement_enabled is a read-only response
# field), so turning the requirement on is ClickOps only.
source "$(dirname "$0")/common.sh"

banner "1.01: Enforce 2FA for Org Members"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.01 Checking two-factor authentication enforcement..."

# HTH Guide Excerpt: begin api-enforce-2fa
# Audit the organization's 2FA requirement (read-only; enable it in the UI)
ORG_DATA=$(gh_get "/orgs/${GITHUB_ORG}") || {
  fail "1.01 Unable to retrieve org settings for ${GITHUB_ORG}"
  increment_failed
  summary
  exit 0
}
TFA_ENABLED=$(echo "${ORG_DATA}" | jq -r '.two_factor_requirement_enabled // false')

# Members without 2FA (first 100; needs org owner access)
MEMBERS_NO_2FA=$(gh_get "/orgs/${GITHUB_ORG}/members?filter=2fa_disabled&per_page=100" \
  | jq 'length' 2>/dev/null || echo "-1")
# HTH Guide Excerpt: end api-enforce-2fa

if [ "${TFA_ENABLED}" != "true" ]; then
  fail "1.01 2FA is NOT required -- enable it: Organization Settings -> Authentication security"
  increment_failed
  summary
  exit 0
fi
pass "1.01 Two-factor authentication is required for the organization"

if [ "${MEMBERS_NO_2FA}" = "0" ]; then
  pass "1.01 All members have 2FA enabled"
elif [ "${MEMBERS_NO_2FA}" = "-1" ]; then
  warn "1.01 Unable to query members without 2FA (requires organization owner access)"
else
  warn "1.01 ${MEMBERS_NO_2FA} member(s) without 2FA are blocked from organization resources until they enable it"
fi

increment_applied
summary
