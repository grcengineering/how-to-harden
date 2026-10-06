#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: aws-iam-identity-center-1.2
#   guide:   https://howtoharden.com/guides/aws-iam-identity-center/#12-configure-session-duration
#   profile: L1
#   mode:    read-only
#   requires: AWS_REGION; AWS credentials with sso:ListInstances, sso:ListPermissionSets, sso:DescribePermissionSet, sso:ListManagedPoliciesInPermissionSet
# =============================================================================
# HTH AWS IAM Identity Center Control 1.2: Configure Session Duration
# Profile: L1 | NIST: AC-12 | Frameworks: CIS Controls 6.2
# https://howtoharden.com/guides/aws-iam-identity-center/#12-configure-session-duration
# Dependencies: aws (CLI v2), jq
# Exit codes: 0 compliant | 1 finding or failed read | 2 precondition
#
# SCOPE: the permission-set half of 1.2 only. The interactive (AWS access portal)
# session duration has no public API -- it is not in the IAM Identity Center API
# operation list -- so it can only be read in the console (Settings ->
# Authentication -> Session duration). This pack says so instead of guessing.
#
# Thresholds follow the guide: administrative and other high-blast-radius
# permission sets should run at 1 hour, the minimum AWS allows (range 1-12 h),
# because these role sessions survive user deletion. A privileged set over its
# limit is a FINDING (exit 1). The guide sets no number for other sets, so the
# 4-hour limit on them is this pack's advisory (WARN, exit 0) -- the same 4-hour
# advisory the 3.1 pack uses. Override with:
#   HTH_ADMIN_MAX_SESSION  (default PT1H)  -- for sets carrying a privileged policy
#   HTH_MAX_SESSION        (default PT4H)  -- advisory limit for every other set
#   HTH_PRIVILEGED_POLICIES (default "AdministratorAccess IAMFullAccess")
#
# Classification limit: a set counts as privileged only when an AWS managed policy
# named in HTH_PRIVILEGED_POLICIES is attached to it. A set made admin-equivalent
# by an inline policy or a customer managed policy reference is classed standard,
# so it gets at most the 4-hour WARN. Review such sets by hand, or run with
# HTH_MAX_SESSION=PT1H to WARN on every set over 1 hour.
source "$(dirname "$0")/common.sh"

ADMIN_MAX="${HTH_ADMIN_MAX_SESSION:-PT1H}"
OTHER_MAX="${HTH_MAX_SESSION:-PT4H}"
PRIVILEGED="${HTH_PRIVILEGED_POLICIES:-AdministratorAccess IAMFullAccess}"
ADMIN_MAX_S=$(iso8601_seconds "${ADMIN_MAX}") || precondition "HTH_ADMIN_MAX_SESSION '${ADMIN_MAX}' is not an ISO-8601 duration"
OTHER_MAX_S=$(iso8601_seconds "${OTHER_MAX}") || precondition "HTH_MAX_SESSION '${OTHER_MAX}' is not an ISO-8601 duration"

banner "1.2: Configure Session Duration (permission sets)"

should_apply 1 || { increment_skipped; summary; }
info "1.2 Interactive (portal) session duration has no public API -- verify it in the console"

# HTH Guide Excerpt: begin cli-audit-session-duration
# Compare every permission set's SessionDuration with the guide's thresholds.
PS_JSON=$(sso_admin list-permission-sets) || {
  fail "1.2 Failed to list permission sets (sso:ListPermissionSets)"
  increment_failed
  summary
}
# Extract the list on its own line: inside a for-list a jq failure is silent and
# would read as "no permission sets" (exit 0) instead of a failed read.
PS_ARNS=$(echo "${PS_JSON}" | jq -r '.PermissionSets[]') || {
  fail "1.2 ListPermissionSets returned no readable PermissionSets list -- nothing was audited"
  increment_failed
  summary
}
PRIV_RE="$(echo "${PRIVILEGED}" | tr ' ' '|')"
PS_COUNT=0; PRIV_COUNT=0; STD_COUNT=0; PRIV_OVER=0; STD_OVER=0; READ_ERRORS=0

