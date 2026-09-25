#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: slack-3.2
#   guide:   https://howtoharden.com/guides/slack/#32-manage-slack-connect-external-collaboration
#   profile: L2
#   mode:    read-only
#   requires: SLACK_BOT_TOKEN(conversations.connect:manage + team:read bot token — Enterprise only)
# =============================================================================
# HTH Slack Control 3.2: Manage Slack Connect — external organization inventory
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 3.3 | NIST 800-53 AC-22, SC-7
# Source: https://docs.slack.dev/reference/methods/team.externalTeams.list
#         https://docs.slack.dev/apis/slack-connect/using-slack-connect-api-methods
# Dependencies: curl (7.55+ for -H @file), jq
#
# Lists every external organization connected through Slack Connect with its
# connection status and channel counts, so the list can be compared against the
# partners you approved. Disconnecting (team.externalTeams.disconnect) is a
# write and is deliberately not here.
#
# Fails CLOSED on a non-200 status or "ok": false, so a failed read never
# prints an empty (and falsely reassuring) partner list. Pagination follows
# response_metadata.next_cursor; a repeated cursor exits 1 rather than looping.
# =============================================================================
set -euo pipefail

# HTH Guide Excerpt: begin api-list-external-orgs
: "${SLACK_BOT_TOKEN:?set SLACK_BOT_TOKEN (conversations.connect:manage, team:read)}"

cursor=""
seen=" "
printf 'team_id\tteam_name\tconnection_status\tpublic\tprivate\tlast_active\n'
while :; do
  out="$(curl -sS --get "https://slack.com/api/team.externalTeams.list" \
    -H @<(printf 'Authorization: Bearer %s\n' "${SLACK_BOT_TOKEN}") \
    --data-urlencode "cursor=${cursor}" \
    -w '\n%{http_code}')"
  code="${out##*$'\n'}"
  body="${out%$'\n'*}"
  [ "${code}" = "200" ] || { echo "team.externalTeams.list failed: HTTP ${code}" >&2; exit 1; }
  if [ "$(printf '%s' "${body}" | jq -r '.ok')" != "true" ]; then
    echo "team.externalTeams.list failed: $(printf '%s' "${body}" | jq -r '.error // "unknown"')" >&2
    exit 1
  fi

  printf '%s' "${body}" | jq -r '.organizations[]
    | [.team_id, .team_name, .connection_status,
       (.public_channel_count | tostring), (.private_channel_count | tostring),
       ((.last_active_timestamp // 0) | todate)]
    | @tsv'

  cursor="$(printf '%s' "${body}" | jq -r '.response_metadata.next_cursor // ""')"
  [ -n "${cursor}" ] || break
  case "${seen}" in *" ${cursor} "*) echo "team.externalTeams.list: pagination cursor repeated, listing incomplete" >&2; exit 1 ;; esac
  seen="${seen}${cursor} "
done
# HTH Guide Excerpt: end api-list-external-orgs
