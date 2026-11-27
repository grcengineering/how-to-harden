#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: calendly-2.1
#   guide:   https://howtoharden.com/guides/calendly/
#   profile: L2
#   mode:    read-only
#   requires: CALENDLY_TOKEN(activity_log:read), CALENDLY_ORGANIZATION_URI, CALENDLY_START_UTC, CALENDLY_END_UTC
# Emit minimized audit-event arrays per page. Discard all output after a nonzero exit.
# API source: https://developer.calendly.com/api-docs/calendly-api/activity-log/list-activity-log-entries
# Dependencies: bash, curl (7.55+), jq
# HTH Guide Excerpt: begin read-evidence
set +x
set -euo pipefail
start=${CALENDLY_START_UTC:?Set CALENDLY_START_UTC to YYYY-MM-DDTHH:MM:SSZ}
end=${CALENDLY_END_UTC:?Set CALENDLY_END_UTC to YYYY-MM-DDTHH:MM:SSZ}
utc='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'
[[ "$start" =~ $utc && "$end" =~ $utc && "$start" < "$end" ]] || exit 2

token=${CALENDLY_TOKEN:?Set CALENDLY_TOKEN to an appropriate bearer token}
organization=${CALENDLY_ORGANIZATION_URI:?Set the full Calendly organization URI}
[[ "$organization" =~ ^https://api\.calendly\.com/organizations/[A-Za-z0-9-]+$ ]] || exit 2
[[ "$token" != *$'\r'* && "$token" != *$'\n'* ]] || exit 2
token_page=
for ((page=0; page<1000; page++)); do
  args=(--get --data-urlencode "organization=$organization")
  args+=(--data-urlencode "min_occurred_at=$start" --data-urlencode "max_occurred_at=$end")
  if [[ -n "$token_page" ]]; then args+=(--data-urlencode "page_token=$token_page"); fi
  body=$(printf 'Authorization: Bearer %s\n' "$token" |
    curl -q --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 40 --header @- "${args[@]}" https://api.calendly.com/activity_log_entries)
  jq -ce --arg org "$organization" 'if (.collection|type=="array") and all(.collection[]; .organization==$org and (.occurred_at|type=="string") and (.fully_qualified_name|type=="string")) then .collection | map({occurred_at,fully_qualified_name}) else error("invalid activity results") end' <<<"$body"
  next=$(jq -er '.pagination | if type=="object" then (.next_page_token // "") else error("missing pagination") end | if type=="string" then . else error("invalid next page") end' <<<"$body")
  if [[ -z "$next" ]]; then exit 0; fi
  [[ "$next" != "$token_page" ]] || { echo "Repeated Calendly page token" >&2; exit 1; }
  token_page=$next
done
echo "Calendly inventory exceeded page limit; incomplete" >&2
exit 1
# HTH Guide Excerpt: end read-evidence
