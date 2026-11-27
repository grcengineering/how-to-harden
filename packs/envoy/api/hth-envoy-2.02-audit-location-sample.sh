#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: envoy-2.2
#   guide: https://howtoharden.com/guides/envoy/
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq; ENVOY_ACCESS_TOKEN scoped to locations.read
# HTH Guide Excerpt: begin audit-location-sample
set +x
set -euo pipefail
umask 077

token="${ENVOY_ACCESS_TOKEN:?Set ENVOY_ACCESS_TOKEN from your secret manager}"
unset ENVOY_ACCESS_TOKEN
[[ "$token" =~ ^[A-Za-z0-9._~+/=-]+$ ]] ||
  { printf '%s\n' 'Invalid bearer token format.' >&2; exit 2; }
printf 'header = "Authorization: Bearer %s"\n' "$token" |
  curl -q --config - --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 45 \
    --header 'Accept: application/vnd.api+json' --get --data-urlencode 'page=1' --data-urlencode 'perPage=100' \
    'https://api.envoy.com/rest/v1/locations' |
  jq -e '
    if type != "object" or has("errors") or (.data | type) != "array"
       or any(.data[]; (type != "object") or .type != "locations" or (.attributes.disabled | type) != "boolean")
    then error("Unexpected Envoy location response")
    else {sampled: (.data | length), page: 1, requestedLimit: 100,
          enabled: ([.data[] | select(.attributes.disabled | not)] | length),
          disabled: ([.data[] | select(.attributes.disabled)] | length)}
    end'

# HTH Guide Excerpt: end audit-location-sample
