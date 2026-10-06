#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: slack-4.5
#   guide:   https://howtoharden.com/guides/slack/#45-restrict-slack-ai-access-to-sensitive-channels-canvases-and-lists
#   profile: L3
#   mode:    mutating
#   requires: SLACK_ADMIN_TOKEN(admin.conversations:write user token — Enterprise+), EXCLUDE(optional: true|false, default true)
# =============================================================================
# HTH Slack Control 4.5: Restrict Slack AI Access to Sensitive Channels — bulk exclusion
# Profile Level: L3 (Run)
# Frameworks: CIS Controls 3.3, 3.12 | NIST 800-53 AC-3, AC-4, SC-28
# Source: https://docs.slack.dev/reference/methods/admin.conversations.bulkSetExcludeFromSlackAi
# Dependencies: curl (7.55+ for -H @file), jq
# Usage: bash hth-slack-4.05-exclude-channels-from-ai.sh C0123ABCD [C0456EFGH ...]
#
# MUTATING. Excludes up to 100 channels per call from Slack AI. REVERT with the
# same channel IDs and EXCLUDE=false. The method queues a bulk action: it
# returns a bulk_action_id and a not_added list of channels that failed
# validation (for example invalid_channel), and this script exits non-zero if
# any channel was not added, so a partial restriction is never reported as done.
# Canvases and lists are restricted per item in the UI (guide Step 2).
# =============================================================================
set -euo pipefail

# HTH Guide Excerpt: begin api-exclude-channels-from-ai
: "${SLACK_ADMIN_TOKEN:?set SLACK_ADMIN_TOKEN (admin.conversations:write)}"
exclude="${EXCLUDE:-true}"
case "${exclude}" in true|false) ;; *) echo "EXCLUDE must be true or false" >&2; exit 2 ;; esac
[ "$#" -ge 1 ] && [ "$#" -le 100 ] || { echo "usage: $0 <channel_id> ... (1-100 IDs)" >&2; exit 2; }

payload="$(printf '%s\n' "$@" | jq -Rn --argjson ex "${exclude}" '{channel_ids: [inputs], exclude: $ex}')"
out="$(curl -sS -X POST "https://slack.com/api/admin.conversations.bulkSetExcludeFromSlackAi" \
  -H @<(printf 'Authorization: Bearer %s\n' "${SLACK_ADMIN_TOKEN}") \
  -H 'Content-Type: application/json; charset=utf-8' \
  --data "${payload}" \
  -w '\n%{http_code}')"
code="${out##*$'\n'}"
body="${out%$'\n'*}"
[ "${code}" = "200" ] || { echo "bulkSetExcludeFromSlackAi failed: HTTP ${code}" >&2; exit 1; }
if [ "$(printf '%s' "${body}" | jq -r '.ok')" != "true" ]; then
  echo "bulkSetExcludeFromSlackAi failed: $(printf '%s' "${body}" | jq -r '.error // "unknown"')" >&2
  exit 1
fi

echo "bulk_action_id: $(printf '%s' "${body}" | jq -r '.bulk_action_id')"
not_added="$(printf '%s' "${body}" | jq -r '(.not_added // [])[] | [.channel_id, .error] | @tsv')"
if [ -n "${not_added}" ]; then
  printf 'not added:\n%s\n' "${not_added}" >&2
  exit 1
fi
# HTH Guide Excerpt: end api-exclude-channels-from-ai