for PS_ARN in ${PS_ARNS}; do
  PS_DETAIL=$(sso_admin describe-permission-set --permission-set-arn "${PS_ARN}") || {
    fail "1.2 Cannot describe ${PS_ARN##*/} (sso:DescribePermissionSet)"
    READ_ERRORS=$((READ_ERRORS + 1)); continue
  }
  PS_NAME=$(echo "${PS_DETAIL}" | jq -r '.PermissionSet.Name')
  DURATION=$(echo "${PS_DETAIL}" | jq -r '.PermissionSet.SessionDuration // "PT1H"')
  SECONDS_SET=$(iso8601_seconds "${DURATION}") || {
    fail "1.2 '${PS_NAME}': unparseable session duration '${DURATION}'"
    READ_ERRORS=$((READ_ERRORS + 1)); continue
  }
  POLICIES=$(sso_admin list-managed-policies-in-permission-set --permission-set-arn "${PS_ARN}") || {
    fail "1.2 Cannot list managed policies on '${PS_NAME}' (sso:ListManagedPoliciesInPermissionSet)"
    READ_ERRORS=$((READ_ERRORS + 1)); continue
  }
  PS_COUNT=$((PS_COUNT + 1))

  if echo "${POLICIES}" | jq -e --arg re ":iam::aws:policy/(${PRIV_RE})$" \
      '[(.AttachedManagedPolicies // [])[].Arn | select(test($re))] | length > 0' >/dev/null; then
    LIMIT_S="${ADMIN_MAX_S}"; LIMIT="${ADMIN_MAX}"; KIND="privileged"; PRIV_COUNT=$((PRIV_COUNT + 1))
  else
    LIMIT_S="${OTHER_MAX_S}"; LIMIT="${OTHER_MAX}"; KIND="standard"; STD_COUNT=$((STD_COUNT + 1))
  fi
  if [ "${SECONDS_SET}" -gt "${LIMIT_S}" ] && [ "${KIND}" = "privileged" ]; then
    fail "1.2 privileged permission set '${PS_NAME}': session ${DURATION} exceeds ${LIMIT}"
    PRIV_OVER=$((PRIV_OVER + 1))
  elif [ "${SECONDS_SET}" -gt "${LIMIT_S}" ]; then
    warn "1.2 standard permission set '${PS_NAME}': session ${DURATION} exceeds the ${LIMIT} advisory"
    STD_OVER=$((STD_OVER + 1))
  else
    info "1.2   ${KIND} permission set '${PS_NAME}': session ${DURATION} (limit ${LIMIT})"
  fi
done
# HTH Guide Excerpt: end cli-audit-session-duration

if [ "${READ_ERRORS}" -gt 0 ]; then
  fail "1.2 ${READ_ERRORS} permission-set read(s) failed -- the session audit is incomplete, not clean"
  increment_failed
elif [ "${PS_COUNT}" -eq 0 ]; then
  info "1.2 No permission sets exist -- nothing to audit on the permission-set half"
  increment_skipped
elif [ "${PRIV_OVER}" -gt 0 ]; then
  fail "1.2 ${PRIV_OVER} of ${PRIV_COUNT} privileged permission set(s) exceed ${ADMIN_MAX} -- guide 1.2 sets them to 1 hour (AC-12)"
  increment_failed
elif [ "${STD_OVER}" -gt 0 ]; then
  warn "1.2 ${STD_OVER} of ${STD_COUNT} standard permission set(s) exceed the ${OTHER_MAX} advisory -- review; privileged sets are within ${ADMIN_MAX}"
  increment_applied
else
  pass "1.2 All ${PS_COUNT} permission sets are within the guide's session limits (privileged = AWS managed ${PRIVILEGED})"
  increment_applied
fi

summary
