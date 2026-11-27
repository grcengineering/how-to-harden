#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: anodot-1.3
#   guide: https://howtoharden.com/guides/anodot/#13-restrict-streams-and-notification-routes
#   profile: L2
#   mode: read-only
#   requires: Bash, curl, jq, ANODOT_HOST, ANODOT_BEARER_TOKEN
# Vendor contract: https://support.anodot.com/reference/get-channels
# HTH Guide Excerpt: begin summarize-alert-channels
set +x
set -euo pipefail

: "${ANODOT_HOST:?Set the approved account hostname with no scheme or path}"
: "${ANODOT_BEARER_TOKEN:?Inject the authorized short-lived Anodot API bearer token}"
[[ "$ANODOT_HOST" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.anodot\.com$ ]] || exit 2
[[ "$ANODOT_BEARER_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || exit 2

response=$(
  printf 'Authorization: Bearer %s\n' "$ANODOT_BEARER_TOKEN" |
    curl -q --fail --silent --show-error --proto '=https' --max-time 30 \
      --header @- --header 'Accept: application/json' \
      "https://$ANODOT_HOST/api/v2/channels"
)

jq -es '
  if length != 1 or (.[0] | type) != "array"
  then error("invalid Anodot channel response")
  else .[0] end
  | if any(.[]; ((.type | type) != "string") or
                  (.type | test("^[A-Za-z0-9_-]{1,64}$") | not))
    then error("invalid Anodot channel type")
    else {visibleChannels: length,
          byType: (group_by(.type | ascii_downcase) |
            map({key: (.[0].type | ascii_downcase), value: length}) | from_entries)}
    end
' <<< "$response"
# HTH Guide Excerpt: end summarize-alert-channels
