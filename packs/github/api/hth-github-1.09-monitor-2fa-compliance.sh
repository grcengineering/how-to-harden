#!/usr/bin/env bash
# HTH GitHub Control 1.09: Monitor 2FA Compliance
# Profile: L1 | NIST: IA-2(1), IA-2(2)
# https://howtoharden.com/guides/github/#11-enforce-multi-factor-authentication-mfa-for-all-organization-members
source "$(dirname "$0")/common.sh"

banner "1.09: Monitor 2FA Compliance"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.09 Monitoring 2FA compliance for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-monitor-2fa-compliance
# Daily check for non-compliant members (expected: 0; if > 0, alert security team)
NON_COMPLIANT=$(gh api --paginate "/orgs/${GITHUB_ORG}/members?filter=2fa_disabled&per_page=100" \
  --jq '.[].login' | wc -l | tr -d ' ')
echo "Members without 2FA: ${NON_COMPLIANT}"
# HTH Guide Excerpt: end api-monitor-2fa-compliance

if [ "${NON_COMPLIANT}" -eq 0 ]; then
  pass "1.09 No members without 2FA"
  increment_applied
else
  fail "1.09 ${NON_COMPLIANT} member(s) without 2FA"
  increment_failed
fi
summary
