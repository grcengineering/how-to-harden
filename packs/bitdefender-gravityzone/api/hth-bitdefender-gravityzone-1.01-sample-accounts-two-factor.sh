#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: bitdefender-gravityzone-1.1
#   guide: https://howtoharden.com/guides/bitdefender-gravityzone/
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq; base64, tr; GRAVITYZONE_API_KEY, optional GRAVITYZONE_KEY_KIND, GRAVITYZONE_PAGE
# HTH Guide Excerpt: begin sample-accounts-two-factor
set +x
set -euo pipefail
umask 077
key="${GRAVITYZONE_API_KEY:?Set GRAVITYZONE_API_KEY via your approved secret store}"
kind="${GRAVITYZONE_KEY_KIND:-service}"
page="${GRAVITYZONE_PAGE:-1}"
[[ "$key" =~ ^[A-Za-z0-9._~+/=-]+$ && "$page" =~ ^[1-9][0-9]{0,8}$ ]] || {
  printf '%s\n' 'Invalid API key format or page.' >&2
  exit 2
}
case "$kind" in
  service) auth="X-API-Key: $key" ;;
  personal)
    encoded=$(printf '%s:' "$key" | base64 | tr -d '\n')
    auth="Authorization: Basic $encoded"
    ;;
  *) printf '%s\n' 'Expected service or personal for GRAVITYZONE_KEY_KIND.' >&2; exit 2 ;;
esac
payload=$(jq -cn --argjson page "$page" '{id:"hth-accounts",jsonrpc:"2.0",method:"getAccountsList",params:{page:$page,perPage:100}}')
# The vendor uses HTTP POST for JSON-RPC, including this read-only getAccountsList call.
printf 'header = "%s"\n' "$auth" |
  curl -q --config - --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 45 \
    --header 'Content-Type: application/json' --data-binary "$payload" \
    'https://cloud.gravityzone.bitdefender.com/api/v1.0/jsonrpc/accounts' |
  jq -e --argjson page "$page" '
    if .error != null then error("GravityZone returned a JSON-RPC error")
    elif .id != "hth-accounts" or .jsonrpc != "2.0" or
        (.result | type) != "object" or .result.page != $page or
        (.result.pagesCount | type) != "number" or (.result.items | type) != "array" or
        any(.result.items[]; type != "object")
    then error("Unexpected GravityZone account response")
    else .result | {page, pagesCount, retrievedCount: (.items | length),
      factorTrue: ([.items[] | select(.twoFactorAuthenticationStatus == true)] | length),
      factorFalse: ([.items[] | select(.twoFactorAuthenticationStatus == false)] | length),
      factorUnknown: ([.items[] | select((.twoFactorAuthenticationStatus | type) != "boolean")] | length)}
    end'

# HTH Guide Excerpt: end sample-accounts-two-factor
