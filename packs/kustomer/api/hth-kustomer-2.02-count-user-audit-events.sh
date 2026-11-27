#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: kustomer-2.2
#   guide: https://howtoharden.com/guides/kustomer/#22-validate-bounded-audit-evidence
#   profile: L1
#   mode: read-only
#   requires: curl, jq, Kustomer audit-read API key
# Source (reviewed 2026-11-27): https://developer.kustomer.com/api/core-resources/query-events-associated-with-your-organization
# HTH Guide Excerpt: begin count-user-audit-events
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${KUSTOMER_API_KEY:-}" =~ ^[[:alnum:]_.~+/=-]+$ ]] || fail 'Missing or invalid KUSTOMER_API_KEY'
[[ "${KUSTOMER_ORG_SUBDOMAIN:-}" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]] || fail 'Missing or invalid KUSTOMER_ORG_SUBDOMAIN'

auth=$KUSTOMER_API_KEY
response=$(printf 'header = "Authorization: Bearer %s"\n' "$auth" |
  curl --disable --config - --silent --show-error --fail --proto '=https' \
    --connect-timeout 10 --max-time 45 "https://$KUSTOMER_ORG_SUBDOMAIN.api.kustomerapp.com/v1/audit-logs?count=100&filter%5BobjectType%5D=user") || fail 'Read request did not succeed'

jq -e '
  (.data|type=="array") and all(.data[];.type=="audit_log" and
    .attributes.objectType=="user") and
  (.links|type=="object") and (.links.next==null or (.links.next|type=="string"))
' <<<"$response" >/dev/null 2>&1 || fail 'Unexpected or unfiltered audit log response'
jq '{object_type:"user",returned_event_count:(.data|length),next_page_present:((.links.next // "")!=""),complete_coverage_checked:false}' <<<"$response"
# HTH Guide Excerpt: end count-user-audit-events
