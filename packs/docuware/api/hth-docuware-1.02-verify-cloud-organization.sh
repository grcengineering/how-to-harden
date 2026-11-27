#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: docuware-1.2
#   guide: https://howtoharden.com/guides/docuware/#12-separate-organization-and-role-scope
#   profile: L1
#   mode: read-only
#   requires: curl, jq, approved DocuWare Cloud Platform bearer token
# Source (reviewed 2026-11-27): https://developer.docuware.com/URL_Integration/examples/ids.html
# HTH Guide Excerpt: begin verify-cloud-organization
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${DOCUWARE_SUBDOMAIN:-}" =~ ^[[:alnum:]]([[:alnum:]-]{0,61}[[:alnum:]])?$ ]] || fail 'Missing or invalid DOCUWARE_SUBDOMAIN'
[[ "${DOCUWARE_ACCESS_TOKEN:-}" =~ ^[[:alnum:]_.~+/=-]+$ ]] || fail 'Missing or invalid DOCUWARE_ACCESS_TOKEN'
[[ "${DOCUWARE_ORG_ID:-}" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ]] || fail 'Missing or invalid DOCUWARE_ORG_ID'

response=$(printf 'header = "Authorization: Bearer %s"\n' "$DOCUWARE_ACCESS_TOKEN" |
  curl --disable --config - --silent --show-error --fail --proto '=https' \
    --connect-timeout 10 --max-time 45 --header 'Accept: application/json' \
    "https://$DOCUWARE_SUBDOMAIN.docuware.cloud/DocuWare/Platform/Organizations") ||
  fail 'Organization read did not succeed'
jq -e --arg expected "$DOCUWARE_ORG_ID" '
  (.Organization|type=="array") and all(.Organization[];(.Id|type=="string")) and
  any(.Organization[];(.Id|ascii_downcase)==($expected|ascii_downcase))
' <<<"$response" >/dev/null 2>&1 || fail 'Unexpected response or expected organization not visible'
jq '{expected_organization_visible:true,visible_organization_count:(.Organization|length),role_scope_checked:false}' <<<"$response"
# HTH Guide Excerpt: end verify-cloud-organization
