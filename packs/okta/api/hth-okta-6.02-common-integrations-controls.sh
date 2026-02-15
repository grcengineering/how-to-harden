#!/usr/bin/env bash
# HTH Okta Control 6.2: Common Integrations and Recommended Controls
# Profile: L1 | NIST: SA-9, AC-4 | SOC 2: CC6.1, CC6.3
# https://howtoharden.com/guides/okta/#62-common-integrations-and-recommended-controls
source "$(dirname "$0")/common.sh"

banner "6.2: Common Integrations and Recommended Controls"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "6.2 Auditing OAuth/OIDC integration security..."

# -----------------------------------------------------------------------
# 6.2a: List all OAuth/OIDC applications
# -----------------------------------------------------------------------
# HTH Guide Excerpt: begin api-list-oauth-apps
info "6.2 Fetching active OAuth/OIDC applications..."
ACTIVE_APPS=$(okta_get "/api/v1/apps?filter=status%20eq%20%22ACTIVE%22&limit=200" 2>/dev/null || echo "[]")
OAUTH_APPS=$(echo "${ACTIVE_APPS}" | jq '[.[] | select(.signOnMode == "OPENID_CONNECT" or .signOnMode == "OAUTH_2_0")]' 2>/dev/null || echo "[]")
OAUTH_COUNT=$(echo "${OAUTH_APPS}" | jq 'length' 2>/dev/null || echo "0")
# HTH Guide Excerpt: end api-list-oauth-apps

if [ "${OAUTH_COUNT}" -eq 0 ]; then
  info "6.2 No OAuth/OIDC applications found"
  pass "6.2 No OAuth apps to audit"
  increment_applied
  summary
  exit 0
fi

info "6.2 Found ${OAUTH_COUNT} OAuth/OIDC application(s)"

# -----------------------------------------------------------------------
# 6.2b: Check for client_credentials grant type (service/machine apps)
# -----------------------------------------------------------------------
info "6.2 Identifying service applications (client_credentials grant type)..."
SERVICE_APPS=$(echo "${OAUTH_APPS}" | jq '[.[] | select(
  .settings.oauthClient.grant_types != null and
  (.settings.oauthClient.grant_types | index("client_credentials"))
)]' 2>/dev/null || echo "[]")
SVC_COUNT=$(echo "${SERVICE_APPS}" | jq 'length' 2>/dev/null || echo "0")

if [ "${SVC_COUNT}" -gt 0 ]; then
  warn "6.2 Found ${SVC_COUNT} service app(s) using client_credentials grant (machine-to-machine):"
  echo "${SERVICE_APPS}" | jq -r \
    '.[] | "  - \(.label // .name) (ID: \(.id), grant_types: \(.settings.oauthClient.grant_types | join(", ")))"' \
    2>/dev/null || true
  echo ""
  info "6.2 Service apps operate without user context -- ensure scopes are minimal"
else
  pass "6.2 No client_credentials (service) apps detected"
fi

# -----------------------------------------------------------------------
# 6.2c: Audit granted scopes per OAuth app
# -----------------------------------------------------------------------
info "6.2 Auditing OAuth scope grants per application..."
flagged_count=0
admin_scope_count=0

APP_IDS=$(echo "${OAUTH_APPS}" | jq -r '.[].id' 2>/dev/null || true)

if [ -z "${APP_IDS}" ]; then
  info "6.2 No OAuth app IDs to audit"
  pass "6.2 OAuth scope audit complete"
  increment_applied
  summary
  exit 0
fi

