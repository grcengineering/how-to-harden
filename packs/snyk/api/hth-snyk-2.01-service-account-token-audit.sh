#!/usr/bin/env bash
# HTH Snyk Control 2.1: Secure Service Account Tokens
# Profile: L1 | NIST 800-53: IA-5
# https://howtoharden.com/guides/snyk/#21-secure-service-account-tokens
#
# Audits every Snyk service account at group and org level and flags the
# credential types the guide treats as standing risk: api_key (never
# expires, legacy/not recommended) and access_token (1-year ceiling, no
# in-place rotation). Requires: curl, jq, a Snyk token with admin read.
# Verified against:
#   https://docs.snyk.io/platform-administration/service-accounts/manage-service-accounts-using-the-snyk-api
#   https://docs.snyk.io/developer-tools/snyk-api/reference/serviceaccounts
#   https://docs.snyk.io/developer-tools/snyk-api/authentication-for-api
set -euo pipefail

command -v curl >/dev/null || { echo "ERROR: curl not found" >&2; exit 1; }
command -v jq >/dev/null || { echo "ERROR: jq not found" >&2; exit 1; }

# HTH Guide Excerpt: begin api-service-account-credential-audit
: "${SNYK_TOKEN:?Set SNYK_TOKEN to a Snyk API token with admin access}"
SNYK_API="${SNYK_API:-https://api.snyk.io}"
SNYK_API_VERSION="${SNYK_API_VERSION:-2024-06-10}"

# Audit one scope: "groups <group_id>" or "orgs <org_id>"
audit_service_accounts() {
  local scope="$1" scope_id="$2"
  echo "== Service accounts for ${scope}/${scope_id} =="
  curl -sf \
    --header "Authorization: token ${SNYK_TOKEN}" \
    --header "Content-Type: application/vnd.api+json" \
    "${SNYK_API}/rest/${scope}/${scope_id}/service_accounts?version=${SNYK_API_VERSION}" \
  | jq -r '
      # Service account records carry: id, name, auth_type, role_id,
      # access_token_expires_at, access_token_ttl_seconds.
      # auth_type is one of: access_token, api_key,
      # oauth_client_secret, oauth_private_key_jwt.
      [.. | objects | select(.auth_type?)] | .[] |
      [ .name,
        .auth_type,
        (.access_token_expires_at // "n/a"),
        (if .auth_type == "api_key" then
           "FAIL: legacy API key - never expires, migrate to OAuth 2.0"
         elif .auth_type == "access_token" then
           "WARN: 1-year max expiry, no in-place rotation - plan replacement"
         else
           "PASS: OAuth 2.0 short-lived credential"
         end)
      ] | @tsv'
}

# Group-level service accounts, then each org you operate:
[ -n "${SNYK_GROUP_ID:-}" ] && audit_service_accounts "groups" "${SNYK_GROUP_ID}"
[ -n "${SNYK_ORG_ID:-}" ]   && audit_service_accounts "orgs"   "${SNYK_ORG_ID}"
# HTH Guide Excerpt: end api-service-account-credential-audit

# HTH Guide Excerpt: begin api-delete-legacy-service-account
# Remove a flagged legacy service account once its workload is migrated
# to an OAuth 2.0 service account (deletion also kills its API key).
#   DELETE /rest/orgs/{org_id}/service_accounts/{service_account_id}
#   DELETE /rest/groups/{group_id}/service_accounts/{service_account_id}
delete_service_account() {
  local scope="$1" scope_id="$2" sa_id="$3"
  curl -sf -X DELETE \
    --header "Authorization: token ${SNYK_TOKEN}" \
    "${SNYK_API}/rest/${scope}/${scope_id}/service_accounts/${sa_id}?version=${SNYK_API_VERSION}"
  echo "Deleted service account ${sa_id} from ${scope}/${scope_id}"
}
# HTH Guide Excerpt: end api-delete-legacy-service-account
