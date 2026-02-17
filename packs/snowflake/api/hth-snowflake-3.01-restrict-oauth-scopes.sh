#!/usr/bin/env bash
# HTH Snowflake Control 3.1: Restrict OAuth Token Scope and Lifetime
# Profile: L1 | NIST: IA-5(13)
# https://howtoharden.com/guides/snowflake/#31-restrict-oauth-token-scope-and-lifetime
source "$(dirname "$0")/common.sh"

banner "3.1: Restrict OAuth Token Scope and Lifetime"

should_apply 1 || { increment_skipped; summary; exit 0; }

# HTH Guide Excerpt: begin audit-security-integrations
# Audit all security integrations for OAuth scope and lifetime
info "3.1 Auditing security integrations..."
INTEGRATIONS=$(snow_query "SHOW SECURITY INTEGRATIONS;") || {
  warn "3.1 No security integrations found or query failed"
  INTEGRATIONS="[]"
}

OAUTH_COUNT=$(echo "${INTEGRATIONS}" | jq '[.[] | select(.type == "OAUTH - SNOWFLAKE" or .type == "OAUTH - CUSTOM" or .type == "OAUTH - EXTERNAL")] | length' 2>/dev/null || echo "0")

if [ "${OAUTH_COUNT}" -gt 0 ]; then
  info "3.1 Found ${OAUTH_COUNT} OAuth integration(s):"
  echo "${INTEGRATIONS}" | jq -r '.[] | select(.type | test("OAUTH")) | "  - \(.name) [\(.type)] enabled=\(.enabled)"' 2>/dev/null || true
else
  info "3.1 No OAuth integrations found"
fi
# HTH Guide Excerpt: end audit-security-integrations

# HTH Guide Excerpt: begin check-blocked-roles
# Verify all OAuth integrations block privileged roles
info "3.1 Checking OAuth integrations for blocked role lists..."
INTEGRATION_NAMES=$(echo "${INTEGRATIONS}" | jq -r '.[] | select(.type | test("OAUTH")) | .name' 2>/dev/null || true)

ISSUES_FOUND=0
while IFS= read -r int_name; do
  [ -z "${int_name}" ] && continue
  DETAIL=$(snow_query "DESCRIBE SECURITY INTEGRATION \"${int_name}\";") || {
    warn "3.1 Could not describe integration: ${int_name}"
    continue
  }

  # Check for BLOCKED_ROLES_LIST
  BLOCKED=$(echo "${DETAIL}" | jq -r '.[] | select(.property == "BLOCKED_ROLES_LIST") | .property_value' 2>/dev/null || echo "")

  if [ -z "${BLOCKED}" ] || [ "${BLOCKED}" = "ACCOUNTADMIN, SECURITYADMIN" ]; then
    # Default -- check it at minimum blocks ACCOUNTADMIN
    if echo "${BLOCKED}" | grep -q "ACCOUNTADMIN"; then
      pass "3.1 Integration ${int_name} blocks ACCOUNTADMIN"
    else
      fail "3.1 Integration ${int_name} does NOT block ACCOUNTADMIN"
      ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
  else
    info "3.1 Integration ${int_name} blocked roles: ${BLOCKED}"
  fi

  # Check token lifetime
  TOKEN_LIFETIME=$(echo "${DETAIL}" | jq -r '.[] | select(.property == "OAUTH_ACCESS_TOKEN_VALIDITY") | .property_value' 2>/dev/null || echo "")
  REFRESH_LIFETIME=$(echo "${DETAIL}" | jq -r '.[] | select(.property == "OAUTH_REFRESH_TOKEN_VALIDITY") | .property_value' 2>/dev/null || echo "")

  if [ -n "${TOKEN_LIFETIME}" ]; then
    if [ "${TOKEN_LIFETIME}" -le 600 ]; then
      pass "3.1 Integration ${int_name} access token lifetime: ${TOKEN_LIFETIME}s (<=600s)"
    else
      warn "3.1 Integration ${int_name} access token lifetime: ${TOKEN_LIFETIME}s (recommend <=600s)"
    fi
  fi
done <<< "${INTEGRATION_NAMES}"
# HTH Guide Excerpt: end check-blocked-roles

if [ "${ISSUES_FOUND}" -gt 0 ]; then
  fail "3.1 Found ${ISSUES_FOUND} OAuth integration(s) without ACCOUNTADMIN in blocked roles"
  increment_failed
else
  pass "3.1 All OAuth integrations properly restrict privileged roles"
  increment_applied
fi

summary