for APP_ID in ${APP_IDS}; do
  APP_LABEL=$(echo "${OAUTH_APPS}" | jq -r ".[] | select(.id == \"${APP_ID}\") | .label // .name" 2>/dev/null || echo "unknown")

  # HTH Guide Excerpt: begin api-check-app-grants
  # Fetch grants for this application
  GRANTS=$(okta_get "/api/v1/apps/${APP_ID}/grants" 2>/dev/null || echo "[]")
  GRANT_COUNT=$(echo "${GRANTS}" | jq 'length' 2>/dev/null || echo "0")

  if [ "${GRANT_COUNT}" -eq 0 ]; then
    info "6.2   ${APP_LABEL}: no explicit scope grants"
    continue
  fi

  # Extract all granted scope IDs
  SCOPE_LIST=$(echo "${GRANTS}" | jq -r '.[].scopeId // empty' 2>/dev/null || true)
  # HTH Guide Excerpt: end api-check-app-grants

  info "6.2   ${APP_LABEL} (${GRANT_COUNT} grant(s)):"
  echo "${GRANTS}" | jq -r \
    '.[] | "      scope: \(.scopeId // "unknown") (status: \(.status // "unknown"))"' \
    2>/dev/null || true

  # Flag admin-level scopes (okta.*, manage, write patterns)
  ADMIN_SCOPES=$(echo "${GRANTS}" | jq -r \
    '[.[] | select(.scopeId | test("okta\\.(apps|users|groups|logs|roles)\\.(manage|read)"; "i") or test("admin"; "i"))] | length' \
    2>/dev/null || echo "0")

  if [ "${ADMIN_SCOPES}" -gt 0 ]; then
    warn "6.2   ALERT: '${APP_LABEL}' has ${ADMIN_SCOPES} admin-level scope grant(s) -- review for least privilege"
    admin_scope_count=$((admin_scope_count + ADMIN_SCOPES))
    flagged_count=$((flagged_count + 1))
  fi

  # Flag broad write/manage scopes
  BROAD_SCOPES=$(echo "${GRANTS}" | jq -r \
    '[.[] | select(.scopeId | test("manage|write"; "i"))] | length' \
    2>/dev/null || echo "0")

  if [ "${BROAD_SCOPES}" -gt 0 ] && [ "${ADMIN_SCOPES}" -eq 0 ]; then
    warn "6.2   '${APP_LABEL}' has ${BROAD_SCOPES} write/manage scope(s) -- verify necessity"
    flagged_count=$((flagged_count + 1))
  fi
done

# -----------------------------------------------------------------------
# 6.2d: Audit OAuth clients on authorization servers
# -----------------------------------------------------------------------
echo ""
info "6.2 Auditing OAuth clients on authorization servers..."

# HTH Guide Excerpt: begin api-list-auth-server-clients
# Check default authorization server
AUTH_CLIENTS=$(okta_get "/api/v1/authorizationServers/default/clients" 2>/dev/null || echo "[]")
DEFAULT_CLIENT_COUNT=$(echo "${AUTH_CLIENTS}" | jq 'length' 2>/dev/null || echo "0")

if [ "${DEFAULT_CLIENT_COUNT}" -gt 0 ]; then
  info "6.2 Default auth server has ${DEFAULT_CLIENT_COUNT} registered client(s):"
  echo "${AUTH_CLIENTS}" | jq -r \
    '.[] | "  - \(.client_name // "unnamed") (ID: \(.client_id))"' \
    2>/dev/null || true
else
  info "6.2 No clients registered on default authorization server"
fi
# HTH Guide Excerpt: end api-list-auth-server-clients

# HTH Guide Excerpt: begin api-list-auth-servers
# List all custom authorization servers
AUTH_SERVERS=$(okta_get "/api/v1/authorizationServers" 2>/dev/null || echo "[]")
CUSTOM_SERVERS=$(echo "${AUTH_SERVERS}" | jq '[.[] | select(.name != "default")]' 2>/dev/null || echo "[]")
CUSTOM_COUNT=$(echo "${CUSTOM_SERVERS}" | jq 'length' 2>/dev/null || echo "0")

if [ "${CUSTOM_COUNT}" -gt 0 ]; then
  info "6.2 Found ${CUSTOM_COUNT} custom authorization server(s):"
  echo "${CUSTOM_SERVERS}" | jq -r \
    '.[] | "  - \(.name) (ID: \(.id), audiences: \(.audiences // [] | join(", ")))"' \
    2>/dev/null || true
fi
# HTH Guide Excerpt: end api-list-auth-servers

# -----------------------------------------------------------------------
# 6.2e: Summary and recommendations
# -----------------------------------------------------------------------
echo ""
info "6.2 Integration Security Audit Summary:"
info "  OAuth/OIDC applications:         ${OAUTH_COUNT}"
info "  Service apps (client_creds):     ${SVC_COUNT}"
info "  Apps with admin scopes:          ${flagged_count}"
info "  Total admin scope grants:        ${admin_scope_count}"
info "  Auth server clients (default):   ${DEFAULT_CLIENT_COUNT}"
info "  Custom authorization servers:    ${CUSTOM_COUNT}"
echo ""
info "6.2 Review Checklist:"
info "  [ ] All client_credentials apps have documented business justification"
info "  [ ] Admin-scoped apps verified for least-privilege access"
info "  [ ] OAuth scopes reviewed quarterly and excess grants revoked"
info "  [ ] Custom auth server audiences match intended applications"
info "  [ ] SCIM token rotation scheduled for provisioning apps"

if [ "${flagged_count}" -gt 0 ]; then
  warn "6.2 ${flagged_count} application(s) flagged for excessive scope grants -- review immediately"
else
  pass "6.2 No applications with excessive admin scopes detected"
fi

pass "6.2 Integration security audit complete"
increment_applied

summary
