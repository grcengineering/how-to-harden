#!/usr/bin/env bash
# HTH Cloudflare Control 1.4: Configure Admin Role Restrictions
# Profile: L1 | NIST: AC-6(1) | CIS: 5.4
# https://howtoharden.com/guides/cloudflare/#14-configure-admin-role-restrictions
#
# Read-only audit. Reads every page of account members, counts members holding
# the "Super Administrator - All Privileges" role, and prints a member count
# per role. Member email addresses are never printed.
source "$(dirname "$0")/common.sh"

banner "1.4: Configure Admin Role Restrictions"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.4 Auditing account member roles..."

# HTH Guide Excerpt: begin api-audit-roles
# Collect every page of account members
ALL_MEMBERS='[]'
PAGE=1
TOTAL_PAGES=1
while [ "${PAGE}" -le "${TOTAL_PAGES}" ]; do
  RESP=$(cf_get "/accounts/${CF_ACCOUNT_ID}/members?page=${PAGE}&per_page=50") || {
    fail "1.4 Unable to retrieve account members (page ${PAGE})"
    increment_failed
    summary
    exit 0
  }
  ALL_MEMBERS=$(jq -n --argjson acc "${ALL_MEMBERS}" --argjson page "${RESP}" '$acc + $page.result')
  # result_info carries total_count and per_page; derive the page count from them
  TOTAL_PAGES=$(echo "${RESP}" | jq '.result_info as $i
    | ($i.total_pages // (if (($i.total_count // 0) == 0) then 1
        else ((($i.total_count + ($i.per_page // 50) - 1) / ($i.per_page // 50)) | floor) end))')
  PAGE=$((PAGE + 1))
done

MEMBER_COUNT=$(echo "${ALL_MEMBERS}" | jq 'length')
info "1.4 Found ${MEMBER_COUNT} account member(s)"

# The role is named "Super Administrator - All Privileges"
SUPER_ADMINS=$(echo "${ALL_MEMBERS}" | jq '[.[] | select(any(.roles[]?; .name | startswith("Super Administrator")))] | length')
if [ "${SUPER_ADMINS}" -gt 3 ]; then
  fail "1.4 ${SUPER_ADMINS} Super Administrators found (recommend max 2-3)"
elif [ "${SUPER_ADMINS}" -eq 0 ]; then
  fail "1.4 No member reported the Super Administrator role -- check the token can read member roles"
else
  pass "1.4 ${SUPER_ADMINS} Super Administrator(s) found (within recommended limit)"
fi

# Member count per role (no email addresses)
echo "${ALL_MEMBERS}" | jq -r '[.[].roles[]?.name] | group_by(.) | .[] | "  - \(.[0]): \(length) member(s)"'
# HTH Guide Excerpt: end api-audit-roles

if [ "${SUPER_ADMINS}" -gt 3 ] || [ "${SUPER_ADMINS}" -eq 0 ]; then
  increment_failed
else
  increment_applied
fi

summary
