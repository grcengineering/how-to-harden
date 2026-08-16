#!/usr/bin/env bash
# HTH Anthropic Claude Control 1.2: Enforce Least-Privilege Organization Roles
# Profile: L1 | NIST: AC-6, AC-6(1) | SOC 2: CC6.1, CC6.3
# https://howtoharden.com/guides/anthropic-claude/#12-enforce-least-privilege-organization-roles
source "$(dirname "$0")/common.sh"

banner "1.2: Enforce Least-Privilege Organization Roles"
require_admin_key

# HTH Guide Excerpt: begin api-audit-roles
# Audit organization member roles across the FULL documented enum. The Admin
# API can return: user, claude_code_user, developer, billing, admin, managed,
# membership_admin, owner, primary_owner — a distribution that only counts the
# classic four silently miscounts real organizations. The elevated tier to
# limit is admin PLUS owner/primary_owner (owners hold all admin permissions
# and additionally manage admins).
info "Auditing organization member roles..."
MEMBERS=$(anthropic_list_all "/v1/organizations/users") || {
  fail "1.2 Failed to list organization users"
  summary; exit 0
}

TOTAL=$(echo "${MEMBERS}" | jq 'length')
info "Role distribution (all roles present, no value dropped):"
echo "${MEMBERS}" | jq -r 'group_by(.role) | map("  \(.[0].role)=\(length)") | .[]'

# Any role outside the documented enum is worth eyes-on (API drift or new tier)
echo "${MEMBERS}" | jq -r '.[] | select([.role] | inside(["user","claude_code_user","developer","billing","admin","managed","membership_admin","owner","primary_owner"]) | not) | "  UNDOCUMENTED ROLE: \(.role) — \(.email)"'

# Flag excessive ELEVATED-tier count: admin + owner + primary_owner
ELEVATED_COUNT=$(echo "${MEMBERS}" | jq '[.[] | select(.role == "admin" or .role == "owner" or .role == "primary_owner")] | length')
if [[ "${ELEVATED_COUNT}" -gt 3 ]]; then
  warn "1.2 ${ELEVATED_COUNT} members hold admin/owner/primary_owner — review for least privilege"
  echo "Elevated members:"
  echo "${MEMBERS}" | jq -r '.[] | select(.role == "admin" or .role == "owner" or .role == "primary_owner") | "  \(.role): \(.name) <\(.email)>"'
else
  pass "1.2 Elevated-tier count (${ELEVATED_COUNT}) is within recommended limit (<=3), total members: ${TOTAL}"
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
