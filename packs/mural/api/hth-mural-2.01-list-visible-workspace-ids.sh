#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: mural-2.1
#   guide:   https://howtoharden.com/guides/mural/
#   profile: L2
#   mode:    read-only
#   requires: MURAL_TOKEN(workspaces:read), curl, jq
# API/CLI source: https://developers.mural.co/public/reference/getworkspaces
# HTH Guide Excerpt: begin read-evidence
set +x
set -euo pipefail
token=${MURAL_TOKEN:?Set a previously authorized bearer token}
[[ "$token" != *$'\r'* && "$token" != *$'\n'* ]] || exit 2

cursor=
ids='[]'
for ((page=0; page<1000; page++)); do
  args=(--get)
  if [[ -n "$cursor" ]]; then args+=(--data-urlencode "next=$cursor"); fi
  body=$(printf 'Authorization: Bearer %s\n' "$token" |
    curl -q --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 40 --header @- "${args[@]}" "https://app.mural.co/api/public/v1/workspaces")
  page_ids=$(jq -ce '.value | if type=="array" and all(.[]; (.id|type=="string" and length>0)) then map(.id) else error("invalid workspace response") end' <<<"$body")
  next=$(jq -er '.next // "" | if type=="string" then . else error("invalid pagination") end' <<<"$body")
  ids=$(jq -cs 'add' <<<"$ids"$'\n'"$page_ids")
  if [[ -z "$next" ]]; then
    jq -ce 'if length == (unique|length) then sort else error("duplicate workspace IDs") end' <<<"$ids"
    exit 0
  fi
  [[ "$next" != "$cursor" ]] || { echo "Repeated workspace cursor; incomplete" >&2; exit 1; }
  cursor=$next
done
echo "Workspace inventory exceeded page limit; incomplete" >&2
exit 1
# HTH Guide Excerpt: end read-evidence
