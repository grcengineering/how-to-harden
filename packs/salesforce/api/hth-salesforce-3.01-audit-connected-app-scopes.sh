#!/usr/bin/env bash
# HTH Salesforce Control 3.1: Audit and Reduce OAuth Scopes
# Profile: L1 | NIST: AC-6
# https://howtoharden.com/guides/salesforce/#31-audit-and-reduce-oauth-scopes
source "$(dirname "$0")/common.sh"

banner "3.1: Audit and Reduce OAuth Scopes"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "3.1 Auditing Connected Apps and OAuth scope configuration..."

# HTH Guide Excerpt: begin api-list-connected-apps
# List all Connected Applications with OAuth settings
info "3.1 Querying Connected Applications..."
APP_QUERY="SELECT Id, Name, CreatedDate, CreatedBy.Name, LastModifiedDate FROM ConnectedApplication ORDER BY Name"
APP_RESPONSE=$(sf_tooling_query "${APP_QUERY}") || {
  fail "3.1 Failed to query Connected Applications"
  increment_failed
  summary
  exit 0
}

APP_COUNT=$(echo "${APP_RESPONSE}" | jq '.totalSize // 0' 2>/dev/null)

if [ "${APP_COUNT}" -gt 0 ]; then
  info "3.1 Found ${APP_COUNT} Connected Application(s):"
  echo "${APP_RESPONSE}" | jq -r '.records[] | "  - \(.Name) (Created: \(.CreatedDate), By: \(.CreatedBy.Name // "unknown"))"' 2>/dev/null || true
else
  info "3.1 No Connected Applications found"
fi
# HTH Guide Excerpt: end api-list-connected-apps

# HTH Guide Excerpt: begin api-audit-oauth-tokens
# Audit active OAuth access tokens to identify over-permissioned integrations
info "3.1 Querying active OAuth tokens..."
TOKEN_QUERY="SELECT Id, AppName, UserId, CreatedDate, LastUsedDate FROM OAuthToken ORDER BY LastUsedDate DESC NULLS LAST"
TOKEN_RESPONSE=$(sf_query "${TOKEN_QUERY}" 2>/dev/null || echo '{"records":[],"totalSize":0}')

TOKEN_COUNT=$(echo "${TOKEN_RESPONSE}" | jq '.totalSize // 0' 2>/dev/null)

if [ "${TOKEN_COUNT}" -gt 0 ]; then
  info "3.1 Found ${TOKEN_COUNT} active OAuth token(s):"
  echo "${TOKEN_RESPONSE}" | jq -r '.records[] | "  - \(.AppName // "unnamed") (Last Used: \(.LastUsedDate // "never"), Created: \(.CreatedDate))"' 2>/dev/null || true

  # Flag tokens not used in 90+ days
  STALE_QUERY="SELECT Id, AppName, UserId, CreatedDate, LastUsedDate FROM OAuthToken WHERE LastUsedDate < LAST_N_DAYS:90"
  STALE_RESPONSE=$(sf_query "${STALE_QUERY}" 2>/dev/null || echo '{"records":[],"totalSize":0}')
  STALE_COUNT=$(echo "${STALE_RESPONSE}" | jq '.totalSize // 0' 2>/dev/null)

  if [ "${STALE_COUNT}" -gt 0 ]; then
    warn "3.1 Found ${STALE_COUNT} stale OAuth token(s) unused for 90+ days -- consider revoking:"
    echo "${STALE_RESPONSE}" | jq -r '.records[] | "  - \(.AppName // "unnamed") (Last Used: \(.LastUsedDate // "never"))"' 2>/dev/null || true
  else
    pass "3.1 No stale OAuth tokens found (all used within 90 days)"
  fi
else
  info "3.1 No active OAuth tokens found"
fi
# HTH Guide Excerpt: end api-audit-oauth-tokens

# HTH Guide Excerpt: begin api-check-connected-app-policies
# Check Connected App OAuth policies (admin approval, IP relaxation)
info "3.1 Checking Connected App OAuth policies..."
POLICY_QUERY="SELECT Id, Name, OptionsAllowAdminApprovedUsersOnly, OptionsRefreshTokenValidityMetric FROM ConnectedApplication"
POLICY_RESPONSE=$(sf_tooling_query "${POLICY_QUERY}" 2>/dev/null || echo '{"records":[],"totalSize":0}')

POLICY_COUNT=$(echo "${POLICY_RESPONSE}" | jq '.totalSize // 0' 2>/dev/null)

if [ "${POLICY_COUNT}" -gt 0 ]; then
  # Flag apps that do NOT require admin pre-authorization
  OPEN_APPS=$(echo "${POLICY_RESPONSE}" | jq '[.records[] | select(.OptionsAllowAdminApprovedUsersOnly != true)]' 2>/dev/null || echo "[]")
  OPEN_COUNT=$(echo "${OPEN_APPS}" | jq 'length' 2>/dev/null || echo "0")

  if [ "${OPEN_COUNT}" -gt 0 ]; then
    warn "3.1 Found ${OPEN_COUNT} Connected App(s) not requiring admin pre-authorization:"
    echo "${OPEN_APPS}" | jq -r '.[] | "  - \(.Name) -- set OAuth policy to 'Admin approved users are pre-authorized'"' 2>/dev/null || true
  else
    pass "3.1 All Connected Apps require admin pre-authorization"
  fi
else
  info "3.1 No Connected App policy data available"
fi
# HTH Guide Excerpt: end api-check-connected-app-policies

increment_applied

summary
