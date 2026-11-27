#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: alteryx-designer-cloud-1.2
#   guide: https://howtoharden.com/guides/alteryx-designer-cloud/#12-review-and-retire-personal-api-tokens
#   profile: L1
#   mode: read-only
#   requires: Bash, curl, jq, ALTERYX_US1_API_TOKEN
# Vendor contract: https://help.alteryx.com/developer-help/fr/get-started-with-alteryx-one-apis.html
# HTH Guide Excerpt: begin inspect-personal-api-token-metadata
set +x
set -euo pipefail

: "${ALTERYX_US1_API_TOKEN:?Inject the authorized user token for Alteryx One US1}"
[[ "$ALTERYX_US1_API_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || exit 2
response=$(
  printf 'Authorization: Bearer %s\n' "$ALTERYX_US1_API_TOKEN" |
    curl -q --fail --silent --show-error --proto '=https' --max-time 30 \
      --header @- --header 'Content-Type: application/json' \
      'https://us1.alteryxcloud.com/v4/apiAccessTokens'
)
jq -e '
  if (.data | type) != "array" or any(.data[]; (.createdAt | type) != "string")
  then error("unexpected personal API token response")
  else {scope: "authenticated-user/US1", returnedCount: (.data | length),
        tokens: [.data[] | {createdAt, expiredAt, lastUsed}]} end
' <<< "$response"
# HTH Guide Excerpt: end inspect-personal-api-token-metadata
