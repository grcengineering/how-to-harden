#!/usr/bin/env bash
# HTH Okta Code Pack -- Section 7: Operational Security
# Controls: 7.3 (API-automatable parts)
# https://howtoharden.com/guides/okta/#7-operational-security
source "$(dirname "$0")/common.sh"

banner "Section 7: Operational Security"

# ===========================================================================
# 7.3 Conduct Regular Access Reviews
# Profile: L1 | NIST: AC-2(3) | SOC 2: CC6.1, CC6.2
# ===========================================================================
control_7_3() {
  should_apply 1 || { increment_skipped; return 0; }
  info "7.3 Conducting access review..."

  # -----------------------------------------------------------------------
  # 7.3a: Find active users who haven't logged in for 90+ days
  # -----------------------------------------------------------------------
  info "7.3 Finding inactive users (no login in 90+ days)..."
  ACTIVE_USERS=$(okta_get "/api/v1/users?filter=status+eq+%22ACTIVE%22&limit=200" 2>/dev/null || echo "[]")
  TOTAL_ACTIVE=$(echo "${ACTIVE_USERS}" | jq 'length' 2>/dev/null || echo "0")

  INACTIVE_COUNT=$(echo "${ACTIVE_USERS}" | jq \
    '[.[] | select(.lastLogin != null) | select((.lastLogin | fromdateiso8601) < (now - 7776000))] | length' \
    2>/dev/null || echo "0")

  info "7.3 Total active users (first page): ${TOTAL_ACTIVE}"

  if [ "${INACTIVE_COUNT}" -gt 0 ]; then
    warn "7.3 Found ${INACTIVE_COUNT} user(s) with no login in 90+ days:"
    echo "${ACTIVE_USERS}" | jq -r \
      '[.[] | select(.lastLogin != null) | select((.lastLogin | fromdateiso8601) < (now - 7776000))] | .[] | "  - \(.profile.login) (last login: \(.lastLogin))"' \
      2>/dev/null || true
  else
    pass "7.3 No inactive users detected (within first 200 users)"
  fi

  # -----------------------------------------------------------------------
  # 7.3b: Count Super Admin assignments
  # -----------------------------------------------------------------------
  info "7.3 Counting Super Admin role assignments..."

  # Try the IAM assignees endpoint first
  SUPER_ADMIN_COUNT=$(okta_get "/api/v1/iam/assignees/users?roleType=SUPER_ADMIN" 2>/dev/null \
    | jq 'length' 2>/dev/null || echo "unknown")

  if [ "${SUPER_ADMIN_COUNT}" != "unknown" ] && [ "${SUPER_ADMIN_COUNT}" -ge 0 ] 2>/dev/null; then
    if [ "${SUPER_ADMIN_COUNT}" -gt 5 ]; then
      warn "7.3 Super Admin count: ${SUPER_ADMIN_COUNT} (should be fewer than 5)"
    else
      pass "7.3 Super Admin count: ${SUPER_ADMIN_COUNT} (within recommended limit of < 5)"
    fi
  else
    warn "7.3 Unable to count Super Admin assignments via IAM API"

    # Fallback: enumerate users and check roles individually
    info "7.3 Attempting fallback Super Admin enumeration (checking first 50 users)..."
    local super_count=0
    for USER_ID in $(echo "${ACTIVE_USERS}" | jq -r '.[].id' 2>/dev/null | head -50); do
      ROLES=$(okta_get "/api/v1/users/${USER_ID}/roles" 2>/dev/null || echo "[]")
      IS_SUPER=$(echo "${ROLES}" | jq '[.[] | select(.type == "SUPER_ADMIN")] | length' 2>/dev/null || echo "0")
      if [ "${IS_SUPER}" -gt 0 ]; then
        USER_LOGIN=$(echo "${ACTIVE_USERS}" | jq -r ".[] | select(.id == \"${USER_ID}\") | .profile.login" 2>/dev/null || echo "unknown")
        warn "7.3   Super Admin: ${USER_LOGIN}"
        super_count=$((super_count + 1))
      fi
    done

    SUPER_ADMIN_COUNT="${super_count}"
    if [ "${super_count}" -gt 5 ]; then
      warn "7.3 Found ${super_count} Super Admin(s) in first 50 users (should be < 5)"
    else
      pass "7.3 Found ${super_count} Super Admin(s) in first 50 users"
    fi
  fi

  # -----------------------------------------------------------------------
  # 7.3c: List admin role assignments
  # -----------------------------------------------------------------------
  info "7.3 Listing admin role assignments..."
  ADMIN_ROLES=$(okta_get "/api/v1/iam/assignees/users" 2>/dev/null || echo "[]")
  ADMIN_COUNT=$(echo "${ADMIN_ROLES}" | jq 'length' 2>/dev/null || echo "0")

  if [ "${ADMIN_COUNT}" -gt 0 ]; then
    info "7.3 Found ${ADMIN_COUNT} admin role assignment(s)"
    echo "${ADMIN_ROLES}" | jq -r \
      '.[] | "  - User: \(.userId), Role: \(.role // .type // "unknown")"' \
      2>/dev/null || true
  fi

  # -----------------------------------------------------------------------
  # 7.3d: Summary and recommendations
  # -----------------------------------------------------------------------
  echo ""
  info "7.3 Access Review Summary:"
  info "  Active users checked: ${TOTAL_ACTIVE} (first page)"
  info "  Inactive 90+ days: ${INACTIVE_COUNT}"
  info "  Super Admin count: ${SUPER_ADMIN_COUNT}"
  info "  Admin role assignments: ${ADMIN_COUNT}"
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
}

# ===========================================================================
# Execute all controls
# ===========================================================================
control_7_3

summary
