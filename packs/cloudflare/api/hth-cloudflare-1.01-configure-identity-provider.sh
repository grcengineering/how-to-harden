#!/usr/bin/env bash
# HTH Cloudflare Control 1.1: Configure Identity Provider Integration
# Profile: L1 | NIST: IA-2, IA-8 | CIS: 6.3, 12.5
# https://howtoharden.com/guides/cloudflare/#11-configure-identity-provider-integration
#
# Read-only by default: it lists the configured identity providers and passes
# only when at least one is a corporate IdP. One-time PIN, the Cloudflare
# identity provider (added automatically to new organizations), and the social
# providers (Facebook, GitHub, consumer Google, LinkedIn, Yandex) do not count:
# none of them is an identity your organization manages. When no corporate IdP
# exists it reports the OIDC provider it would add; the write happens only with
# HTH_APPLY=1, and it adds a provider without removing any existing login
# method. Adding an IdP changes how users sign in to Access -- run it against a
# test account first, and keep an existing login method in place until the new
# provider passes the dashboard's Test button.
# Token permission: Access: Organizations, Identity Providers, and Groups Read.
source "$(dirname "$0")/common.sh"

banner "1.1: Configure Identity Provider Integration"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.1 Checking identity provider configuration..."

# Corporate identity provider types, from the IdentityProviderType enum
# (developers.cloudflare.com/api/resources/zero_trust/subresources/identity_providers/).
# An allowlist, so a type added to the enum later is not counted until reviewed.
CORPORATE_IDP_TYPES='["azureAD","saml","centrify","google-apps","oidc","okta","onelogin","pingone"]'

# Check for existing identity providers (every page)
IDP_LIST=$(cf_get_all "/accounts/${CF_ACCOUNT_ID}/access/identity_providers") || {
  fail "1.1 Unable to retrieve identity provider list"
  increment_failed
  summary
  exit 0
}

IDP_COUNT=$(echo "${IDP_LIST}" | jq '.result | length')
CORP_COUNT=$(echo "${IDP_LIST}" | jq --argjson corp "${CORPORATE_IDP_TYPES}" \
  '[.result[] | select(.type as $t | $corp | index($t))] | length')
echo "${IDP_LIST}" | jq -r --argjson corp "${CORPORATE_IDP_TYPES}" '.result[]
  | "  - \(.name) (\(.type))\(if (.type as $t | $corp | index($t)) then "" else " -- not a corporate IdP" end)"'

if [ "${CORP_COUNT}" -gt 0 ]; then
  pass "1.1 Found ${CORP_COUNT} corporate identity provider(s) configured"
  increment_applied
  summary
  exit 0
fi

if [ "${IDP_COUNT}" -gt 0 ]; then
  warn "1.1 ${IDP_COUNT} login method(s) configured, none of them a corporate IdP"
fi
may_write "add an OIDC identity provider named 'Corporate IdP'" || {
  fail "1.1 No corporate identity provider is configured"
  increment_failed
  summary
  exit 0
}

# HTH Guide Excerpt: begin api-add-idp
# Add OIDC identity provider to Zero Trust
info "1.1 Adding OIDC identity provider..."
: "${CF_IDP_CLIENT_ID:?Set CF_IDP_CLIENT_ID}"
: "${CF_IDP_CLIENT_SECRET:?Set CF_IDP_CLIENT_SECRET}"
: "${CF_IDP_AUTH_URL:?Set CF_IDP_AUTH_URL}"
: "${CF_IDP_TOKEN_URL:?Set CF_IDP_TOKEN_URL}"
: "${CF_IDP_CERTS_URL:?Set CF_IDP_CERTS_URL (the IdP jwks_uri endpoint)}"

# Build the body with jq so a secret containing quotes or backslashes still
# produces valid JSON.
BODY=$(jq -n \
  --arg id "${CF_IDP_CLIENT_ID}" \
  --arg sec "${CF_IDP_CLIENT_SECRET}" \
  --arg au "${CF_IDP_AUTH_URL}" \
  --arg tu "${CF_IDP_TOKEN_URL}" \
  --arg cu "${CF_IDP_CERTS_URL}" \
  '{
    name: "Corporate IdP",
    type: "oidc",
    config: {
      client_id: $id,
      client_secret: $sec,
      auth_url: $au,
      token_url: $tu,
      certs_url: $cu,
      pkce_enabled: true,
      claims: ["email_verified", "preferred_username", "groups"],
      scopes: ["openid", "email", "profile", "groups"]
    }
  }')

RESPONSE=$(cf_post "/accounts/${CF_ACCOUNT_ID}/access/identity_providers" "${BODY}") || {
  fail "1.1 Failed to add identity provider"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-add-idp

SUCCESS=$(echo "${RESPONSE}" | jq -r '.success')
if [ "${SUCCESS}" = "true" ]; then
  pass "1.1 Identity provider added successfully"
  increment_applied
else
  fail "1.1 Identity provider creation failed"
  echo "${RESPONSE}" | jq '.errors'
  increment_failed
fi

summary
