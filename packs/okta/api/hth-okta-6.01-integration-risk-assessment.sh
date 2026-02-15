#!/usr/bin/env bash
# HTH Okta Control 6.1: Integration Risk Assessment Matrix
# Profile: L1 | NIST: RA-3, SA-9 | SOC 2: CC3.2, CC9.2
# https://howtoharden.com/guides/okta/#61-integration-risk-assessment-matrix
source "$(dirname "$0")/common.sh"

banner "6.1: Integration Risk Assessment Matrix"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "6.1 Building integration risk assessment inventory..."

# -----------------------------------------------------------------------
# 6.1a: Fetch all active applications
# -----------------------------------------------------------------------
# HTH Guide Excerpt: begin api-list-active-apps
info "6.1 Fetching active applications..."
ACTIVE_APPS=$(okta_get "/api/v1/apps?filter=status%20eq%20%22ACTIVE%22&limit=200" 2>/dev/null || echo "[]")
TOTAL_APPS=$(echo "${ACTIVE_APPS}" | jq 'length' 2>/dev/null || echo "0")
# HTH Guide Excerpt: end api-list-active-apps

if [ "${TOTAL_APPS}" -eq 0 ]; then
  warn "6.1 No active applications found (or API token lacks apps:read scope)"
  increment_failed
  summary
  exit 0
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

summary
