#!/usr/bin/env bash
# HTH ServiceNow Control 3.2: Limit Admin Access
# Profile: L1 | NIST: AC-6(1)
# https://howtoharden.com/guides/servicenow/#32-limit-admin-access
source "$(dirname "$0")/common.sh"

banner "3.2: Limit Admin Access"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "3.2 Auditing admin role assignments..."

# ---------------------------------------------------------------------------
# Enumerate all users with the admin role
# ---------------------------------------------------------------------------
# HTH Guide Excerpt: begin api-audit-admin-roles
info "3.2 Querying admin role assignments..."
ADMIN_ROLES=$(sn_table_get "sys_user_has_role" \
  "sysparm_query=role.name=admin^state=active&sysparm_fields=user.user_name,user.name,user.active,user.last_login_time" \
  2>/dev/null || true)

ADMIN_COUNT=$(echo "${ADMIN_ROLES}" | jq -r '.result | length' 2>/dev/null || echo "0")

info "3.2 Found ${ADMIN_COUNT} active admin role assignment(s)"

# List each admin
if [ "${ADMIN_COUNT}" -gt 0 ]; then
  echo "${ADMIN_ROLES}" | jq -r '.result[] | "  - \(.["user.user_name"] // "unknown") (\(.["user.name"] // "N/A")) — last login: \(.["user.last_login_time"] // "never")"' 2>/dev/null || true
fi
# HTH Guide Excerpt: end api-audit-admin-roles

# ---------------------------------------------------------------------------
# Flag excessive admin count
# ---------------------------------------------------------------------------
# HTH Guide Excerpt: begin api-flag-excessive-admins
MAX_ADMINS=5
if [ "${ADMIN_COUNT}" -le "${MAX_ADMINS}" ]; then
  pass "3.2 Admin count (${ADMIN_COUNT}) is within threshold (<= ${MAX_ADMINS})"
  increment_applied
else
  fail "3.2 Excessive admin count: ${ADMIN_COUNT} (threshold: ${MAX_ADMINS})"
  fail "3.2 Review admin assignments and remove unnecessary privileges"
  increment_failed
fi
# HTH Guide Excerpt: end api-flag-excessive-admins

# ---------------------------------------------------------------------------
# Check for inactive users with admin role
# ---------------------------------------------------------------------------
info "3.2 Checking for inactive users with admin role..."
INACTIVE_ADMINS=$(sn_table_get "sys_user_has_role" \
  "sysparm_query=role.name=admin^user.active=false&sysparm_fields=user.user_name,user.name" \
  2>/dev/null || true)

INACTIVE_COUNT=$(echo "${INACTIVE_ADMINS}" | jq -r '.result | length' 2>/dev/null || echo "0")

if [ "${INACTIVE_COUNT}" -eq 0 ]; then
  pass "3.2 No inactive users hold the admin role"
else
  fail "3.2 Found ${INACTIVE_COUNT} inactive user(s) with admin role — revoke immediately"
  echo "${INACTIVE_ADMINS}" | jq -r '.result[] | "  - \(.["user.user_name"] // "unknown") (\(.["user.name"] // "N/A"))"' 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Check for security_admin role separation
# ---------------------------------------------------------------------------
info "3.2 Checking security_admin role assignments..."
SEC_ADMIN_COUNT=$(sn_table_get "sys_user_has_role" \
  "sysparm_query=role.name=security_admin^state=active&sysparm_fields=user.user_name" \
  | jq -r '.result | length' 2>/dev/null || echo "0")

info "3.2 Found ${SEC_ADMIN_COUNT} security_admin role assignment(s)"

summary
