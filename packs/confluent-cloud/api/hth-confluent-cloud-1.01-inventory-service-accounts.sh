#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: confluent-cloud-1.1
#   guide: https://howtoharden.com/guides/confluent-cloud/#11-separate-workload-identities
#   profile: L1
#   mode: read-only
#   requires: curl, jq, base64, Confluent Cloud API key
# Source (reviewed 2026-11-27): https://docs.confluent.io/cloud/current/ccloud/list-iam-v-2-service-accounts/
# HTH Guide Excerpt: begin inventory-service-accounts
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${CONFLUENT_CLOUD_API_KEY:-}" =~ ^[[:alnum:]_-]+$ ]] || fail 'Missing or invalid CONFLUENT_CLOUD_API_KEY'
[[ "${CONFLUENT_CLOUD_API_SECRET:-}" =~ ^[[:alnum:]_+./=-]+$ ]] || fail 'Missing or invalid CONFLUENT_CLOUD_API_SECRET'

page_token=${CONFLUENT_PAGE_TOKEN:-}
[[ "$page_token" =~ ^[[:alnum:]_~.+/=-]*$ ]] || fail 'Invalid pagination token'
auth=$(printf '%s:%s' "$CONFLUENT_CLOUD_API_KEY" "$CONFLUENT_CLOUD_API_SECRET" | base64 | tr -d '\r\n')
query='page_size=100'
if [[ -n "$page_token" ]]; then
  query+="&page_token=$(jq -rn --arg t "$page_token" '$t|@uri')"
fi
response=$(printf 'header = "Authorization: Basic %s"\n' "$auth" |
  curl --disable --config - --silent --show-error --fail --proto '=https' \
    --connect-timeout 10 --max-time 45 "https://api.confluent.cloud/iam/v2/service-accounts?$query") || fail 'Read request did not succeed'

jq -e '(.data|type)=="array" and all(.data[]; (.id|type)=="string" and (.display_name|type)=="string") and (.metadata.next==null or (.metadata.next|type)=="string")' <<<"$response" >/dev/null || fail 'Unexpected service account response'
jq '{scope:"one page of service accounts visible to the current identity",next_page_link:.metadata.next,accounts:[.data[]|{id,display_name}]}' <<<"$response"
# HTH Guide Excerpt: end inventory-service-accounts
