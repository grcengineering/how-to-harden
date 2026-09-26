#!/usr/bin/env bash
# HTH Okta Control 3.3: Implement OAuth Application Allowlisting
# Profile: L2 | NIST: CM-7, AC-6
# https://howtoharden.com/guides/okta/#33-implement-oauth-application-allowlisting
#
# Read-only audit. A token owned by a Read-Only Administrator is sufficient.
source "$(dirname "$0")/common.sh"

banner "3.3: Implement OAuth Application Allowlisting"

should_apply 2 || { increment_skipped; summary; exit 0; }
info "3.3 Auditing OAuth application scopes and grants..."

# HTH Guide Excerpt: begin api-list-oauth-apps
# List all active OIDC/OAuth apps (a failed read stops the pack)
ACTIVE_APPS=$(okta_get "/api/v1/apps?filter=status%20eq%20%22ACTIVE%22&limit=200")
APP_IDS=$(printf '%s' "${ACTIVE_APPS}" | jq -r '.[] | select(.signOnMode == "OPENID_CONNECT" or .signOnMode == "OAUTH_2_0") | .id')
# HTH Guide Excerpt: end api-list-oauth-apps

if [ -z "${APP_IDS}" ]; then
  info "3.3 No active OAuth/OIDC applications (read succeeded, $(printf '%s' "${ACTIVE_APPS}" | jq 'length') active app(s) in total)"
  increment_applied
  summary
  exit 0
fi

# Check each OAuth app for overly broad scopes
flagged=0
for APP_ID in ${APP_IDS}; do
  APP_LABEL=$(printf '%s' "${ACTIVE_APPS}" | jq -r --arg id "${APP_ID}" '.[] | select(.id == $id) | .label')
  # HTH Guide Excerpt: begin api-check-app-grants
  GRANTS=$(okta_get "/api/v1/apps/${APP_ID}/grants")
  BROAD_SCOPES=$(printf '%s' "${GRANTS}" | jq -r '.[] | select(.scopeId | test("manage|write"; "i")) | .scopeId')
  # HTH Guide Excerpt: end api-check-app-grants

  if [ -n "${BROAD_SCOPES}" ]; then
    warn "3.3 App '${APP_LABEL}' (${APP_ID}) has broad scopes: ${BROAD_SCOPES}"
    flagged=$((flagged + 1))
  fi
done

if [ "${flagged}" -gt 0 ]; then
  warn "3.3 Found ${flagged} application(s) with broad OAuth scopes -- review and restrict"
else
  pass "3.3 No applications with overly broad OAuth scopes detected"
fi

# HTH Guide Excerpt: begin api-list-auth-server-clients
# List OAuth clients on default authorization server
info "3.3 Auditing default authorization server clients..."
okta_get "/api/v1/authorizationServers/default/clients" \
  | jq -r '.[] | "  - \(.client_name // "unnamed") (ID: \(.client_id))"'
# HTH Guide Excerpt: end api-list-auth-server-clients

pass "3.3 OAuth allowlisting audit complete"
increment_applied

summary
