#!/usr/bin/env bash
# HTH AWS IAM Identity Center Control 3.1: Configure Permission Sets
# Profile: L1 | NIST: AC-6 | Frameworks: SOC 2 CC6.3, ISO 27001 A.9.2.3
# https://howtoharden.com/guides/aws-iam-identity-center/#31-configure-permission-sets
source "$(dirname "$0")/common.sh"

banner "3.1: Configure Permission Sets"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "3.1 Auditing permission sets..."

# HTH Guide Excerpt: begin api-list-permission-sets
# List all permission sets and their configurations
info "3.1 Retrieving all permission sets..."
PS_ARNS=$(sso_admin list-permission-sets \
  | jq -r '.PermissionSets[]' 2>/dev/null) || {
  fail "3.1 Failed to list permission sets"
  increment_failed
  summary
  exit 0
}

PS_COUNT=0
LONG_SESSION_COUNT=0
MAX_RECOMMENDED_DURATION="PT4H"

for PS_ARN in ${PS_ARNS}; do
  PS_DETAIL=$(sso_admin describe-permission-set \
    --permission-set-arn "${PS_ARN}" 2>/dev/null) || continue

  PS_NAME=$(echo "${PS_DETAIL}" | jq -r '.PermissionSet.Name')
  SESSION_DURATION=$(echo "${PS_DETAIL}" | jq -r '.PermissionSet.SessionDuration')
  PS_COUNT=$((PS_COUNT + 1))

  # Check for overly long session durations (> 4 hours)
  DURATION_SECONDS=$(echo "${SESSION_DURATION}" | sed 's/PT//;s/H/*3600+/;s/M/*60+/;s/S//;s/+$//' | bc 2>/dev/null || echo "0")
  if [ "${DURATION_SECONDS}" -gt 14400 ]; then
    warn "3.1 Permission set '${PS_NAME}' has long session: ${SESSION_DURATION}"
    LONG_SESSION_COUNT=$((LONG_SESSION_COUNT + 1))
  fi

  # List managed policies attached
  MANAGED_POLICIES=$(sso_admin list-managed-policies-in-permission-set \
    --permission-set-arn "${PS_ARN}" \
    | jq -r '.AttachedManagedPolicies[].Name' 2>/dev/null || echo "none")

  info "3.1   ${PS_NAME} (session: ${SESSION_DURATION}, policies: ${MANAGED_POLICIES})"
done
# HTH Guide Excerpt: end api-list-permission-sets

if [ "${PS_COUNT}" -eq 0 ]; then
  warn "3.1 No permission sets found -- create permission sets before assigning access"
  increment_failed
elif [ "${LONG_SESSION_COUNT}" -gt 0 ]; then
  warn "3.1 Found ${LONG_SESSION_COUNT} permission set(s) with sessions exceeding 4 hours"
  warn "3.1 NIST AC-12 recommends limiting session duration for privileged access"
  increment_applied
else
  pass "3.1 All ${PS_COUNT} permission sets have reasonable session durations"
  increment_applied
fi

# HTH Guide Excerpt: begin api-check-admin-policies
# Flag permission sets with AdministratorAccess or overly broad policies
info "3.1 Checking for overly broad permission sets..."
ADMIN_PS_COUNT=0

for PS_ARN in ${PS_ARNS}; do
  PS_DETAIL=$(sso_admin describe-permission-set \
    --permission-set-arn "${PS_ARN}" 2>/dev/null) || continue
  PS_NAME=$(echo "${PS_DETAIL}" | jq -r '.PermissionSet.Name')

  MANAGED_POLICIES=$(sso_admin list-managed-policies-in-permission-set \
    --permission-set-arn "${PS_ARN}" \
    | jq -r '.AttachedManagedPolicies[].Arn' 2>/dev/null || true)

  if echo "${MANAGED_POLICIES}" | grep -q "AdministratorAccess"; then
    warn "3.1 Permission set '${PS_NAME}' has AdministratorAccess -- apply least privilege"
    ADMIN_PS_COUNT=$((ADMIN_PS_COUNT + 1))
  fi
done

if [ "${ADMIN_PS_COUNT}" -gt 0 ]; then
  warn "3.1 ${ADMIN_PS_COUNT} permission set(s) use AdministratorAccess -- review for least privilege (AC-6)"
else
  pass "3.1 No permission sets use AdministratorAccess"
fi
# HTH Guide Excerpt: end api-check-admin-policies

summary
