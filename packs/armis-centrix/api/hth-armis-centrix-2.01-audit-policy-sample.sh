#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: armis-centrix-2.1
#   guide: https://howtoharden.com/guides/armis-centrix/
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq; ARMIS_ACCESS_TOKEN with PERMISSION.POLICY.READ
# HTH Guide Excerpt: begin audit-policy-sample
set +x
set -euo pipefail
umask 077

token="${ARMIS_ACCESS_TOKEN:?Set ARMIS_ACCESS_TOKEN from your secret manager}"
unset ARMIS_ACCESS_TOKEN
[[ "$token" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || { printf '%s\n' 'Invalid bearer token format.' >&2; exit 2; }
printf 'header = "Authorization: Bearer %s"\n' "$token" |
  curl -q --config - --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 45 \
    --get --data-urlencode 'limit=100' 'https://api.armis.com/v3/policies' |
  jq -e '
    if (.items | type) != "array"
       or any(.items[]; (type != "object") or (.is_enabled | type) != "boolean")
       or ((.next | type) != "number" and .next != null)
    then error("Unexpected Armis policies response")
    else {sampled: (.items | length), hasNext: (.next != null),
          enabled: ([.items[] | select(.is_enabled)] | length),
          disabled: ([.items[] | select(.is_enabled | not)] | length)}
    end'

# HTH Guide Excerpt: end audit-policy-sample
