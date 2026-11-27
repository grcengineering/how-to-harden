#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: aha-roadmaps-3.1
#   guide:   https://howtoharden.com/guides/aha-roadmaps/
#   profile: L2
#   mode:    read-only
#   requires: AHA_SUBDOMAIN, AHA_OPERATIONS_EMAIL, AHA_TOKEN, curl, jq
# First-party source: https://www.aha.io/api/resources/users/list_users
# Response schema: https://www.aha.io/openapi.json
# HTH Guide Excerpt: begin read-evidence
set +x
set -euo pipefail
tenant=${AHA_SUBDOMAIN:?Set the account subdomain without the .aha.io suffix}
contact=${AHA_OPERATIONS_EMAIL:?Set an operations contact for the User-Agent}
[[ "$tenant" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]] || exit 2
email='^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
[[ "$contact" =~ $email ]] || exit 2

token=${AHA_TOKEN:?Set a previously authorized bearer credential}
[[ "$token" != *$'\r'* && "$token" != *$'\n'* ]] || exit 2

ids='[]'
total=
for ((page=1; page<=1000; page++)); do
  body=$(printf 'Authorization: Bearer %s\n' "$token" |
  curl -q --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 40 --header @- --user-agent "HTH Aha audit ($contact)" --get --data-urlencode "page=$page" --data-urlencode per_page=100 "https://$tenant.aha.io/api/v1/users")
  page_ids=$(jq -ce '.users | if type=="array" and all(.[]; (.id|type=="string" and length>0)) then map(.id) else error("invalid users array") end' <<<"$body")
  # The endpoint OpenAPI example uses an object; the general v1 guide shows a singleton array.
  next_total=$(jq -er --argjson page "$page" '
    .pagination | if type=="object" then . elif type=="array" and length==1 then .[0] else error("invalid pagination") end
    | if .current_page==$page and (.total_pages|type=="number" and floor==. and .>=0)
      then .total_pages else error("invalid page metadata") end
  ' <<<"$body")
  [[ -z "$total" || "$next_total" == "$total" ]] || { echo "Aha pagination changed; retry" >&2; exit 1; }
  total=$next_total
  ids=$(jq -cs 'add' <<<"$ids"$'\n'"$page_ids")
  if ((page >= total)); then
    jq -ce 'if length==(unique|length) then sort else error("duplicate user IDs") end' <<<"$ids"
    exit 0
  fi
done
echo "Account inventory exceeded the bounded page count; incomplete" >&2
exit 1
# HTH Guide Excerpt: end read-evidence
