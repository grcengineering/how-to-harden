#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: syncplicity-1.2
#   guide: https://howtoharden.com/guides/syncplicity/#12-restrict-api-application-credentials
#   profile: L1
#   mode: mutating
#   requires: curl, jq, base64, approved application credential and API user token
# Source (reviewed 2026-11-27): https://support.syncplicity.com/hc/en-us/articles/115002028926-Getting-Started-with-Syncplicity-APIs
# HTH Guide Excerpt: begin verify-company-token
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }

[[ "${1:-}" == '--issue-token' && $# == 1 ]] || fail 'Explicit --issue-token required'
case "${SYNCPLICITY_REGION:-us}" in
  us) host=api.syncplicity.com ;;
  eu) host=api.eu.syncplicity.com ;;
  *) fail 'SYNCPLICITY_REGION must be us or eu' ;;
esac
[[ "${SYNCPLICITY_APP_KEY:-}" =~ ^[[:alnum:]_.~+/=-]+$ ]] || fail 'Missing or invalid SYNCPLICITY_APP_KEY'
[[ "${SYNCPLICITY_APP_SECRET:-}" =~ ^[[:alnum:]_.~+/=-]+$ ]] || fail 'Missing or invalid SYNCPLICITY_APP_SECRET'
[[ "${SYNCPLICITY_APP_TOKEN:-}" =~ ^[[:alnum:]_.~+/=-]+$ ]] || fail 'Missing or invalid SYNCPLICITY_APP_TOKEN'
[[ "${SYNCPLICITY_COMPANY_ID:-}" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ]] || fail 'Missing or invalid SYNCPLICITY_COMPANY_ID'

auth=$(printf '%s:%s' "$SYNCPLICITY_APP_KEY" "$SYNCPLICITY_APP_SECRET" | base64 | tr -d '\r\n')
response=$(printf 'header = "Authorization: Basic %s"\nheader = "Sync-App-Token: %s"\n' "$auth" "$SYNCPLICITY_APP_TOKEN" |
  curl --disable --config - --silent --show-error --fail --proto '=https' \
    --connect-timeout 10 --max-time 45 --data 'grant_type=client_credentials' "https://$host/oauth/token") ||
  fail 'Token exchange did not succeed'
jq -e --arg expected "$SYNCPLICITY_COMPANY_ID" '
  (.access_token|type=="string" and length>0) and
  (.user_company_id|ascii_downcase)==($expected|ascii_downcase) and
  (.scope|type=="string" and length>0) and
  (.expires_in|tonumber)>0
' <<<"$response" >/dev/null 2>&1 || fail 'Unexpected token metadata or wrong company'
jq '{expected_company_confirmed:true,scope_present:true,expires_in_seconds:(.expires_in|tonumber)}' <<<"$response"
# HTH Guide Excerpt: end verify-company-token
