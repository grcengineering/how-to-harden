#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cisco-secure-access-1.1
#   guide: https://howtoharden.com/guides/cisco-secure-access/
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq; SECURE_ACCESS_TOKEN with policies.securityProfiles:read
# HTH Guide Excerpt: begin audit-security-profiles
set +x
set -euo pipefail
umask 077

token="${SECURE_ACCESS_TOKEN:?Set SECURE_ACCESS_TOKEN from your secret manager}"
unset SECURE_ACCESS_TOKEN
[[ "$token" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || { printf '%s\n' 'Invalid bearer token format.' >&2; exit 2; }
printf 'header = "Authorization: Bearer %s"\n' "$token" |
  curl -q --config - --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 45 \
    --get --data-urlencode 'page=1' --data-urlencode 'limit=100' \
    'https://api.sse.cisco.com/policies/v2/securityProfiles' |
  jq -e '
    if .status.code != 200 or .meta.page != 1 or (.meta.total | type) != "number"
       or (.data | type) != "array" or .meta.total < (.data | length)
       or any(.data[]; (type != "object") or (.isDefault | type) != "boolean")
    then error("Unexpected security profiles response")
    else {sampled: (.data | length), advertisedTotal: .meta.total,
          defaults: ([.data[] | select(.isDefault)] | length),
          reportingEnabled: ([.data[] | select(.reporting == "enabled")] | length),
          reportingDisabled: ([.data[] | select(.reporting == "disabled")] | length),
          reportingUnknown: ([.data[] | select(.reporting != "enabled" and .reporting != "disabled")] | length)}
    end'

# HTH Guide Excerpt: end audit-security-profiles
