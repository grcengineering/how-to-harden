#!/usr/bin/env bash
# HTH Anthropic Claude Control 1.2: Enforce Least-Privilege Organization Roles
# Profile: L1 | NIST: AC-6, AC-6(1) | SOC 2: CC6.1, CC6.3
# https://howtoharden.com/guides/anthropic-claude/#12-enforce-least-privilege-organization-roles
source "$(dirname "$0")/common.sh"

banner "1.2: Enforce Least-Privilege Organization Roles"
require_admin_key

# HTH Guide Excerpt: begin api-audit-roles
# Audit organization member roles — flag users with admin or billing roles
info "Auditing organization member roles..."
MEMBERS=$(anthropic_list_all "/v1/organizations/users") || {
  fail "1.2 Failed to list organization users"
  summary; exit 0
}

# Count by role
ADMIN_COUNT=$(echo "${MEMBERS}" | jq '[.[] | select(.role == "admin")] | length')
BILLING_COUNT=$(echo "${MEMBERS}" | jq '[.[] | select(.role == "billing")] | length')
DEVELOPER_COUNT=$(echo "${MEMBERS}" | jq '[.[] | select(.role == "developer")] | length')
USER_COUNT=$(echo "${MEMBERS}" | jq '[.[] | select(.role == "user")] | length')
TOTAL=$(echo "${MEMBERS}" | jq 'length')

info "Role distribution: admin=${ADMIN_COUNT}, billing=${BILLING_COUNT}, developer=${DEVELOPER_COUNT}, user=${USER_COUNT}, total=${TOTAL}"

# Flag excessive admin count
if [[ "${ADMIN_COUNT}" -gt 3 ]]; then
  warn "1.2 ${ADMIN_COUNT} users have admin role — review for least privilege"
  echo "Admins:"
  echo "${MEMBERS}" | jq -r '.[] | select(.role == "admin") | "  \(.name) <\(.email)>"'
else
  pass "1.2 Admin count (${ADMIN_COUNT}) is within recommended limit (<=3)"
fi
# HTH Guide Excerpt: end api-audit-roles

# HTH Guide Excerpt: begin api-downgrade-role
# Downgrade a user from a privileged role to 'user' or 'developer'
# Usage: Set USER_ID and TARGET_ROLE before running
if [[ -n "${USER_ID:-}" && -n "${TARGET_ROLE:-}" ]]; then
  info "Updating user ${USER_ID} to role '${TARGET_ROLE}'..."
  anthropic_post "/v1/organizations/users/${USER_ID}" \
    "{\"role\": \"${TARGET_ROLE}\"}" || {
    fail "1.2 Failed to update user role"
    summary; exit 0
  }
  pass "1.2 User ${USER_ID} updated to role '${TARGET_ROLE}'"
fi
# HTH Guide Excerpt: end api-downgrade-role

summary
