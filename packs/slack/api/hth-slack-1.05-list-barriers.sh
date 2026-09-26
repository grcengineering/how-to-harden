#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: slack-1.5
#   guide:   https://howtoharden.com/guides/slack/#15-create-information-barriers-between-groups
#   profile: L3
#   mode:    read-only
#   requires: SLACK_ADMIN_TOKEN(admin.barriers:read user token — Enterprise only)
# =============================================================================
# HTH Slack Control 1.5: Create Information Barriers Between Groups — barrier inventory
# Profile Level: L3 (Run)
# Frameworks: CIS Controls 3.3, 6.8 | NIST 800-53 AC-3, AC-4, SC-7(21)
# Source: https://docs.slack.dev/reference/methods/admin.barriers.list
# Dependencies: curl (7.55+ for -H @file), jq
#
# Lists every information barrier: the primary user group, the groups it is
# barred from, and the restricted subjects (im, mpim, call). Use it to reconcile
# the live barriers against the compliance inventory the guide asks you to keep.
# Writes (admin.barriers.create/update/delete) are deliberately not here.
#
# Fails CLOSED on a non-200 status or "ok": false — including
# feature_not_enabled, which Slack returns when barriers are not enabled for
# the org, so "no barriers" is never inferred from a failed read. Pagination
# follows response_metadata.next_cursor; a repeated cursor exits 1 rather than
# looping forever.
# =============================================================================
set -euo pipefail

# HTH Guide Excerpt: begin api-list-barriers
: "${SLACK_ADMIN_TOKEN:?set SLACK_ADMIN_TOKEN (admin.barriers:read)}"

cursor=""
seen=" "
while :; do
  out="$(curl -sS --get "https://slack.com/api/admin.barriers.list" \
    -H @<(printf 'Authorization: Bearer %s\n' "${SLACK_ADMIN_TOKEN}") \
    --data-urlencode "limit=200" --data-urlencode "cursor=${cursor}" \
    -w '\n%{http_code}')"
  code="${out##*$'\n'}"
  body="${out%$'\n'*}"
  [ "${code}" = "200" ] || { echo "admin.barriers.list failed: HTTP ${code}" >&2; exit 1; }
  if [ "$(printf '%s' "${body}" | jq -r '.ok')" != "true" ]; then
    echo "admin.barriers.list failed: $(printf '%s' "${body}" | jq -r '.error // "unknown"')" >&2
    exit 1
  fi

  printf '%s' "${body}" | jq -r '.barriers[]
    | [.id, .primary_usergroup.name,
       ([.barriered_from_usergroups[].name] | join(", ")),
       ((.restricted_subjects // []) | join(","))]
    | @tsv'

  cursor="$(printf '%s' "${body}" | jq -r '.response_metadata.next_cursor // ""')"
  [ -n "${cursor}" ] || break
  case "${seen}" in *" ${cursor} "*) echo "admin.barriers.list: pagination cursor repeated, listing incomplete" >&2; exit 1 ;; esac
  seen="${seen}${cursor} "
done
# HTH Guide Excerpt: end api-list-barriers
