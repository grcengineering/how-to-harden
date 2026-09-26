#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: aws-iam-identity-center-3.1
#   guide:   https://howtoharden.com/guides/aws-iam-identity-center/#31-configure-permission-sets
#   profile: L1
#   mode:    read-only
#   requires: AWS_REGION; AWS credentials with sso:ListInstances, sso:ListPermissionSets, sso:DescribePermissionSet, sso:ListManagedPoliciesInPermissionSet
# =============================================================================
# HTH AWS IAM Identity Center Control 3.1: Configure Permission Sets
# Profile: L1 | NIST: AC-6 | Frameworks: SOC 2 CC6.3, ISO 27001 A.9.2.3
# https://howtoharden.com/guides/aws-iam-identity-center/#31-configure-permission-sets
# Dependencies: aws (CLI v2), jq
#
# FAIL-CLOSED BY DESIGN. An earlier revision piped every per-set read through
# `|| true` / `|| continue`, so a credential missing
# sso:ListManagedPoliciesInPermissionSet printed "No permission sets use
# AdministratorAccess" -- a PASS built on reads that never happened. Every read
# below that fails is counted, and any failed read turns the verdict into FAIL.
source "$(dirname "$0")/common.sh"

banner "3.1: Configure Permission Sets"

should_apply 1 || { increment_skipped; summary; }
info "3.1 Auditing permission sets..."

# HTH Guide Excerpt: begin cli-audit-permission-sets
# List every permission set, then read its session duration and managed policies.
# A read that fails is counted as a failure, never as "nothing attached".
PS_JSON=$(sso_admin list-permission-sets) || {
  fail "3.1 Failed to list permission sets (sso:ListPermissionSets)"
  increment_failed
  summary
}
PS_ARNS=$(echo "${PS_JSON}" | jq -r '.PermissionSets[]')

PS_COUNT=0; READ_ERRORS=0; LONG_SESSION_COUNT=0; ADMIN_PS_COUNT=0
MAX_RECOMMENDED_SECONDS=14400   # PT4H -- see 1.2 for the 1-hour admin recommendation

for PS_ARN in ${PS_ARNS}; do
  PS_DETAIL=$(sso_admin describe-permission-set --permission-set-arn "${PS_ARN}") || {
    fail "3.1 Cannot describe ${PS_ARN##*/} (sso:DescribePermissionSet)"
    READ_ERRORS=$((READ_ERRORS + 1)); continue
  }
  PS_NAME=$(echo "${PS_DETAIL}" | jq -r '.PermissionSet.Name')
  # AWS applies a 1-hour session when none was set on the permission set.
  SESSION_DURATION=$(echo "${PS_DETAIL}" | jq -r '.PermissionSet.SessionDuration // "PT1H"')
  PS_COUNT=$((PS_COUNT + 1))

  if ! DURATION_SECONDS=$(iso8601_seconds "${SESSION_DURATION}"); then
    fail "3.1 '${PS_NAME}': unparseable session duration '${SESSION_DURATION}'"
    READ_ERRORS=$((READ_ERRORS + 1))
  elif [ "${DURATION_SECONDS}" -gt "${MAX_RECOMMENDED_SECONDS}" ]; then
    warn "3.1 Permission set '${PS_NAME}' has long session: ${SESSION_DURATION}"
    LONG_SESSION_COUNT=$((LONG_SESSION_COUNT + 1))
  fi

  POLICIES=$(sso_admin list-managed-policies-in-permission-set --permission-set-arn "${PS_ARN}") || {
    fail "3.1 Cannot list managed policies on '${PS_NAME}' (sso:ListManagedPoliciesInPermissionSet)"
    READ_ERRORS=$((READ_ERRORS + 1)); continue
  }
  if echo "${POLICIES}" | jq -e '[(.AttachedManagedPolicies // [])[].Arn
        | select(test(":iam::aws:policy/AdministratorAccess$"))] | length > 0' >/dev/null; then
    warn "3.1 Permission set '${PS_NAME}' has AdministratorAccess -- apply least privilege"
    ADMIN_PS_COUNT=$((ADMIN_PS_COUNT + 1))
  fi
  info "3.1   ${PS_NAME} (session: ${SESSION_DURATION}, policies: $(echo "${POLICIES}" \
    | jq -r '[(.AttachedManagedPolicies // [])[].Name] | join(",") | if . == "" then "none" else . end'))"
done
# HTH Guide Excerpt: end cli-audit-permission-sets

# HTH Guide Excerpt: begin cli-verdict-permission-sets
# The verdict is only as good as the reads behind it.
if [ "${READ_ERRORS}" -gt 0 ]; then
  fail "3.1 ${READ_ERRORS} permission-set read(s) failed -- the audit is incomplete, not clean"
  increment_failed
elif [ "${PS_COUNT}" -eq 0 ]; then
  warn "3.1 No permission sets found -- create permission sets before assigning access"
  increment_failed
else
  if [ "${LONG_SESSION_COUNT}" -gt 0 ]; then
    warn "3.1 ${LONG_SESSION_COUNT} of ${PS_COUNT} permission set(s) allow sessions longer than 4 hours (AC-12)"
  else
    pass "3.1 All ${PS_COUNT} permission sets have sessions of 4 hours or less"
  fi
  if [ "${ADMIN_PS_COUNT}" -gt 0 ]; then
    warn "3.1 ${ADMIN_PS_COUNT} permission set(s) use AdministratorAccess -- review for least privilege (AC-6)"
  else
    pass "3.1 None of the ${PS_COUNT} permission sets use AdministratorAccess"
  fi
  increment_applied
fi
# HTH Guide Excerpt: end cli-verdict-permission-sets

summary
