#!/usr/bin/env bash
# HTH Okta Code Pack -- Section 6: Third-Party Integration Security
# Controls: 6.1, 6.2 (audit/inventory -- no destructive changes)
# https://howtoharden.com/guides/okta/#6-third-party-integration-security
source "$(dirname "$0")/common.sh"

banner "Section 6: Third-Party Integration Security"

# ===========================================================================
# 6.1 Integration Risk Assessment Matrix
# Profile: L1 | NIST: RA-3, SA-9 | SOC 2: CC3.2, CC9.2
# ===========================================================================
control_6_1() {
  should_apply 1 || { increment_skipped; return 0; }
  info "6.1 Building integration risk assessment inventory..."

  # -----------------------------------------------------------------------
  # 6.1a: Fetch all active applications
  # -----------------------------------------------------------------------
  info "6.1 Fetching active applications..."
  ACTIVE_APPS=$(okta_get "/api/v1/apps?filter=status%20eq%20%22ACTIVE%22&limit=200" 2>/dev/null || echo "[]")
  TOTAL_APPS=$(echo "${ACTIVE_APPS}" | jq 'length' 2>/dev/null || echo "0")

  if [ "${TOTAL_APPS}" -eq 0 ]; then
    warn "6.1 No active applications found (or API token lacks apps:read scope)"
    increment_failed
    return 0
  fi

  info "6.1 Total active applications: ${TOTAL_APPS}"

  # -----------------------------------------------------------------------
  # 6.1b: Categorize by integration type (signOnMode)
  # -----------------------------------------------------------------------
  info "6.1 Categorizing applications by sign-on mode..."

  SAML_COUNT=$(echo "${ACTIVE_APPS}" | jq '[.[] | select(.signOnMode == "SAML_2_0")] | length' 2>/dev/null || echo "0")
  OIDC_COUNT=$(echo "${ACTIVE_APPS}" | jq '[.[] | select(.signOnMode == "OPENID_CONNECT")] | length' 2>/dev/null || echo "0")
  BOOKMARK_COUNT=$(echo "${ACTIVE_APPS}" | jq '[.[] | select(.signOnMode == "BOOKMARK")] | length' 2>/dev/null || echo "0")
  SWA_COUNT=$(echo "${ACTIVE_APPS}" | jq '[.[] | select(.signOnMode | test("BROWSER_PLUGIN"; "i"))] | length' 2>/dev/null || echo "0")
  WS_FED_COUNT=$(echo "${ACTIVE_APPS}" | jq '[.[] | select(.signOnMode == "WS_FEDERATION")] | length' 2>/dev/null || echo "0")
  OTHER_COUNT=$(echo "${ACTIVE_APPS}" | jq '[.[] | select(.signOnMode != "SAML_2_0" and .signOnMode != "OPENID_CONNECT" and .signOnMode != "BOOKMARK" and (.signOnMode | test("BROWSER_PLUGIN"; "i") | not) and .signOnMode != "WS_FEDERATION")] | length' 2>/dev/null || echo "0")

  echo ""
  info "6.1 Integration Type Summary:"
  info "  SAML 2.0:          ${SAML_COUNT}"
  info "  OpenID Connect:    ${OIDC_COUNT}"
  info "  Bookmark:          ${BOOKMARK_COUNT}"
  info "  SWA/Browser Plug:  ${SWA_COUNT}"
  info "  WS-Federation:     ${WS_FED_COUNT}"
  info "  Other:             ${OTHER_COUNT}"
  echo ""

  # -----------------------------------------------------------------------
  # 6.1c: List all apps with their sign-on modes
  # -----------------------------------------------------------------------
  info "6.1 Full application inventory:"
  echo "${ACTIVE_APPS}" | jq -r \
    '.[] | "  - \(.label // .name) (mode: \(.signOnMode), created: \(.created))"' \
    2>/dev/null || true

  # -----------------------------------------------------------------------
  # 6.1d: Flag provisioning-enabled apps (higher risk -- SCIM/lifecycle)
  # -----------------------------------------------------------------------
  echo ""
  info "6.1 Checking for provisioning-enabled applications (SCIM/lifecycle)..."

  PROVISIONING_APPS=$(echo "${ACTIVE_APPS}" | jq '[.[] | select(
    .settings.provisioning != null or
    .features != null and (.features | index("PUSH_NEW_USERS") or index("PUSH_USER_DEACTIVATION") or index("IMPORT_NEW_USERS") or index("PUSH_PROFILE_UPDATES"))
  )]' 2>/dev/null || echo "[]")
  PROV_COUNT=$(echo "${PROVISIONING_APPS}" | jq 'length' 2>/dev/null || echo "0")

  if [ "${PROV_COUNT}" -gt 0 ]; then
    warn "6.1 Found ${PROV_COUNT} app(s) with provisioning features enabled (higher risk):"
    echo "${PROVISIONING_APPS}" | jq -r \
      '.[] | "  - \(.label // .name) (mode: \(.signOnMode), features: \(.features // [] | join(", ")))"' \
      2>/dev/null || true
    echo ""
    info "6.1 Provisioning-enabled apps can create/modify/deactivate users -- review quarterly"
  else
    pass "6.1 No provisioning-enabled applications detected in first 200 apps"
  fi

  # -----------------------------------------------------------------------
  # 6.1e: Flag SWA/Bookmark apps (weaker security model)
  # -----------------------------------------------------------------------
  WEAK_COUNT=$((BOOKMARK_COUNT + SWA_COUNT))
  if [ "${WEAK_COUNT}" -gt 0 ]; then
    warn "6.1 Found ${WEAK_COUNT} Bookmark/SWA app(s) -- consider upgrading to SAML or OIDC:"
    echo "${ACTIVE_APPS}" | jq -r \
      '.[] | select(.signOnMode == "BOOKMARK" or (.signOnMode | test("BROWSER_PLUGIN"; "i"))) | "  - \(.label // .name) (mode: \(.signOnMode))"' \
      2>/dev/null || true
  fi

  # -----------------------------------------------------------------------
  # 6.1f: Risk summary
  # -----------------------------------------------------------------------
  echo ""
  info "6.1 Risk Assessment Summary:"
  info "  Total active apps:      ${TOTAL_APPS}"
  info "  Federated (SAML/OIDC):  $((SAML_COUNT + OIDC_COUNT))"
  info "  Provisioning-enabled:   ${PROV_COUNT}"
  info "  Weak auth (SWA/BM):     ${WEAK_COUNT}"
  echo ""
  info "6.1 Review Checklist:"
  info "  [ ] All high-risk integrations have documented risk acceptance"
  info "  [ ] Provisioning-enabled apps reviewed for least-privilege attributes"
  info "  [ ] Bookmark/SWA apps evaluated for SAML/OIDC migration"
  info "  [ ] Integration inventory matches approved vendor list"

  pass "6.1 Integration risk assessment inventory complete"
  increment_applied
}

