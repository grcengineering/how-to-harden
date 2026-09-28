#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: slack-1.3
#   guide:   https://howtoharden.com/guides/slack/#13-restrict-workspace-admin-roles
#   profile: L1
#   mode:    read-only
#   requires: SLACK_USER_TOKEN(users:read — bot or user token; any plan)
# =============================================================================
# HTH Slack Control 1.3: Restrict Workspace Admin Roles — privileged-member audit
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 5.4 | NIST 800-53 AC-6(1)
# Source: https://docs.slack.dev/reference/methods/users.list
# Dependencies: curl (7.55+ for -H @file), jq
#
# Prints every active member whose user object carries is_primary_owner,
# is_owner, or is_admin, so the Owner/Admin roster can be reviewed against the
# least-privilege list in the guide. users.list also returns deleted and
# invited accounts; deleted ones are skipped. Pagination follows
# response_metadata.next_cursor until it comes back empty; a cursor Slack has
# already returned stops the run with exit 1, since a looping listing is
# incomplete, not clean.
#
# Fails CLOSED: a non-200 status or "ok": false (invalid_auth, missing_scope,
# ratelimited, ...) exits 1 with the vendor error, and a roster with no primary
# owner exits 1 too — every workspace has exactly one, so its absence means the
# read was incomplete, not that the workspace is clean. The token is passed as
# a header read from a process-substitution fd, never in curl's argv.
# =============================================================================
set -euo pipefail

# HTH Guide Excerpt: begin api-list-privileged-members
: "${SLACK_USER_TOKEN:?set SLACK_USER_TOKEN (users:read)}"

cursor=""
seen=" "
primary_owners=0
while :; do
  out="$(curl -sS --get "https://slack.com/api/users.list" \
    -H @<(printf 'Authorization: Bearer %s\n' "${SLACK_USER_TOKEN}") \
    --data-urlencode "limit=200" --data-urlencode "cursor=${cursor}" \
    -w '\n%{http_code}')"
  code="${out##*$'\n'}"
  body="${out%$'\n'*}"
  [ "${code}" = "200" ] || { echo "users.list failed: HTTP ${code}" >&2; exit 1; }
  if [ "$(printf '%s' "${body}" | jq -r '.ok')" != "true" ]; then
    echo "users.list failed: $(printf '%s' "${body}" | jq -r '.error // "unknown"')" >&2
    exit 1
  fi

  printf '%s' "${body}" | jq -r '
    .members[]
    | select((.deleted // false) | not)
    | select((.is_primary_owner // false) or (.is_owner // false) or (.is_admin // false))
    | [.id, .name,
       (if .is_primary_owner then "primary_owner"
        elif .is_owner then "owner" else "admin" end)]
    | @tsv'
  n="$(printf '%s' "${body}" | jq '[.members[] | select(.is_primary_owner == true)] | length')"
  primary_owners=$((primary_owners + n))

  cursor="$(printf '%s' "${body}" | jq -r '.response_metadata.next_cursor // ""')"
  [ -n "${cursor}" ] || break
  case "${seen}" in *" ${cursor} "*) echo "users.list: pagination cursor repeated, listing incomplete" >&2; exit 1 ;; esac
  seen="${seen}${cursor} "
done

if [ "${primary_owners}" -eq 0 ]; then
  echo "no primary owner in the roster: the read was incomplete" >&2
  exit 1
fi
# HTH Guide Excerpt: end api-list-privileged-members
