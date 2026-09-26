#!/usr/bin/env bash
# HTH Okta Control 3.1: Implement OAuth App Consent Policies
# Profile: L1 | NIST: AC-6, CM-7
# https://howtoharden.com/guides/okta/#31-implement-oauth-app-consent-policies
#
# Read-only audit. A token owned by a Read-Only Administrator is sufficient.
source "$(dirname "$0")/common.sh"

banner "3.1: Implement OAuth App Consent Policies"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "3.1 Auditing OAuth app consent and active applications..."

# HTH Guide Excerpt: begin api-list-active-apps
# List all active applications with OAuth/OIDC sign-on (a failed read stops the pack)
info "3.1 Listing active applications..."
ACTIVE_APPS=$(okta_get "/api/v1/apps?filter=status%20eq%20%22ACTIVE%22&limit=200")

TOTAL_COUNT=$(printf '%s' "${ACTIVE_APPS}" | jq 'length')
OAUTH_APPS=$(printf '%s' "${ACTIVE_APPS}" | jq '[.[] | select(.signOnMode == "OPENID_CONNECT" or .signOnMode == "OAUTH_2_0")]')
OAUTH_COUNT=$(printf '%s' "${OAUTH_APPS}" | jq 'length')

info "3.1 Total active apps: ${TOTAL_COUNT}, OAuth/OIDC apps: ${OAUTH_COUNT}"
printf '%s' "${OAUTH_APPS}" | jq -r '.[] | "  - \(.label // .name) (mode: \(.signOnMode), created: \(.created))"'
# HTH Guide Excerpt: end api-list-active-apps

# HTH Guide Excerpt: begin api-list-auth-server-clients
# Audit OAuth token clients on default authorization server
info "3.1 Auditing OAuth clients on default authorization server..."
AUTH_CLIENTS=$(okta_get "/api/v1/authorizationServers/default/clients")
CLIENT_COUNT=$(printf '%s' "${AUTH_CLIENTS}" | jq 'length')

if [ "${CLIENT_COUNT}" -gt 0 ]; then
  info "3.1 Found ${CLIENT_COUNT} OAuth client(s) on default auth server"
  printf '%s' "${AUTH_CLIENTS}" | jq -r '.[] | "  - \(.client_name // "unnamed") (ID: \(.client_id))"'
else
  info "3.1 No OAuth clients hold tokens from the default authorization server"
fi
# HTH Guide Excerpt: end api-list-auth-server-clients

pass "3.1 OAuth app audit complete -- review output for over-permissioned apps"
increment_applied

summary
