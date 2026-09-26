#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: aws-iam-identity-center-3.4
#   guide:   https://howtoharden.com/guides/aws-iam-identity-center/#34-govern-the-ssoaccountaccess-scope-on-customer-managed-applications
#   profile: L2
#   mode:    read-only
#   requires: AWS_REGION; AWS credentials in the management or delegated-administrator account with sso:ListInstances, sso:ListApplications, sso:ListApplicationAccessScopes
# =============================================================================
# HTH AWS IAM Identity Center Control 3.4: Govern the sso:account:access Scope
# Profile: L2 | NIST: AC-6, AC-3 | Frameworks: CIS Controls 5.4, 6.8
# https://howtoharden.com/guides/aws-iam-identity-center/#34-govern-the-ssoaccountaccess-scope-on-customer-managed-applications
# Dependencies: aws (CLI v2), jq
#
# Inventory every application on the instance and flag each one granted the
# sso:account:access scope. The scope is all-or-nothing (every account and role
# the signed-in user holds), so every holder needs a recorded justification.
# Remediation is a separate, deliberate act:
#   aws sso-admin delete-application-access-scope --application-arn <arn> --scope sso:account:access
source "$(dirname "$0")/common.sh"

banner "3.4: Govern the sso:account:access scope"

should_apply 2 || { increment_skipped; summary; }

# HTH Guide Excerpt: begin cli-audit-account-access-scope
# ListApplications carries InstanceArn (sso_admin); ListApplicationAccessScopes
# takes only the application ARN, so it goes through aws_json.
APPS=$(sso_admin list-applications) || {
  fail "3.4 Failed to list applications (sso:ListApplications)"
  increment_failed
  summary
}
APP_COUNT=0; HOLDERS=0; READ_ERRORS=0
while IFS=$'\t' read -r APP_ARN APP_NAME; do
  [ -n "${APP_ARN}" ] || continue
  APP_COUNT=$((APP_COUNT + 1))
  SCOPES=$(aws_json sso-admin list-application-access-scopes --application-arn "${APP_ARN}") || {
    fail "3.4 Cannot list access scopes for '${APP_NAME}' (sso:ListApplicationAccessScopes)"
    READ_ERRORS=$((READ_ERRORS + 1)); continue
  }
  if echo "${SCOPES}" | jq -e '[(.Scopes // [])[] | select(.Scope == "sso:account:access")] | length > 0' >/dev/null; then
    warn "3.4 Application '${APP_NAME}' holds sso:account:access -- confirm a recorded justification"
    HOLDERS=$((HOLDERS + 1))
  fi
done < <(echo "${APPS}" | jq -r '(.Applications // [])[] | [.ApplicationArn, (.Name // "unnamed")] | @tsv')
# HTH Guide Excerpt: end cli-audit-account-access-scope

if [ "${READ_ERRORS}" -gt 0 ]; then
  fail "3.4 ${READ_ERRORS} scope read(s) failed -- the inventory is incomplete, not clean"
  increment_failed
elif [ "${HOLDERS}" -gt 0 ]; then
  warn "3.4 ${HOLDERS} of ${APP_COUNT} application(s) hold sso:account:access -- each is organization-wide account reach"
  increment_applied
else
  pass "3.4 None of the ${APP_COUNT} application(s) hold sso:account:access"
  increment_applied
fi

summary
