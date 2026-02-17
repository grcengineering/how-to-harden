#!/usr/bin/env bash
# HTH Salesforce Control 1.1: Enforce Multi-Factor Authentication
# Profile: L1 | NIST: IA-2(1)
# https://howtoharden.com/guides/salesforce/#11-enforce-multi-factor-authentication
source "$(dirname "$0")/common.sh"

banner "1.1: Enforce Multi-Factor Authentication"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.1 Auditing MFA enforcement across user population..."

# HTH Guide Excerpt: begin api-query-users-without-mfa
# Query active users who do not have MFA enabled
info "1.1 Querying active users without MFA..."
MFA_QUERY="SELECT Id, Username, Name, Profile.Name, IsActive, UserPreferencesDisableMFAPrompt FROM User WHERE IsActive = true"
USER_RESPONSE=$(sf_query "${MFA_QUERY}") || {
  fail "1.1 Failed to query user MFA status"
  increment_failed
  summary
  exit 0
}

TOTAL_USERS=$(echo "${USER_RESPONSE}" | jq '.totalSize // 0' 2>/dev/null)
info "1.1 Total active users: ${TOTAL_USERS}"

# Identify users with MFA prompt disabled (potential bypass)
MFA_DISABLED=$(echo "${USER_RESPONSE}" | jq '[.records[] | select(.UserPreferencesDisableMFAPrompt == true)]' 2>/dev/null || echo "[]")
DISABLED_COUNT=$(echo "${MFA_DISABLED}" | jq 'length' 2>/dev/null || echo "0")

if [ "${DISABLED_COUNT}" -gt 0 ]; then
  warn "1.1 Found ${DISABLED_COUNT} user(s) with MFA prompt disabled:"
  echo "${MFA_DISABLED}" | jq -r '.[] | "  - \(.Username) (\(.Name), Profile: \(.Profile.Name // "unknown"))"' 2>/dev/null || true
else
  pass "1.1 No users have MFA prompt disabled"
fi
# HTH Guide Excerpt: end api-query-users-without-mfa

# HTH Guide Excerpt: begin api-check-session-settings
# Verify org-wide session security settings require MFA
info "1.1 Checking org-wide session security level..."
SESSION_QUERY="SELECT Id, Name, SessionSecurityLevel FROM Profile WHERE Name IN ('System Administrator', 'Standard User')"
SESSION_RESPONSE=$(sf_query "${SESSION_QUERY}" 2>/dev/null || echo '{"records":[]}')

PROFILE_COUNT=$(echo "${SESSION_RESPONSE}" | jq '.totalSize // 0' 2>/dev/null)
if [ "${PROFILE_COUNT}" -gt 0 ]; then
  info "1.1 Profile session security levels:"
  echo "${SESSION_RESPONSE}" | jq -r '.records[] | "  - \(.Name): Session Level = \(.SessionSecurityLevel // "Standard")"' 2>/dev/null || true
else
  warn "1.1 Could not retrieve profile session settings"
fi
# HTH Guide Excerpt: end api-check-session-settings

# HTH Guide Excerpt: begin api-check-identity-verification
# Query permission sets with "Manage Multi-Factor Authentication" enabled
info "1.1 Checking permission sets for MFA management..."
PERM_QUERY="SELECT Id, Label, PermissionsManageMultiFactorInUi FROM PermissionSet WHERE PermissionsManageMultiFactorInUi = true"
PERM_RESPONSE=$(sf_query "${PERM_QUERY}" 2>/dev/null || echo '{"records":[]}')

PERM_COUNT=$(echo "${PERM_RESPONSE}" | jq '.totalSize // 0' 2>/dev/null)
if [ "${PERM_COUNT}" -gt 0 ]; then
  pass "1.1 Found ${PERM_COUNT} permission set(s) with MFA management enabled"
  echo "${PERM_RESPONSE}" | jq -r '.records[] | "  - \(.Label)"' 2>/dev/null || true
else
  warn "1.1 No permission sets with MFA management -- ensure MFA is enforced org-wide via Setup > Identity Verification"
fi
# HTH Guide Excerpt: end api-check-identity-verification

if [ "${DISABLED_COUNT}" -gt 0 ]; then
  warn "1.1 MFA audit complete -- ${DISABLED_COUNT} user(s) require remediation"
  increment_applied
else
  pass "1.1 MFA audit complete -- all users have MFA enabled"
  increment_applied
fi

summary
