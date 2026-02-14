#!/usr/bin/env bash
# HTH Okta Control 3.4: Govern Non-Human Identities (NHI)
# Profile: L1 | NIST: IA-4, IA-5, AC-2
# https://howtoharden.com/guides/okta/#34-govern-non-human-identities
source "$(dirname "$0")/common.sh"

banner "3.4: Govern Non-Human Identities (NHI)"

should_apply 1 || { increment_skipped; summary; exit 0; }
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

summary
