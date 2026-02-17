#!/usr/bin/env bash
# HTH Qualys Control 1.3: Implement Role-Based Access Control
# Profile: L1 | NIST: AC-6
# https://howtoharden.com/guides/qualys/#13-implement-role-based-access-control
source "$(dirname "$0")/common.sh"

banner "1.3: Implement Role-Based Access Control"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.3 Auditing user roles for excessive privileges..."

# HTH Guide Excerpt: begin api-audit-user-roles
# Fetch all users and audit role assignments
# Qualys v2 user list returns XML with USER_LIST/USER elements
USER_XML=$(ql_get "/auth/user/?action=list" 2>/dev/null) || {
  fail "1.3 Failed to retrieve user list (requires Manager role)"
  increment_failed
  summary
  exit 1
}

# Count users by role type
TOTAL_USERS=$(echo "${USER_XML}" | xml_count "USER")
MANAGER_COUNT=$(echo "${USER_XML}" | grep -c "<USER_ROLE>Manager</USER_ROLE>" || echo "0")
ADMIN_COUNT=$(echo "${USER_XML}" | grep -c "<USER_ROLE>Unit Manager</USER_ROLE>" || echo "0")
READER_COUNT=$(echo "${USER_XML}" | grep -c "<USER_ROLE>Reader</USER_ROLE>" || echo "0")
SCANNER_COUNT=$(echo "${USER_XML}" | grep -c "<USER_ROLE>Scanner</USER_ROLE>" || echo "0")

info "1.3 Total users: ${TOTAL_USERS}"
info "1.3 Managers: ${MANAGER_COUNT} | Unit Managers: ${ADMIN_COUNT}"
info "1.3 Scanners: ${SCANNER_COUNT} | Readers: ${READER_COUNT}"

# Flag if more than 3 Manager-level accounts exist
if [ "${MANAGER_COUNT}" -gt 3 ]; then
  warn "1.3 ${MANAGER_COUNT} Manager accounts detected -- review for least-privilege"
  warn "1.3 Best practice: limit Manager role to 2-3 accounts maximum"
fi
# HTH Guide Excerpt: end api-audit-user-roles

# HTH Guide Excerpt: begin api-list-admin-users
# List all users with Manager or Unit Manager roles for review
info "1.3 Privileged users requiring review:"
echo "${USER_XML}" | grep -B5 -A5 "<USER_ROLE>Manager</USER_ROLE>" \
  | grep -oP "<USER_LOGIN>\K[^<]+" | while read -r login; do
    warn "1.3   Manager: ${login}"
  done
echo "${USER_XML}" | grep -B5 -A5 "<USER_ROLE>Unit Manager</USER_ROLE>" \
  | grep -oP "<USER_LOGIN>\K[^<]+" | while read -r login; do
    warn "1.3   Unit Manager: ${login}"
  done
# HTH Guide Excerpt: end api-list-admin-users

# Evaluate result
if [ "${MANAGER_COUNT}" -le 3 ]; then
  pass "1.3 Manager account count (${MANAGER_COUNT}) within acceptable threshold"
  increment_applied
else
  fail "1.3 Excessive Manager accounts (${MANAGER_COUNT}) -- reduce to 3 or fewer"
  increment_failed
fi

summary
