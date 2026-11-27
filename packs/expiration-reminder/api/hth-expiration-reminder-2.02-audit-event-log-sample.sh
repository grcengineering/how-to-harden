#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: expiration-reminder-2.2
#   guide: https://howtoharden.com/guides/expiration-reminder/
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq; EXPIRATION_REMINDER_API_KEY and optionally EXPIRATION_REMINDER_PAGE
# HTH Guide Excerpt: begin audit-event-log-sample
set +x
set -euo pipefail
umask 077

token="${EXPIRATION_REMINDER_API_KEY:?Set EXPIRATION_REMINDER_API_KEY from your secret manager}"
page="${EXPIRATION_REMINDER_PAGE:-1}"
unset EXPIRATION_REMINDER_API_KEY
[[ "$token" =~ ^[A-Za-z0-9._~+/=-]+$ ]] &&
  [[ "$page" =~ ^(0|[1-9][0-9]{0,8})$ ]] ||
  { printf '%s\n' 'Invalid credential or page format.' >&2; exit 2; }
printf 'header = "Authorization: Bearer %s"\n' "$token" |
  curl -q --config - --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 45 \
    --header 'Accept: application/json' --get --data-urlencode "page=$page" \
    'https://api.expirationreminder.com/v1/eventlogs' |
  jq -e --argjson page "$page" '
    if type != "object" or (.eventlogs | type) != "array"
       or (.page | type) != "number" or (.pages | type) != "number" or (.total | type) != "number"
       or any(.eventlogs[]; (type != "object") or (.type_id | type) != "number")
    then error("Unexpected Expiration Reminder event log response")
    else {requestedPage: $page, returnedPage: .page, advertisedPages: .pages, advertisedTotal: .total,
          sampled: (.eventlogs | length),
          byEventType: (.eventlogs | group_by(.type_id) |
              map({typeId: .[0].type_id, count: length}))}
    end'

# HTH Guide Excerpt: end audit-event-log-sample
