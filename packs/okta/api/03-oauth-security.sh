#!/usr/bin/env bash
# HTH Okta Code Pack -- Section 3: OAuth & Integration Security
# Controls: 3.1, 3.3, 3.4
# https://howtoharden.com/guides/okta/#3-oauth--integration-security
source "$(dirname "$0")/common.sh"

banner "Section 3: OAuth & Integration Security"

# ===========================================================================
# 3.1 Implement OAuth App Consent Policies
# Profile: L1 | NIST: AC-6, CM-7
# ===========================================================================
control_3_1() {
  should_apply 1 || { increment_skipped; return 0; }
  info "3.1 Auditing OAuth app consent and active applications..."

  # List all active applications with OAuth/OIDC sign-on
  info "3.1 Listing active applications..."
  ACTIVE_APPS=$(okta_get "/api/v1/apps?filter=status%20eq%20%22ACTIVE%22&limit=200") || {
    fail "3.1 Failed to list active applications"
    increment_failed
    return 0
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
}

# ===========================================================================
# 3.3 Implement OAuth Application Allowlisting
# Profile: L2 | NIST: CM-7, AC-6
# ===========================================================================
control_3_3() {
  should_apply 2 || { increment_skipped; return 0; }
  info "3.3 Auditing OAuth application scopes and grants..."

  # List all active OIDC/OAuth apps
  ACTIVE_APPS=$(okta_get "/api/v1/apps?filter=status%20eq%20%22ACTIVE%22&limit=200" 2>/dev/null || echo "[]")
  APP_IDS=$(echo "${ACTIVE_APPS}" | jq -r '.[] | select(.signOnMode == "OPENID_CONNECT" or .signOnMode == "OAUTH_2_0") | .id' 2>/dev/null || true)

  if [ -z "${APP_IDS}" ]; then
    info "3.3 No OAuth/OIDC applications found"
    increment_applied
    return 0
  fi

  # Check each OAuth app for overly broad scopes
  local flagged=0
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
}

# ===========================================================================
# 3.4 Govern Non-Human Identities (NHI)
# Profile: L1 | NIST: IA-4, IA-5, AC-2
# ===========================================================================
control_3_4() {
  should_apply 1 || { increment_skipped; return 0; }
  info "3.4 Auditing non-human identities (API tokens and service apps)..."

  # List all active API tokens
  info "3.4 Listing all active API tokens..."
  API_TOKENS=$(okta_get "/api/v1/api-tokens" 2>/dev/null || echo "[]")
  TOKEN_COUNT=$(echo "${API_TOKENS}" | jq 'length' 2>/dev/null || echo "0")

  info "3.4 Found ${TOKEN_COUNT} API token(s)"
  echo "${API_TOKENS}" | jq -r '.[] | "  - \(.name) (created: \(.created), user: \(.userId), network: \(.network.connection // "unrestricted"))"' 2>/dev/null || true

  # Flag tokens without network restrictions
  UNRESTRICTED=$(echo "${API_TOKENS}" | jq '[.[] | select(.network == null or .network.connection == "ANYWHERE")] | length' 2>/dev/null || echo "0")
  if [ "${UNRESTRICTED}" -gt 0 ]; then
    warn "3.4 ${UNRESTRICTED} API token(s) have no network restrictions -- add IP restrictions"
  fi

  # Flag old tokens (created more than 90 days ago)
  info "3.4 Checking for stale API tokens (>90 days)..."
  NINETY_DAYS_AGO=$(date -d '90 days ago' -u +%Y-%m-%dT%H:%M:%S.000Z 2>/dev/null \
    || date -v-90d -u +%Y-%m-%dT%H:%M:%S.000Z 2>/dev/null || echo "")

  if [ -n "${NINETY_DAYS_AGO}" ]; then
    STALE_TOKENS=$(echo "${API_TOKENS}" | jq --arg cutoff "${NINETY_DAYS_AGO}" \
      '[.[] | select(.created < $cutoff)] | length' 2>/dev/null || echo "0")
    if [ "${STALE_TOKENS}" -gt 0 ]; then
      warn "3.4 ${STALE_TOKENS} API token(s) are older than 90 days -- consider rotation"
    else
      info "3.4 All tokens are less than 90 days old"
    fi
  fi

  # List service applications (OAuth client_credentials)
  info "3.4 Listing OAuth service applications..."
  SERVICE_APPS=$(okta_get "/api/v1/apps?filter=status%20eq%20%22ACTIVE%22&limit=200" 2>/dev/null \
    | jq '[.[] | select(.settings.oauthClient.grant_types? // [] | index("client_credentials"))]' 2>/dev/null || echo "[]")
  SVC_COUNT=$(echo "${SERVICE_APPS}" | jq 'length' 2>/dev/null || echo "0")

  info "3.4 Found ${SVC_COUNT} OAuth service application(s)"
  if [ "${SVC_COUNT}" -gt 0 ]; then
    echo "${SERVICE_APPS}" | jq -r '.[] | "  - \(.label) (ID: \(.id))"' 2>/dev/null || true
  fi

  pass "3.4 NHI audit complete -- review tokens and service apps above"
  increment_applied
}

# ===========================================================================
# Execute all controls
# ===========================================================================
control_3_1
control_3_3
control_3_4

summary
