#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: calendly-1.2
#   guide:   https://howtoharden.com/guides/calendly/
#   profile: L1
#   mode:    read-only
#   requires: CALENDLY_TOKEN(organizations:read), CALENDLY_ORGANIZATION_URI
# Emit one minimized membership array per page.
# API source: https://developer.calendly.com/api-docs/calendly-api/organizations/list-organization-memberships
# Dependencies: bash, curl (7.55+), jq
# HTH Guide Excerpt: begin read-evidence
set +x
set -euo pipefail
token=${CALENDLY_TOKEN:?Set CALENDLY_TOKEN to an appropriate bearer token}
organization=${CALENDLY_ORGANIZATION_URI:?Set the full Calendly organization URI}
[[ "$organization" =~ ^https://api\.calendly\.com/organizations/[A-Za-z0-9-]+$ ]] || exit 2
[[ "$token" != *$'\r'* && "$token" != *$'\n'* ]] || exit 2
token_page=
for ((page=0; page<1000; page++)); do
  args=(--get --data-urlencode "organization=$organization")
  args+=(--data-urlencode count=100)
  if [[ -n "$token_page" ]]; then args+=(--data-urlencode "page_token=$token_page"); fi
  body=$(printf 'Authorization: Bearer %s\n' "$token" |
    curl -q --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 40 --header @- "${args[@]}" https://api.calendly.com/organization_memberships)
  jq -ce --arg org "$organization" 'if (.collection|type=="array") and all(.collection[]; .organization==$org and (.uri|type=="string") and (.role|IN("owner","admin","user"))) then .collection | map({uri,role}) else error("invalid organization memberships") end' <<<"$body"
  next=$(jq -er '.pagination | if type=="object" then (.next_page_token // "") else error("missing pagination") end | if type=="string" then . else error("invalid next page") end' <<<"$body")
  if [[ -z "$next" ]]; then exit 0; fi
  [[ "$next" != "$token_page" ]] || { echo "Repeated Calendly page token" >&2; exit 1; }
  token_page=$next
done
echo "Calendly inventory exceeded page limit; incomplete" >&2
exit 1
# HTH Guide Excerpt: end read-evidence
