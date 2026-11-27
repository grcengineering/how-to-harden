#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: egnyte-2.1
#   guide: https://howtoharden.com/guides/egnyte/#21-verify-audit-delivery-and-cursor-coverage
#   profile: L1
#   mode: read-only
#   requires: curl, jq, reporting-authorized OAuth token
# Source (reviewed 2026-11-27): https://developers.egnyte.com/docs/read/Audit_Reporting_API_V2
# HTH Guide Excerpt: begin read-audit-window
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${EGNYTE_SUBDOMAIN:-}" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$ ]] || fail 'Missing or invalid EGNYTE_SUBDOMAIN'
[[ "${EGNYTE_ACCESS_TOKEN:-}" =~ ^[[:alnum:]_.~+/=-]+$ ]] || fail 'Missing or invalid EGNYTE_ACCESS_TOKEN'
auth=$EGNYTE_ACCESS_TOKEN

start_date=${EGNYTE_START_DATE:-}
[[ "$start_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || fail 'Supply EGNYTE_START_DATE (YYYY-MM-DD) within the last seven days'
query="startDate=$start_date"
response=$(printf 'header = "Authorization: Bearer %s"\n' "$auth" |
  curl --disable --config - --silent --show-error --fail --proto '=https' \
    --connect-timeout 10 --max-time 45 "https://$EGNYTE_SUBDOMAIN.egnyte.com/pubapi/v2/audit/stream?$query") || fail 'Read request did not succeed'

jq -e '(.nextCursor|type)=="string" and (.moreEvents|type)=="boolean" and (.events|type)=="array" and all(.events[]; (.auditSource|type)=="string")' <<<"$response" >/dev/null || fail 'Unexpected audit window response'
jq '{scope:"one audit stream window; not a coverage result",nextCursor,moreEvents,event_count:(.events|length),sources:(.events|group_by(.auditSource)|map({source:.[0].auditSource,count:length}))}' <<<"$response"
# HTH Guide Excerpt: end read-audit-window
