#!/usr/bin/env bash
# HTH Cloudflare Control 1.6: Enforce Two-Factor Authentication for Account Members
# Profile: L1 | NIST: IA-2(1) | CIS: 6.5
# https://howtoharden.com/guides/cloudflare/#16-enforce-two-factor-authentication-for-account-members
#
# Read-only audit. Passes only when the account setting enforce_twofactor is
# true. Also counts members whose user record shows 2FA not enabled (no email
# addresses are printed). This pack never turns enforcement on: enforcement
# blocks every member without 2FA, so it is a deliberate console change.
source "$(dirname "$0")/common.sh"

banner "1.6: Enforce Two-Factor Authentication for Account Members"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.6 Checking account 2FA enforcement..."

# HTH Guide Excerpt: begin api-audit-2fa
# Read the account setting that makes 2FA a condition of membership
ACCOUNT=$(cf_get "/accounts/${CF_ACCOUNT_ID}") || {
  fail "1.6 Unable to retrieve account settings"
  increment_failed
  summary
  exit 0
}
ENFORCED=$(echo "${ACCOUNT}" | jq -r '.result.settings.enforce_twofactor // false')

MEMBERS=$(cf_get_all "/accounts/${CF_ACCOUNT_ID}/members") || {
  fail "1.6 Unable to retrieve account members"
  increment_failed
  summary
  exit 0
}
NO_2FA=$(echo "${MEMBERS}" | jq '[.result[] | select(.user.two_factor_authentication_enabled == false)] | length')
# HTH Guide Excerpt: end api-audit-2fa

info "1.6 Members without 2FA (all pages): ${NO_2FA}"
if [ "${ENFORCED}" = "true" ]; then
  pass "1.6 Account-level 2FA enforcement is on"
  increment_applied
else
  fail "1.6 Account-level 2FA enforcement is off"
  increment_failed
fi

summary
