#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: okta-1.7
#   guide:   https://howtoharden.com/guides/okta/#17-configure-pivcac-smart-card-authentication
#   profile: L3
#   mode:    read-only
#   requires: OKTA_DOMAIN, OKTA_API_TOKEN(SSWS token owned by a Read-only Administrator), HTH_PROFILE_LEVEL(optional)
# HTH Okta Control 1.7: Configure PIV/CAC Smart Card Authentication
# Profile: L3 | NIST: IA-2(12) | DISA STIG: V-273204, V-273207
# https://howtoharden.com/guides/okta/#17-configure-pivcac-smart-card-authentication
#
# Read-only audit. A token owned by a Read-Only Administrator is sufficient.
# A Smart Card IdP is an identity provider of type "X509" (Okta Management API,
# IdentityProviderType); the matching authenticator has key "smart_card_idp".
source "$(dirname "$0")/common.sh"

banner "1.7: Configure PIV/CAC Smart Card Authentication"

should_apply 3 || { increment_skipped; summary; exit 0; }
info "1.7 Auditing Smart Card (PIV/CAC) configuration..."

# HTH Guide Excerpt: begin api-check-smart-card-idp
# Smart Card identity providers (a failed read stops the pack)
SMART_CARD_IDPS=$(okta_get "/api/v1/idps?type=X509" | jq -c '[.[] | select(.type == "X509")]')
IDP_COUNT=$(printf '%s' "${SMART_CARD_IDPS}" | jq 'length')
ACTIVE_IDPS=$(printf '%s' "${SMART_CARD_IDPS}" | jq '[.[] | select(.status == "ACTIVE")] | length')
printf '%s' "${SMART_CARD_IDPS}" | jq -r '.[] | "  - \(.name) (status: \(.status), created: \(.created))"'

# Smart Card authenticator, which points at a Smart Card IdP
SMART_CARD_AUTH=$(okta_get "/api/v1/authenticators" \
  | jq -r '[.[] | select(.key == "smart_card_idp")][0].status // "ABSENT"')
# HTH Guide Excerpt: end api-check-smart-card-idp

info "1.7 Smart Card IdPs: ${IDP_COUNT} (${ACTIVE_IDPS} active); Smart Card Authenticator: ${SMART_CARD_AUTH}"

if [ "${ACTIVE_IDPS}" -gt 0 ] && [ "${SMART_CARD_AUTH}" = "ACTIVE" ]; then
  pass "1.7 PIV/CAC smart card authentication is configured and active"
else
  warn "1.7 PIV/CAC smart card authentication is not fully configured -- see Section 1.7 ClickOps steps"
fi
increment_applied

summary
