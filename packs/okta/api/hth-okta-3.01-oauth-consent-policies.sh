#!/usr/bin/env bash
# HTH Okta Control 3.1: Implement OAuth App Consent Policies
# Profile: L1 | NIST: AC-6, CM-7
# https://howtoharden.com/guides/okta/#31-implement-oauth-app-consent-policies
source "$(dirname "$0")/common.sh"

banner "3.1: Implement OAuth App Consent Policies"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "3.1 Auditing OAuth app consent and active applications..."

# List all active applications with OAuth/OIDC sign-on
info "3.1 Listing active applications..."
ACTIVE_APPS=$(okta_get "/api/v1/apps?filter=status%20eq%20%22ACTIVE%22&limit=200") || {
  fail "3.1 Failed to list active applications"
  increment_failed
  summary
  exit 0
}

TOTAL_COUNT=$(echo "${ACTIVE_APPS}" | jq 'length' 2>/dev/null || echo "0")
OAUTH_APPS=$(echo "${ACTIVE_APPS}" | jq '[.[] | select(.signOnMode == "OPENID_CONNECT" or .signOnMode == "OAUTH_2_0")]' 2>/dev/null || echo "[]")
OAUTH_COUNT=$(echo "${OAUTH_APPS}" | jq 'length' 2>/dev/null || echo "0")

info "3.1 Total active apps: ${TOTAL_COUNT}, OAuth/OIDC apps: ${OAUTH_COUNT}"
echo "${OAUTH_APPS}" | jq -r '.[] | "  - \(.label // .name) (mode: \(.signOnMode), created: \(.created))"' 2>/dev/null || true

# Audit OAuth token clients on default authorization server
info "3.1 Auditing OAuth clients on default authorization server..."
AUTH_CLIENTS=$(okta_get "/api/v1/authorizationServers/default/clients" 2>/dev/null || echo "[]")
CLIENT_COUNT=$(echo "${AUTH_CLIENTS}" | jq 'length' 2>/dev/null || echo "0")

if [ "${CLIENT_COUNT}" -gt 0 ]; then
  info "3.1 Found ${CLIENT_COUNT} OAuth client(s) on default auth server"
  echo "${AUTH_CLIENTS}" | jq -r '.[] | "  - \(.client_name // "unnamed") (ID: \(.client_id))"' 2>/dev/null || true
else
  info "3.1 No OAuth clients on default authorization server"
fi

pass "3.1 OAuth app audit complete -- review output for over-permissioned apps"
increment_applied

summary
