#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: hackerone-1.2
#   guide: https://howtoharden.com/guides/hackerone/
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq; HACKERONE_API_USERNAME, HACKERONE_API_TOKEN, HACKERONE_PROGRAM_ID
# HTH Guide Excerpt: begin audit-program-members
set +x
set -euo pipefail
umask 077

username="${HACKERONE_API_USERNAME:?Set HACKERONE_API_USERNAME}"
token="${HACKERONE_API_TOKEN:?Set HACKERONE_API_TOKEN from your secret manager}"
program="${HACKERONE_PROGRAM_ID:?Set HACKERONE_PROGRAM_ID to the numeric program ID}"
unset HACKERONE_API_USERNAME HACKERONE_API_TOKEN
[[ "$username" =~ ^[A-Za-z0-9._@-]+$ ]] && [[ "$token" =~ ^[A-Za-z0-9._~+/=-]+$ ]] &&
  [[ "$program" =~ ^[1-9][0-9]{0,19}$ ]] ||
  { printf '%s\n' 'Invalid API credentials or program ID format.' >&2; exit 2; }
printf 'user = "%s:%s"\n' "$username" "$token" |
  curl -q --config - --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 45 \
    --basic --header 'Accept: application/json' --get --data-urlencode 'page[size]=100' \
    --data-urlencode 'filter[exclude_system_users]=true' \
    "https://api.hackerone.com/v1/programs/$program/members" |
  jq -e '
    if type != "object" or has("errors") or (.data | type) != "array"
       or any(.data[]; (type != "object") or .type != "organization-member"
              or (.attributes.organization_admin | type) != "boolean")
       or (.links.next != null and (.links.next | type) != "string")
    then error("Unexpected HackerOne program member response")
    else {sampled: (.data | length), organizationAdmins: ([.data[] | select(.attributes.organization_admin)] | length),
          hasNext: (.links.next != null)}
    end'

# HTH Guide Excerpt: end audit-program-members