# ===========================================================================
# 6.2 Common Integrations and Recommended Controls
# Profile: L1 | NIST: SA-9, AC-4 | SOC 2: CC6.1, CC6.3
# ===========================================================================
control_6_2() {
  should_apply 1 || { increment_skipped; return 0; }
  info "6.2 Auditing OAuth/OIDC integration security..."

  # -----------------------------------------------------------------------
  # 6.2a: List all OAuth/OIDC applications
  # -----------------------------------------------------------------------
  info "6.2 Fetching active OAuth/OIDC applications..."
  ACTIVE_APPS=$(okta_get "/api/v1/apps?filter=status%20eq%20%22ACTIVE%22&limit=200" 2>/dev/null || echo "[]")
  OAUTH_APPS=$(echo "${ACTIVE_APPS}" | jq '[.[] | select(.signOnMode == "OPENID_CONNECT" or .signOnMode == "OAUTH_2_0")]' 2>/dev/null || echo "[]")
  OAUTH_COUNT=$(echo "${OAUTH_APPS}" | jq 'length' 2>/dev/null || echo "0")

  if [ "${OAUTH_COUNT}" -eq 0 ]; then
    info "6.2 No OAuth/OIDC applications found"
    pass "6.2 No OAuth apps to audit"
    increment_applied
    return 0
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
  local flagged_count=0
  local admin_scope_count=0

  APP_IDS=$(echo "${OAUTH_APPS}" | jq -r '.[].id' 2>/dev/null || true)

  if [ -z "${APP_IDS}" ]; then
    info "6.2 No OAuth app IDs to audit"
    pass "6.2 OAuth scope audit complete"
    increment_applied
    return 0
  fi

  for APP_ID in ${APP_IDS}; do
    APP_LABEL=$(echo "${OAUTH_APPS}" | jq -r ".[] | select(.id == \"${APP_ID}\") | .label // .name" 2>/dev/null || echo "unknown")

    # Fetch grants for this application
    GRANTS=$(okta_get "/api/v1/apps/${APP_ID}/grants" 2>/dev/null || echo "[]")
    GRANT_COUNT=$(echo "${GRANTS}" | jq 'length' 2>/dev/null || echo "0")

    if [ "${GRANT_COUNT}" -eq 0 ]; then
      info "6.2   ${APP_LABEL}: no explicit scope grants"
      continue
    fi

    # Extract all granted scope IDs
    SCOPE_LIST=$(echo "${GRANTS}" | jq -r '.[].scopeId // empty' 2>/dev/null || true)

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
}

# ===========================================================================
# Execute all controls
# ===========================================================================
control_6_1
control_6_2

summary
