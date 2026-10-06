#!/usr/bin/env bash
# HTH Okta Control 1.9: Audit Default Authentication Policy
# Profile: L1 | NIST: AC-3, IA-2
# https://howtoharden.com/guides/okta/#19-audit-default-authentication-policy
#
# Read-only. The org's default app sign-in policy is the one ACCESS_POLICY with
# "system": true. Its name varies by org ("Default Policy" in older orgs,
# "Any two factors" in newer ones), so it is never looked up by name.
source "$(dirname "$0")/common.sh"

banner "1.9: Audit Default Authentication Policy"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.9 Auditing default authentication policy..."

# HTH Guide Excerpt: begin api-check-default-policy
# Find the default app sign-in policy (system=true), whatever it is named
DEFAULT_POLICY=$(okta_get "/api/v1/policies?type=ACCESS_POLICY" \
  | jq -c '[.[] | select(.system == true)][0] // empty')
# HTH Guide Excerpt: end api-check-default-policy

if [ -z "${DEFAULT_POLICY}" ]; then
  fail "1.9 No system (default) app sign-in policy returned -- cannot audit"
  increment_failed
  summary
fi

DEFAULT_POLICY_ID=$(printf '%s' "${DEFAULT_POLICY}" | jq -r '.id')
DEFAULT_POLICY_NAME=$(printf '%s' "${DEFAULT_POLICY}" | jq -r '.name')
info "1.9 Default app sign-in policy: '${DEFAULT_POLICY_NAME}' (${DEFAULT_POLICY_ID})"

# HTH Guide Excerpt: begin api-list-policy-apps
# List apps assigned to the default policy (a failed read stops the pack)
DEFAULT_APPS=$(okta_get "/api/v1/policies/${DEFAULT_POLICY_ID}/app")
APP_COUNT=$(printf '%s' "${DEFAULT_APPS}" | jq 'length')
# HTH Guide Excerpt: end api-list-policy-apps

if [ "${APP_COUNT}" -gt 0 ]; then
  warn "1.9 Found ${APP_COUNT} application(s) assigned to the default policy '${DEFAULT_POLICY_NAME}':"
  printf '%s' "${DEFAULT_APPS}" | jq -r '.[] | "  - \(.label // .name) (ID: \(.id))"'
  warn "1.9 Move each app to an explicit policy that enforces MFA: PUT /api/v1/apps/{appId}/policies/{policyId}"
else
  pass "1.9 Default policy '${DEFAULT_POLICY_NAME}' has zero applications assigned"
fi

increment_applied

summary
