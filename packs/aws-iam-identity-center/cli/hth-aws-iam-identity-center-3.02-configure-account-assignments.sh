#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: aws-iam-identity-center-3.2
#   guide:   https://howtoharden.com/guides/aws-iam-identity-center/#32-configure-account-assignments
#   profile: L1
#   mode:    read-only
#   requires: AWS_REGION; AWS credentials with sso:ListInstances, sso:ListPermissionSets, sso:DescribePermissionSet, sso:ListAccountAssignments, organizations:ListAccounts, organizations:DescribeOrganization (run from the management or delegated-administrator account)
# =============================================================================
# HTH AWS IAM Identity Center Control 3.2: Configure Account Assignments
# Profile: L1 | NIST: AC-6 | Frameworks: SOC 2 CC6.1, ISO 27001 A.9.2.2
# https://howtoharden.com/guides/aws-iam-identity-center/#32-configure-account-assignments
# Dependencies: aws (CLI v2), jq
# Exit codes: 0 compliant | 1 finding or failed read | 2 precondition
#
# A direct USER assignment is a FINDING: guide 3.2 Step 2 says "Use groups for
# assignments". The management-account count (> 2) stays an advisory WARN,
# because the guide sets no number for it.
#
# TWO TRAPS THIS PACK USED TO FALL INTO:
#   1. Organizations unavailable (standalone account, member account, or
#      AccessDenied) left the account list empty, the assignment loop scanned
#      nothing, and the pack printed "All assignments are group-based". Zero
#      accounts scanned is now a FAIL, never a PASS.
#   2. Account.Status is being retired: AWS's Organizations model says it "will
#      be retired on September 9, 2026 ... use the State parameter". A filter on
#      .Status alone silently drops every account once the field disappears, so
#      the filter reads State and falls back to Status.
source "$(dirname "$0")/common.sh"

banner "3.2: Configure Account Assignments"

should_apply 1 || { increment_skipped; summary; }
info "3.2 Auditing account assignments..."

# HTH Guide Excerpt: begin cli-audit-account-assignments
# Audit account assignments across all permission sets and active accounts.
PS_JSON=$(sso_admin list-permission-sets) || {
  fail "3.2 Failed to list permission sets (sso:ListPermissionSets)"
  increment_failed
  summary
}
PS_ARNS=$(echo "${PS_JSON}" | jq -r '.PermissionSets[]')

ACCOUNTS_JSON=$(aws_json organizations list-accounts) || {
  fail "3.2 Cannot list organization accounts (organizations:ListAccounts) -- assignments were NOT scanned"
  increment_failed
  summary
}
# State replaces the retiring Status field; read State first.
ACCOUNTS=$(echo "${ACCOUNTS_JSON}" \
  | jq -r '.Accounts[] | select((.State // .Status) == "ACTIVE") | .Id')
ACCOUNT_COUNT=$(echo "${ACCOUNTS}" | grep -c . || true)

TOTAL_ASSIGNMENTS=0; USER_DIRECT_ASSIGNMENTS=0; READ_ERRORS=0

