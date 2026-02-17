#!/usr/bin/env bash
# HTH Cloudflare Control 1.1: Configure Identity Provider Integration
# Profile: L1 | NIST: IA-2, IA-8 | CIS: 6.3, 12.5
# https://howtoharden.com/guides/cloudflare/#11-configure-identity-provider-integration
source "$(dirname "$0")/common.sh"

banner "1.1: Configure Identity Provider Integration"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.1 Checking identity provider configuration..."

# Check for existing identity providers
IDP_LIST=$(cf_get "/accounts/${CF_ACCOUNT_ID}/access/identity_providers") || {
  fail "1.1 Unable to retrieve identity provider list"
  increment_failed
  summary
  exit 0
}

IDP_COUNT=$(echo "${IDP_LIST}" | jq '.result | length')

if [ "${IDP_COUNT}" -gt 0 ]; then
  pass "1.1 Found ${IDP_COUNT} identity provider(s) configured"
  echo "${IDP_LIST}" | jq -r '.result[] | "  - \(.name) (\(.type))"'
  increment_applied
  summary
  exit 0
fi

# HTH Guide Excerpt: begin api-add-idp
# Add OIDC identity provider to Zero Trust
info "1.1 Adding OIDC identity provider..."
: "${CF_IDP_CLIENT_ID:?Set CF_IDP_CLIENT_ID}"
: "${CF_IDP_CLIENT_SECRET:?Set CF_IDP_CLIENT_SECRET}"
: "${CF_IDP_AUTH_URL:?Set CF_IDP_AUTH_URL}"
: "${CF_IDP_TOKEN_URL:?Set CF_IDP_TOKEN_URL}"

RESPONSE=$(cf_post "/accounts/${CF_ACCOUNT_ID}/access/identity_providers" "{
  \"name\": \"Corporate IdP\",
  \"type\": \"oidc\",
  \"config\": {
    \"client_id\": \"${CF_IDP_CLIENT_ID}\",
    \"client_secret\": \"${CF_IDP_CLIENT_SECRET}\",
    \"auth_url\": \"${CF_IDP_AUTH_URL}\",
    \"token_url\": \"${CF_IDP_TOKEN_URL}\",
    \"claims\": [\"email_verified\", \"preferred_username\", \"groups\"],
    \"scopes\": [\"openid\", \"email\", \"profile\", \"groups\"]
  }
}") || {
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
