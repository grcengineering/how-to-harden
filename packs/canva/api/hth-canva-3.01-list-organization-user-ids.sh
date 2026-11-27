#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: canva-3.1
#   guide:   https://howtoharden.com/guides/canva/
#   profile: L2
#   mode:    read-only
#   requires: CANVA_ADMIN_TOKEN(admin:user:read)
# List the organization user IDs, not profile data.
# API source: https://www.canva.dev/docs/admin/api-reference/users/list-users/
# Dependencies: bash, curl (7.55+), jq
# HTH Guide Excerpt: begin read-evidence
set +x
set -euo pipefail
token=${CANVA_ADMIN_TOKEN:?Set CANVA_ADMIN_TOKEN to a scoped Admin API bearer token}
[[ "$token" != *$'\r'* && "$token" != *$'\n'* ]] || exit 2
continuation=
ids='[]'
for ((page=0; page<1000; page++)); do
  args=(--get --data-urlencode limit=100)
  if [[ -n "$continuation" ]]; then args+=(--data-urlencode "continuation=$continuation"); fi
  body=$(printf 'Authorization: Bearer %s\n' "$token" |
    curl -q --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 40 --header @- "${args[@]}" https://api.canva.com/admin/v1/users)
  page_ids=$(jq -ce '.items | if type=="array" and all(.[]; (.id|type=="string" and length>0)) then map(.id) else error("invalid user inventory") end' <<<"$body")
  next=$(jq -er '.continuation // "" | if type=="string" then . else error("invalid pagination") end' <<<"$body")
  ids=$(jq -cs 'add' <<<"$ids"$'\n'"$page_ids")
  if [[ -z "$next" ]]; then
    jq -ce 'if length == (unique|length) then sort else error("duplicate user IDs") end' <<<"$ids"
    exit
  fi
  [[ "$next" != "$continuation" ]] || { echo "Repeated Canva cursor" >&2; exit 1; }
  continuation=$next
done
echo "Canva inventory exceeded page limit; incomplete" >&2
exit 1
# HTH Guide Excerpt: end read-evidence