for PS_ARN in ${PS_ARNS}; do
  PS_DETAIL=$(sso_admin describe-permission-set --permission-set-arn "${PS_ARN}") || {
    fail "3.2 Cannot describe ${PS_ARN##*/} (sso:DescribePermissionSet)"
    READ_ERRORS=$((READ_ERRORS + 1)); continue
  }
  PS_NAME=$(echo "${PS_DETAIL}" | jq -r '.PermissionSet.Name')

  for ACCOUNT_ID in ${ACCOUNTS}; do
    ASSIGNMENTS=$(sso_admin list-account-assignments \
      --account-id "${ACCOUNT_ID}" --permission-set-arn "${PS_ARN}") || {
      fail "3.2 Cannot list assignments for ${ACCOUNT_ID} / '${PS_NAME}' (sso:ListAccountAssignments)"
      READ_ERRORS=$((READ_ERRORS + 1)); continue
    }
    COUNT=$(echo "${ASSIGNMENTS}" | jq '(.AccountAssignments // []) | length')
    TOTAL_ASSIGNMENTS=$((TOTAL_ASSIGNMENTS + COUNT))

    # Flag direct user assignments (should use groups instead)
    USER_ASSIGNMENTS=$(echo "${ASSIGNMENTS}" \
      | jq '[(.AccountAssignments // [])[] | select(.PrincipalType == "USER")] | length')
    if [ "${USER_ASSIGNMENTS}" -gt 0 ]; then
      fail "3.2 Account ${ACCOUNT_ID} / PS '${PS_NAME}': ${USER_ASSIGNMENTS} direct user assignment(s) -- use groups instead"
      USER_DIRECT_ASSIGNMENTS=$((USER_DIRECT_ASSIGNMENTS + USER_ASSIGNMENTS))
    fi
  done
done
# HTH Guide Excerpt: end cli-audit-account-assignments

info "3.2 Scanned ${ACCOUNT_COUNT} active account(s); total assignments found: ${TOTAL_ASSIGNMENTS}"

if [ "${ACCOUNT_COUNT}" -eq 0 ]; then
  fail "3.2 Zero active accounts returned -- nothing was scanned, so no verdict is possible"
  increment_failed
elif [ "${READ_ERRORS}" -gt 0 ]; then
  fail "3.2 ${READ_ERRORS} read(s) failed -- the assignment audit is incomplete, not clean"
  increment_failed
elif [ "${USER_DIRECT_ASSIGNMENTS}" -gt 0 ]; then
  fail "3.2 Found ${USER_DIRECT_ASSIGNMENTS} direct user assignment(s) -- guide 3.2 requires group-based assignments (AC-6)"
  increment_failed
else
  pass "3.2 All assignments across ${ACCOUNT_COUNT} account(s) are group-based (no direct user assignments)"
  increment_applied
fi

# HTH Guide Excerpt: begin cli-check-management-account
# Verify the management account has restricted access
info "3.2 Checking management account assignments..."
ORG_JSON=$(aws_json organizations describe-organization) || {
  fail "3.2 Cannot determine the management account (organizations:DescribeOrganization)"
  increment_failed
  summary
}
MGMT_ACCOUNT=$(echo "${ORG_JSON}" | jq -r '.Organization.MasterAccountId // empty')
[ -n "${MGMT_ACCOUNT}" ] || { fail "3.2 DescribeOrganization returned no management account id"; increment_failed; summary; }

MGMT_ASSIGNMENTS=0; MGMT_READ_ERRORS=0
for PS_ARN in ${PS_ARNS}; do
  ASSIGNMENTS=$(sso_admin list-account-assignments \
    --account-id "${MGMT_ACCOUNT}" --permission-set-arn "${PS_ARN}") || {
    MGMT_READ_ERRORS=$((MGMT_READ_ERRORS + 1)); continue
  }
  COUNT=$(echo "${ASSIGNMENTS}" | jq '(.AccountAssignments // []) | length')
  MGMT_ASSIGNMENTS=$((MGMT_ASSIGNMENTS + COUNT))
done

if [ "${MGMT_READ_ERRORS}" -gt 0 ]; then
  fail "3.2 ${MGMT_READ_ERRORS} management-account assignment read(s) failed -- cannot confirm restriction"
  increment_failed
elif [ "${MGMT_ASSIGNMENTS}" -gt 2 ]; then
  warn "3.2 Management account has ${MGMT_ASSIGNMENTS} assignments -- limit access (AC-6(1))"
  increment_applied
else
  pass "3.2 Management account access is appropriately restricted (${MGMT_ASSIGNMENTS} assignments)"
  increment_applied
fi
# HTH Guide Excerpt: end cli-check-management-account

summary
