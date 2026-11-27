#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: hypr-2.2
#   guide: https://howtoharden.com/guides/hypr/
#   profile: L2
#   mode: read-only
#   requires: Bash, curl, jq and approved scoped API access
# HTH hypr 2.2: audit-rp-events
# Profile: see the corresponding control in the guide.
# Framework: NIST SP 800-53 Rev. 5 AU-2, AU-6
# Guide: https://howtoharden.com/guides/hypr/
# HTH Guide Excerpt: begin audit-rp-events
set -euo pipefail
umask 077

token="${HYPR_REPORT_TOKEN:?Set HYPR_REPORT_TOKEN using your secret manager}"
[[ "$token" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || { printf '%s\n' 'Invalid bearer token format.' >&2; exit 2; }
host="${HYPR_TENANT_HOST:?Set HYPR_TENANT_HOST to the approved HYPR Cloud tenant host}"
app="${HYPR_RP_APP_ID:?Set HYPR_RP_APP_ID}"
start="${HYPR_START_EPOCH_MS:?Set HYPR_START_EPOCH_MS}"
end="${HYPR_END_EPOCH_MS:?Set HYPR_END_EPOCH_MS}"
[[ "$host" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.hypr\.com$ ]] || {
  printf '%s\n' 'Expected a HYPR Cloud HTTPS hostname under hypr.com.' >&2; exit 2;
}
if ! [[ "$start" =~ ^[1-9][0-9]{12}$ && "$end" =~ ^[1-9][0-9]{12}$ ]] ||
  ! (( end > start && end - start <= 3600000 )); then
  printf '%s\n' 'Provide a positive UTC epoch millisecond window no longer than one hour.' >&2; exit 2;
fi
printf 'header = "Authorization: Bearer %s"\n' "$token" |
  curl -q --config - --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 45 \
    --get --data-urlencode "startTSUTC=$start" --data-urlencode "endTSUTC=$end" \
    --data-urlencode "rpAppId=$app" --data-urlencode 'pageSize=100' \
    --data-urlencode 'orderBy=eventTimeInUTC' --data-urlencode 'sortDir=desc' \
    "https://$host/cc/api/versioned/audit/search" |
  jq -e 'if (.data | type) != "array" then error("Unexpected audit response") else {sampleCount: (.data | length), eventNames: [.data[] | .eventName] | unique} end'

# HTH Guide Excerpt: end audit-rp-events
