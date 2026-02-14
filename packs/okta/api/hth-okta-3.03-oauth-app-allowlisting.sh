#!/usr/bin/env bash
# HTH Okta Control 3.3: Implement OAuth Application Allowlisting
# Profile: L2 | NIST: CM-7, AC-6
# https://howtoharden.com/guides/okta/#33-implement-oauth-application-allowlisting
source "$(dirname "$0")/common.sh"

banner "3.3: Implement OAuth Application Allowlisting"

should_apply 2 || { increment_skipped; summary; exit 0; }
info "3.3 Auditing OAuth application scopes and grants..."

# List all active OIDC/OAuth apps
ACTIVE_APPS=$(okta_get "/api/v1/apps?filter=status%20eq%20%22ACTIVE%22&limit=200" 2>/dev/null || echo "[]")
APP_IDS=$(echo "${ACTIVE_APPS}" | jq -r '.[] | select(.signOnMode == "OPENID_CONNECT" or .signOnMode == "OAUTH_2_0") | .id' 2>/dev/null || true)

if [ -z "${APP_IDS}" ]; then
  info "3.3 No OAuth/OIDC applications found"
  increment_applied
  summary
  exit 0
fi

# Check each OAuth app for overly broad scopes
flagged=0
for APP_ID in ${APP_IDS}; do
  APP_LABEL=$(echo "${ACTIVE_APPS}" | jq -r ".[] | select(.id == \"${APP_ID}\") | .label" 2>/dev/null || echo "unknown")
  GRANTS=$(okta_get "/api/v1/apps/${APP_ID}/grants" 2>/dev/null || echo "[]")
  BROAD_SCOPES=$(echo "${GRANTS}" | jq -r '.[] | select(.scopeId | test("manage|write"; "i")) | .scopeId' 2>/dev/null || true)

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

# List OAuth clients on default authorization server
info "3.3 Auditing default authorization server clients..."
okta_get "/api/v1/authorizationServers/default/clients" 2>/dev/null \
  | jq -r '.[] | "  - \(.client_name // "unnamed") (ID: \(.client_id))"' 2>/dev/null || true

pass "3.3 OAuth allowlisting audit complete"
increment_applied

summary
