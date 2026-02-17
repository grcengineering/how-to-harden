#!/usr/bin/env bash
# HTH AWS IAM Identity Center Control 3.2: Configure Account Assignments
# Profile: L1 | NIST: AC-6 | Frameworks: SOC 2 CC6.1, ISO 27001 A.9.2.2
# https://howtoharden.com/guides/aws-iam-identity-center/#32-configure-account-assignments
source "$(dirname "$0")/common.sh"

banner "3.2: Configure Account Assignments"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "3.2 Auditing account assignments..."

# HTH Guide Excerpt: begin api-audit-account-assignments
# Audit account assignments across all permission sets and accounts
info "3.2 Retrieving permission sets..."
PS_ARNS=$(sso_admin list-permission-sets \
  | jq -r '.PermissionSets[]' 2>/dev/null) || {
  fail "3.2 Failed to list permission sets"
  increment_failed
  summary
  exit 0
}

# Get all AWS accounts in the organization
info "3.2 Retrieving organization accounts..."
ACCOUNTS=$(aws_json organizations list-accounts \
  | jq -r '.Accounts[] | select(.Status == "ACTIVE") | .Id' 2>/dev/null) || {
  warn "3.2 Cannot list org accounts -- verify organizations:ListAccounts permission"
  ACCOUNTS=""
}

TOTAL_ASSIGNMENTS=0
USER_DIRECT_ASSIGNMENTS=0

for PS_ARN in ${PS_ARNS}; do
  PS_DETAIL=$(sso_admin describe-permission-set \
    --permission-set-arn "${PS_ARN}" 2>/dev/null) || continue
  PS_NAME=$(echo "${PS_DETAIL}" | jq -r '.PermissionSet.Name')

  for ACCOUNT_ID in ${ACCOUNTS}; do
    ASSIGNMENTS=$(sso_admin list-account-assignments \
      --account-id "${ACCOUNT_ID}" \
      --permission-set-arn "${PS_ARN}" 2>/dev/null) || continue

    ASSIGNMENT_LIST=$(echo "${ASSIGNMENTS}" | jq -r '.AccountAssignments[]' 2>/dev/null) || continue

    # Count and classify assignments
    ACCOUNT_ASSIGNMENT_COUNT=$(echo "${ASSIGNMENTS}" | jq '.AccountAssignments | length' 2>/dev/null || echo "0")
    TOTAL_ASSIGNMENTS=$((TOTAL_ASSIGNMENTS + ACCOUNT_ASSIGNMENT_COUNT))

    # Flag direct user assignments (should use groups instead)
    USER_ASSIGNMENTS=$(echo "${ASSIGNMENTS}" \
      | jq '[.AccountAssignments[] | select(.PrincipalType == "USER")] | length' 2>/dev/null || echo "0")
    if [ "${USER_ASSIGNMENTS}" -gt 0 ]; then
      warn "3.2 Account ${ACCOUNT_ID} / PS '${PS_NAME}': ${USER_ASSIGNMENTS} direct user assignment(s) -- use groups instead"
      USER_DIRECT_ASSIGNMENTS=$((USER_DIRECT_ASSIGNMENTS + USER_ASSIGNMENTS))
    fi
  done
done
# HTH Guide Excerpt: end api-audit-account-assignments

info "3.2 Total assignments found: ${TOTAL_ASSIGNMENTS}"

if [ "${USER_DIRECT_ASSIGNMENTS}" -gt 0 ]; then
  warn "3.2 Found ${USER_DIRECT_ASSIGNMENTS} direct user assignment(s) -- migrate to group-based assignments (AC-6)"
  increment_applied
else
  pass "3.2 All assignments are group-based (no direct user assignments)"
  increment_applied
fi

# HTH Guide Excerpt: begin api-check-management-account
# Verify management account has restricted access
info "3.2 Checking management account assignments..."
MGMT_ACCOUNT=$(aws_json organizations describe-organization \
  | jq -r '.Organization.MasterAccountId' 2>/dev/null) || {
  warn "3.2 Cannot determine management account -- verify organizations:DescribeOrganization permission"
  increment_applied
  summary
  exit 0
}

MGMT_ASSIGNMENTS=0
for PS_ARN in ${PS_ARNS}; do
  ASSIGNMENTS=$(sso_admin list-account-assignments \
    --account-id "${MGMT_ACCOUNT}" \
    --permission-set-arn "${PS_ARN}" 2>/dev/null) || continue
  COUNT=$(echo "${ASSIGNMENTS}" | jq '.AccountAssignments | length' 2>/dev/null || echo "0")
  MGMT_ASSIGNMENTS=$((MGMT_ASSIGNMENTS + COUNT))
done

if [ "${MGMT_ASSIGNMENTS}" -gt 2 ]; then
  warn "3.2 Management account (${MGMT_ACCOUNT}) has ${MGMT_ASSIGNMENTS} assignments -- limit access (AC-6(1))"
else
  pass "3.2 Management account access is appropriately restricted (${MGMT_ASSIGNMENTS} assignments)"
fi
# HTH Guide Excerpt: end api-check-management-account

increment_applied
summary
