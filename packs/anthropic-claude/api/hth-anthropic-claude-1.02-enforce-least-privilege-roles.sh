#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: anthropic-claude-1.2
#   guide:   https://howtoharden.com/guides/anthropic-claude/#12-enforce-least-privilege-organization-roles
#   profile: L1
#   mode:    mutating
#   requires: ANTHROPIC_ADMIN_KEY(Console Admin API key; no selectable scopes), USER_ID+TARGET_ROLE(optional; arm the write)
# =============================================================================
# HTH Anthropic Claude Control 1.2: Enforce Least-Privilege Organization Roles
# Profile: L1 | NIST: AC-6, AC-6(1) | SOC 2: CC6.1, CC6.3
#
# WHY `mode: mutating` DESPITE A READ-ONLY DEFAULT. With no arguments this is a
# role audit (GET only). The api-downgrade-role region below changes a member's
# role (POST /v1/organizations/users/{id}) when BOTH USER_ID and TARGET_ROLE are
# set. The sync keeps one api/ pack per section, so the write cannot move to a
# separate file; declaring `read-only` on a file that can change roles would be
# false. Run with USER_ID and TARGET_ROLE unset for evidence collection.
# Exit codes: 0 audit (or write) completed | 1 missing key, bad input, or failed API call
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
  summary; exit 1
}

TOTAL=$(echo "${MEMBERS}" | jq 'length')
info "Role distribution (all roles present, no value dropped):"
echo "${MEMBERS}" | jq -r 'group_by(.role) | map("  \(.[0].role)=\(length)") | .[]'

# Any role outside the documented enum is worth eyes-on (API drift or new tier).
# Exact match via IN(): `inside` does substring matching on strings.
echo "${MEMBERS}" | jq -r '.[] | select(.role | IN("user","claude_code_user","developer","billing","admin","managed","membership_admin","owner","primary_owner") | not) | "  UNDOCUMENTED ROLE: \(.role) — \(.email)"'

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
# WRITE: change one member's role. Runs only when BOTH USER_ID and TARGET_ROLE
# are set. The API accepts user, developer, billing, claude_code_user (Console
# and API orgs) or user, managed (Claude Enterprise orgs); admin cannot be
# assigned through the API.
if [[ -n "${USER_ID:-}" && -n "${TARGET_ROLE:-}" ]]; then
  [[ "${USER_ID}" =~ ^[A-Za-z0-9_-]+$ ]] || { fail "1.2 USER_ID is not a valid user id"; summary; exit 1; }
  case "${TARGET_ROLE}" in
    user|developer|billing|claude_code_user|managed) ;;
    *) fail "1.2 TARGET_ROLE '${TARGET_ROLE}' is not an API-assignable role"; summary; exit 1 ;;
  esac
  info "Updating user ${USER_ID} to role '${TARGET_ROLE}'..."
  # The response is the updated user object (name, email); keep it off stdout.
  anthropic_post "/v1/organizations/users/${USER_ID}" \
    "$(jq -cn --arg role "${TARGET_ROLE}" '{role: $role}')" >/dev/null || {
    fail "1.2 Failed to update user role"
    summary; exit 1
  }
  pass "1.2 User ${USER_ID} updated to role '${TARGET_ROLE}'"
fi
# HTH Guide Excerpt: end api-downgrade-role

summary
