#!/usr/bin/env bash
# HTH Okta Control 7.3: Conduct Regular Access Reviews
# Profile: L1 | NIST: AC-2(3) | SOC 2: CC6.1, CC6.2
# https://howtoharden.com/guides/okta/#73-conduct-regular-access-reviews
#
# Read-only audit. A token owned by a Read-Only Administrator is sufficient.
# GET /api/v1/iam/assignees/users returns {"value": [{"id": ...}], "_links": ...}
# (Okta Management API, RoleAssignedUsers); each user's roles come from
# GET /api/v1/users/{userId}/roles.
source "$(dirname "$0")/common.sh"

banner "7.3: Conduct Regular Access Reviews"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "7.3 Conducting access review..."

# -----------------------------------------------------------------------
# 7.3a: Find active users who haven't logged in for 90+ days
# -----------------------------------------------------------------------
# HTH Guide Excerpt: begin api-list-active-users
info "7.3 Finding inactive users (no login in 90+ days)..."
ACTIVE_USERS=$(okta_get "/api/v1/users?filter=status+eq+%22ACTIVE%22&limit=200")  # a failed read stops the pack
TOTAL_ACTIVE=$(printf '%s' "${ACTIVE_USERS}" | jq 'length')
# HTH Guide Excerpt: end api-list-active-users

INACTIVE_COUNT=$(printf '%s' "${ACTIVE_USERS}" | jq \
  '[.[] | select(.lastLogin != null) | select((.lastLogin | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601) < (now - 7776000))] | length')

info "7.3 Total active users (first page): ${TOTAL_ACTIVE}"

if [ "${INACTIVE_COUNT}" -gt 0 ]; then
  warn "7.3 Found ${INACTIVE_COUNT} user(s) with no login in 90+ days:"
  printf '%s' "${ACTIVE_USERS}" | jq -r \
    '[.[] | select(.lastLogin != null) | select((.lastLogin | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601) < (now - 7776000))] | .[] | "  - \(.profile.login) (last login: \(.lastLogin))"'
else
  pass "7.3 No active user has gone 90+ days without a login (first ${TOTAL_ACTIVE} users read)"
fi

# -----------------------------------------------------------------------
# 7.3b: Admin role assignments and Super Admin count
# -----------------------------------------------------------------------
# HTH Guide Excerpt: begin api-check-super-admins
info "7.3 Listing users with admin role assignments..."
ADMIN_USER_IDS=$(okta_get "/api/v1/iam/assignees/users?limit=200" | jq -r '.value[].id')
ADMIN_COUNT=0
SUPER_ADMIN_COUNT=0
for USER_ID in ${ADMIN_USER_IDS}; do
  ADMIN_COUNT=$((ADMIN_COUNT + 1))
  ROLE_TYPES=$(okta_get "/api/v1/users/${USER_ID}/roles" | jq -r '[.[].type] | join(",")')
  info "7.3   Admin user ${USER_ID}: ${ROLE_TYPES}"
  case ",${ROLE_TYPES}," in
    *,SUPER_ADMIN,*) SUPER_ADMIN_COUNT=$((SUPER_ADMIN_COUNT + 1)) ;;
  esac
done

if [ "${SUPER_ADMIN_COUNT}" -ge 5 ]; then
  warn "7.3 Super Admin count: ${SUPER_ADMIN_COUNT} of ${ADMIN_COUNT} admin(s) (should be fewer than 5)"
else
  pass "7.3 Super Admin count: ${SUPER_ADMIN_COUNT} of ${ADMIN_COUNT} admin(s) (within the fewer-than-5 limit)"
fi
# HTH Guide Excerpt: end api-check-super-admins

# -----------------------------------------------------------------------
# 7.3c: Summary and recommendations
# -----------------------------------------------------------------------
echo ""
info "7.3 Access Review Summary:"
info "  Active users checked: ${TOTAL_ACTIVE} (first page)"
info "  Inactive 90+ days: ${INACTIVE_COUNT}"
info "  Users with admin roles: ${ADMIN_COUNT}"
info "  Super Admin count: ${SUPER_ADMIN_COUNT}"
echo ""
info "7.3 Quarterly Access Review Checklist:"
info "  [ ] All admin accounts verified against current employee list"
info "  [ ] Super Admin count is < 5"
info "  [ ] No orphaned accounts (users who left but were not deprovisioned)"
info "  [ ] No accounts with last login > 90 days (unless exempted)"
info "  [ ] Privileged group memberships reviewed and justified"
info "  [ ] Sensitive application assignments reviewed"
info "  [ ] Review documented with date, reviewer, and findings"

pass "7.3 Access review audit complete"
increment_applied

summary
