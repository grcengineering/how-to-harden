#!/usr/bin/env bash
# HTH Auth0 Control 4.2: Secure Application Configurations
# Profile: L1 | NIST: CM-7 | CIS: 4.1
# https://howtoharden.com/guides/auth0/#42-secure-application-configurations
source "$(dirname "$0")/common.sh"

banner "4.2: Secure Application Configurations"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "4.2 Auditing application configurations..."

# HTH Guide Excerpt: begin api-audit-apps
# Audit application token settings and OIDC conformance
CLIENTS=$(a0_get "/clients?fields=name,client_id,app_type,oidc_conformant,jwt_configuration,refresh_token&include_fields=true") || {
  fail "4.2 Unable to retrieve applications"
  increment_failed; summary; exit 0
}

CLIENT_COUNT=$(echo "${CLIENTS}" | jq 'length')
info "4.2 Found ${CLIENT_COUNT} application(s)"

ISSUES=0
while IFS= read -r client; do
  NAME=$(echo "${client}" | jq -r '.name')
  OIDC=$(echo "${client}" | jq -r '.oidc_conformant // false')
  TOKEN_TTL=$(echo "${client}" | jq -r '.jwt_configuration.lifetime_in_seconds // 36000')
  ROTATION=$(echo "${client}" | jq -r '.refresh_token.rotation_type // "non-rotating"')

  [ "${OIDC}" != "true" ] && { warn "4.2 '${NAME}' is not OIDC conformant"; ISSUES=$((ISSUES + 1)); }
  [ "${TOKEN_TTL}" -gt 3600 ] && { warn "4.2 '${NAME}' access token TTL (${TOKEN_TTL}s) exceeds 1 hour"; ISSUES=$((ISSUES + 1)); }
  [ "${ROTATION}" != "rotating" ] && { warn "4.2 '${NAME}' refresh tokens are not rotating"; ISSUES=$((ISSUES + 1)); }
done < <(echo "${CLIENTS}" | jq -c '.[]')
# HTH Guide Excerpt: end api-audit-apps

[ "${ISSUES}" -eq 0 ] && pass "4.2 All applications pass security audit" || warn "4.2 ${ISSUES} issue(s) found -- review above"
increment_applied
summary
