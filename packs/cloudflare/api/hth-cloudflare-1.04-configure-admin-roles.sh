#!/usr/bin/env bash
# HTH Cloudflare Control 1.4: Configure Admin Role Restrictions
# Profile: L1 | NIST: AC-6(1) | CIS: 5.4
# https://howtoharden.com/guides/cloudflare/#14-configure-admin-role-restrictions
source "$(dirname "$0")/common.sh"

banner "1.4: Configure Admin Role Restrictions"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.4 Auditing account member roles..."

# HTH Guide Excerpt: begin api-audit-roles
# List all account members and their roles
MEMBERS=$(cf_get "/accounts/${CF_ACCOUNT_ID}/members?per_page=50") || {
  fail "1.4 Unable to retrieve account members"
  increment_failed
  summary
  exit 0
}

MEMBER_COUNT=$(echo "${MEMBERS}" | jq '.result | length')
info "1.4 Found ${MEMBER_COUNT} account member(s)"

# Check for Super Administrator count
SUPER_ADMINS=$(echo "${MEMBERS}" | jq '[.result[] | select(.roles[]?.name == "Super Administrator")] | length')
if [ "${SUPER_ADMINS}" -gt 3 ]; then
  warn "1.4 ${SUPER_ADMINS} Super Administrators found (recommend max 2-3)"
else
  pass "1.4 ${SUPER_ADMINS} Super Administrator(s) found (within recommended limit)"
fi

# List all members with their roles
echo "${MEMBERS}" | jq -r '.result[] | "  - \(.user.email): \([.roles[].name] | join(", "))"'
# HTH Guide Excerpt: end api-audit-roles

increment_applied

summary
