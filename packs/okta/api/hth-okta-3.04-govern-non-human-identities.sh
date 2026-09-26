#!/usr/bin/env bash
# HTH Okta Control 3.4: Govern Non-Human Identities (NHI)
# Profile: L1 | NIST: IA-4, IA-5, AC-2
# https://howtoharden.com/guides/okta/#34-govern-non-human-identities-nhi
#
# Read-only audit. A token owned by a Read-Only Administrator is sufficient.
source "$(dirname "$0")/common.sh"

banner "3.4: Govern Non-Human Identities (NHI)"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "3.4 Auditing non-human identities (API tokens and service apps)..."

# HTH Guide Excerpt: begin api-list-tokens
# List all active API tokens (a failed read stops the pack)
info "3.4 Listing all active API tokens..."
API_TOKENS=$(okta_get "/api/v1/api-tokens")
TOKEN_COUNT=$(printf '%s' "${API_TOKENS}" | jq 'length')
# HTH Guide Excerpt: end api-list-tokens

info "3.4 Found ${TOKEN_COUNT} API token(s)"
printf '%s' "${API_TOKENS}" | jq -r '.[] | "  - \(.name) (created: \(.created), user: \(.userId), network: \(.network.connection // "unrestricted"))"'

# Flag tokens without network restrictions
UNRESTRICTED=$(printf '%s' "${API_TOKENS}" | jq '[.[] | select(.network == null or .network.connection == "ANYWHERE")] | length')
if [ "${UNRESTRICTED}" -gt 0 ]; then
  warn "3.4 ${UNRESTRICTED} API token(s) have no network restrictions -- re-create them restricted to a network zone"
fi

# Flag old tokens (created more than 90 days ago)
info "3.4 Checking for stale API tokens (>90 days)..."
NINETY_DAYS_AGO=$(date -d '90 days ago' -u +%Y-%m-%dT%H:%M:%S.000Z 2>/dev/null \
  || date -v-90d -u +%Y-%m-%dT%H:%M:%S.000Z)

STALE_TOKENS=$(printf '%s' "${API_TOKENS}" | jq --arg cutoff "${NINETY_DAYS_AGO}" \
  '[.[] | select(.created < $cutoff)] | length')
if [ "${STALE_TOKENS}" -gt 0 ]; then
  warn "3.4 ${STALE_TOKENS} API token(s) are older than 90 days -- rotate them"
else
  info "3.4 No API token is older than 90 days"
fi

# HTH Guide Excerpt: begin api-list-service-apps
# List service applications (OAuth client_credentials)
info "3.4 Listing OAuth service applications..."
SERVICE_APPS=$(okta_get "/api/v1/apps?filter=status%20eq%20%22ACTIVE%22&limit=200" \
  | jq '[.[] | select((.settings.oauthClient.grant_types? // []) | index("client_credentials"))]')
SVC_COUNT=$(printf '%s' "${SERVICE_APPS}" | jq 'length')
# HTH Guide Excerpt: end api-list-service-apps

info "3.4 Found ${SVC_COUNT} OAuth service application(s)"
if [ "${SVC_COUNT}" -gt 0 ]; then
  printf '%s' "${SERVICE_APPS}" | jq -r '.[] | "  - \(.label) (ID: \(.id), client auth: \(.credentials.oauthClient.token_endpoint_auth_method // "unknown"))"'
fi

pass "3.4 NHI audit complete -- review tokens and service apps above"
increment_applied

summary
