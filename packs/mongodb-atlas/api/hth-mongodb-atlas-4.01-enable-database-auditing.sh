#!/usr/bin/env bash
# HTH MongoDB Atlas Control 4.1: Enable Database Auditing (L1)
# Profile: L1 | SOC 2: CC7.2, CC7.3 | NIST: AU-2, AU-3, AU-12
# https://howtoharden.com/guides/mongodb-atlas/#41-database-auditing
source "$(dirname "$0")/common.sh"

banner "4.1: Enable Database Auditing"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "4.1 Checking database auditing for project ${ATLAS_PROJECT_ID}..."

# HTH Guide Excerpt: begin api-enable-auditing
# Retrieve current auditing configuration
AUDIT_CONFIG=$(atlas_get "/groups/${ATLAS_PROJECT_ID}/auditing") || {
  fail "4.1 Failed to retrieve auditing configuration (requires M10+ cluster)"
  increment_failed
  summary
  exit 1
}

AUDIT_ENABLED=$(echo "${AUDIT_CONFIG}" | jq -r '.enabled // false')
AUDIT_FILTER=$(echo "${AUDIT_CONFIG}" | jq -r '.auditFilter // "none"')
AUDIT_AUTH_SUCCESS=$(echo "${AUDIT_CONFIG}" | jq -r '.auditAuthorizationSuccess // false')

if [ "${AUDIT_ENABLED}" = "true" ]; then
  pass "4.1 Database auditing is enabled"
  info "4.1 Current audit filter: ${AUDIT_FILTER}"
  info "4.1 Audit authorization success: ${AUDIT_AUTH_SUCCESS}"
  increment_applied
else
  warn "4.1 Database auditing is DISABLED -- enabling now..."

  # Enable auditing with a comprehensive filter
  AUDIT_PAYLOAD='{
    "enabled": true,
    "auditFilter": "{\"$or\":[{\"users\":[]},{\"atype\":{\"$in\":[\"authCheck\",\"authenticate\",\"createCollection\",\"createDatabase\",\"createIndex\",\"dropCollection\",\"dropDatabase\",\"dropIndex\",\"createUser\",\"dropUser\",\"updateUser\",\"grantRolesToUser\",\"revokeRolesFromUser\",\"createRole\",\"dropRole\",\"updateRole\",\"shutdown\"]}}]}",
    "auditAuthorizationSuccess": false
  }'

  RESULT=$(atlas_patch "/groups/${ATLAS_PROJECT_ID}/auditing" "${AUDIT_PAYLOAD}") || {
    fail "4.1 Failed to enable auditing"
    increment_failed
    summary
    exit 1
  }

  NEW_STATUS=$(echo "${RESULT}" | jq -r '.enabled // false')
  if [ "${NEW_STATUS}" = "true" ]; then
    pass "4.1 Database auditing enabled successfully"
    increment_applied
  else
    fail "4.1 Auditing enable request returned but status is still disabled"
    increment_failed
  fi
fi

# L2 check: audit authorization success should be enabled
if should_apply 2 2>/dev/null; then
  if [ "${AUDIT_AUTH_SUCCESS}" != "true" ]; then
    warn "4.1 L2 recommends enabling auditAuthorizationSuccess for full visibility"
  else
    pass "4.1 L2: auditAuthorizationSuccess is enabled"
  fi
fi
# HTH Guide Excerpt: end api-enable-auditing

summary
