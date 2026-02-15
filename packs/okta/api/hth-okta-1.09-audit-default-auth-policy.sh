#!/usr/bin/env bash
# HTH Okta Control 1.9: Audit Default Authentication Policy
# Profile: L1 | NIST: AC-3, IA-2
# https://howtoharden.com/guides/okta/#19-audit-default-authentication-policy
source "$(dirname "$0")/common.sh"

banner "1.9: Audit Default Authentication Policy"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.9 Auditing default authentication policy..."

# HTH Guide Excerpt: begin api-check-default-policy
# Find the default policy (system=true)
DEFAULT_POLICY_ID=$(okta_get "/api/v1/policies?type=ACCESS_POLICY" \
  | jq -r '.[] | select(.system == true and .name == "Default Policy") | .id' 2>/dev/null || true)
# HTH Guide Excerpt: end api-check-default-policy

if [ -z "${DEFAULT_POLICY_ID}" ]; then
  warn "1.9 Could not find Default Policy"
  increment_skipped
  summary
  exit 0
fi

info "1.9 Default Policy ID: ${DEFAULT_POLICY_ID}"

# HTH Guide Excerpt: begin api-list-policy-apps
# List apps assigned to the default policy
DEFAULT_APPS=$(okta_get "/api/v1/policies/${DEFAULT_POLICY_ID}/app" 2>/dev/null || echo "[]")
APP_COUNT=$(echo "${DEFAULT_APPS}" | jq 'length' 2>/dev/null || echo "0")
# HTH Guide Excerpt: end api-list-policy-apps

if [ "${APP_COUNT}" -gt 0 ]; then
  warn "1.9 Found ${APP_COUNT} application(s) assigned to the Default Policy (password-only):"
  echo "${DEFAULT_APPS}" | jq -r '.[] | "  - \(.label // .name) (ID: \(.id))"' 2>/dev/null || true
  warn "1.9 These apps allow password-only login -- reassign to an MFA-enforcing policy"
  warn "1.9 Reassign: curl -X PUT \"\${OKTA_BASE}/api/v1/apps/\${APP_ID}/policies/\${TARGET_POLICY_ID}\" -H \"\${AUTH_HEADER}\""
else
  pass "1.9 Default Policy has zero applications assigned -- no MFA gap"
fi

increment_applied

summary
