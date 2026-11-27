#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cisco-umbrella-2.2
#   guide: https://howtoharden.com/guides/cisco-umbrella/
#   profile: L2
#   mode: read-only
#   requires: Bash, curl, jq and approved scoped API access
# HTH cisco-umbrella 2.2: audit-activity-sample
# Profile: see the corresponding control in the guide.
# Framework: NIST SP 800-53 Rev. 5 AU-2, AU-6
# Guide: https://howtoharden.com/guides/cisco-umbrella/
# HTH Guide Excerpt: begin audit-activity-sample
set -euo pipefail
umask 077

token="${UMBRELLA_ACCESS_TOKEN:?Set UMBRELLA_ACCESS_TOKEN using your secret manager}"
[[ "$token" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || { printf '%s\n' 'Invalid bearer token format.' >&2; exit 2; }
id="${UMBRELLA_ORIGIN_ID:?Set UMBRELLA_ORIGIN_ID for the approved pilot identity}"
[[ "$id" =~ ^[1-9][0-9]{0,16}$ ]] || { printf '%s\n' 'Invalid identity ID.' >&2; exit 2; }
printf 'header = "Authorization: Bearer %s"\n' "$token" |
  curl -q --config - --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 45 \
    --get --data-urlencode 'from=-1days' --data-urlencode 'to=now' \
    --data-urlencode "identityids=$id" --data-urlencode 'limit=100' \
    'https://api.umbrella.com/reports/v2/activity' |
  jq -e 'if (.data | type) != "array" then error("Unexpected activity response") else {sampleCount: (.data | length), limit: 100} end'

# HTH Guide Excerpt: end audit-activity-sample
