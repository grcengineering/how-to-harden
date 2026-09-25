#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: okta-3.5
#   guide:   https://howtoharden.com/guides/okta/#35-authorize-ai-agents-and-mcp-servers-with-cross-app-access-xaa
#   profile: L2
#   mode:    read-only
#   requires: OKTA_DOMAIN, OKTA_API_TOKEN(SSWS token owned by a Read-only Administrator), HTH_PROFILE_LEVEL(optional)
# HTH Okta Control 3.5: Authorize AI Agents and MCP Servers with Cross App Access (XAA)
# Profile: L2 | NIST: AC-3, AC-6, IA-4, IA-5, AU-2
# https://howtoharden.com/guides/okta/#35-authorize-ai-agents-and-mcp-servers-with-cross-app-access-xaa
#
# Read-only audit. A token owned by a Read-Only Administrator is sufficient.
# 1) Service apps (client_credentials) that authenticate with a shared client
#    secret instead of private_key_jwt.
# 2) Cross App Access connections per OIDC app:
#    GET /api/v1/apps/{appId}/cwo/connections (Okta Management API,
#    ApplicationCrossAppAccessConnections).
source "$(dirname "$0")/common.sh"

banner "3.5: Authorize AI Agents and MCP Servers with Cross App Access (XAA)"

should_apply 2 || { increment_skipped; summary; exit 0; }
info "3.5 Auditing agent credentials and Cross App Access connections..."

# A failed read stops the pack
ACTIVE_APPS=$(okta_get "/api/v1/apps?filter=status%20eq%20%22ACTIVE%22&limit=200")

# HTH Guide Excerpt: begin api-check-agent-client-auth
# Service apps holding a shared secret rather than a private key
SECRET_CLIENTS=$(printf '%s' "${ACTIVE_APPS}" | jq -r '.[]
  | select(((.settings.oauthClient.grant_types? // []) | index("client_credentials")) != null)
  | select(.credentials.oauthClient.token_endpoint_auth_method != "private_key_jwt")
  | "  - \(.label) (ID: \(.id), client auth: \(.credentials.oauthClient.token_endpoint_auth_method))"')
# HTH Guide Excerpt: end api-check-agent-client-auth

if [ -n "${SECRET_CLIENTS}" ]; then
  warn "3.5 Service apps authenticating with a shared client secret (move them to private_key_jwt):"
  echo "${SECRET_CLIENTS}"
else
  pass "3.5 No service app authenticates with a shared client secret"
fi

# HTH Guide Excerpt: begin api-list-xaa-connections
# Cross App Access connections for each OIDC app integration that has its own
# OAuth client (Okta's built-in first-party apps have no credentials.oauthClient
# and the connections endpoint rejects them)
CONNECTIONS=0
for APP_ID in $(printf '%s' "${ACTIVE_APPS}" | jq -r '.[] | select(.signOnMode == "OPENID_CONNECT" and .credentials.oauthClient != null) | .id'); do
  APP_CONNECTIONS=$(okta_get "/api/v1/apps/${APP_ID}/cwo/connections")
  COUNT=$(printf '%s' "${APP_CONNECTIONS}" | jq 'length')
  if [ "${COUNT}" -gt 0 ]; then
    printf '%s' "${APP_CONNECTIONS}" | jq -r '.[] | "  - \(.requestingAppInstanceId) -> \(.resourceAppInstanceId) (status: \(.status))"'
    CONNECTIONS=$((CONNECTIONS + COUNT))
  fi
done
# HTH Guide Excerpt: end api-list-xaa-connections

info "3.5 Cross App Access connections found: ${CONNECTIONS} -- review each against the agent inventory"
increment_applied

summary
