#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: slack-4.2
#   guide:   https://howtoharden.com/guides/slack/#42-configure-message-retention-policies
#   profile: L1
#   mode:    read-only
#   requires: SLACK_ADMIN_TOKEN(admin.conversations:read user token — Enterprise only)
# =============================================================================
# HTH Slack Control 4.2: Configure Message Retention Policies — per-conversation retention audit
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 3.4 | NIST 800-53 SI-12, AU-11
# Source: https://docs.slack.dev/reference/methods/admin.conversations.getCustomRetention
# Dependencies: curl (7.55+ for -H @file), jq
# Usage: bash hth-slack-4.02-get-custom-retention.sh C0123ABCD [C0456EFGH ...]
#
# For each conversation ID (public or private channel, DM, or MPDM) prints
# whether a custom retention policy is enabled and how many days messages are
# kept, so compliance-relevant channels can be checked against the retention
# schedule. The workspace/org default has no Web API method — verify it in the
# console (guide Step 1).
#
# POST is this method's documented transport; it only reads. Fails CLOSED: the
# first conversation that returns a non-200 or "ok": false stops the run.
# =============================================================================
set -euo pipefail

# HTH Guide Excerpt: begin api-get-custom-retention
: "${SLACK_ADMIN_TOKEN:?set SLACK_ADMIN_TOKEN (admin.conversations:read)}"
[ "$#" -gt 0 ] || { echo "usage: $0 <channel_id> [channel_id ...]" >&2; exit 2; }

printf 'channel_id\tpolicy_enabled\tduration_days\n'
for channel_id in "$@"; do
  out="$(curl -sS "https://slack.com/api/admin.conversations.getCustomRetention" \
    -H @<(printf 'Authorization: Bearer %s\n' "${SLACK_ADMIN_TOKEN}") \
    --data-urlencode "channel_id=${channel_id}" \
    -w '\n%{http_code}')"
  code="${out##*$'\n'}"
  body="${out%$'\n'*}"
  [ "${code}" = "200" ] || { echo "${channel_id}: HTTP ${code}" >&2; exit 1; }
  if [ "$(printf '%s' "${body}" | jq -r '.ok')" != "true" ]; then
    echo "${channel_id}: $(printf '%s' "${body}" | jq -r '.error // "unknown"')" >&2
    exit 1
  fi
  printf '%s' "${body}" | jq -r --arg c "${channel_id}" \
    '[$c, (.is_policy_enabled | tostring), ((.duration_days // "-") | tostring)] | @tsv'
done
# HTH Guide Excerpt: end api-get-custom-retention
