#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: slack-1.4
#   guide:   https://howtoharden.com/guides/slack/#14-configure-session-management
#   profile: L2
#   mode:    read-only
#   requires: SLACK_ADMIN_TOKEN(admin.users:read user token — Enterprise only)
# =============================================================================
# HTH Slack Control 1.4: Configure Session Management — per-user session audit
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 4.3 | NIST 800-53 AC-11, AC-12
# Source: https://docs.slack.dev/reference/methods/admin.users.session.getSettings
# Dependencies: curl (7.55+ for -H @file), jq
# Usage: bash hth-slack-1.04-session-settings.sh U0123ABCD [U0456EFGH ...]
#
# Reads the per-user session overrides (duration in seconds, and whether the
# session ends when the desktop app or browser quits) that Enterprise orgs set
# with admin.users.session.setSettings. The org/workspace default duration has
# no Web API method at all — verify it in the console (guide Step 1). Users
# with no override are omitted by Slack and fall back to that default.
#
# POST is this method's documented transport; it only reads. Fails CLOSED on a
# non-200 status or "ok": false (not_an_admin, feature_not_enabled, ...).
# =============================================================================
set -euo pipefail

# HTH Guide Excerpt: begin api-session-settings
: "${SLACK_ADMIN_TOKEN:?set SLACK_ADMIN_TOKEN (admin.users:read)}"
[ "$#" -gt 0 ] || { echo "usage: $0 <user_id> [user_id ...]" >&2; exit 2; }

payload="$(printf '%s\n' "$@" | jq -Rn '{user_ids: [inputs]}')"
out="$(curl -sS "https://slack.com/api/admin.users.session.getSettings" \
  -H @<(printf 'Authorization: Bearer %s\n' "${SLACK_ADMIN_TOKEN}") \
  -H 'Content-Type: application/json; charset=utf-8' \
  --data "${payload}" \
  -w '\n%{http_code}')"
code="${out##*$'\n'}"
body="${out%$'\n'*}"
[ "${code}" = "200" ] || { echo "getSettings failed: HTTP ${code}" >&2; exit 1; }
if [ "$(printf '%s' "${body}" | jq -r '.ok')" != "true" ]; then
  echo "getSettings failed: $(printf '%s' "${body}" | jq -r '.error // "unknown"')" >&2
  exit 1
fi

printf 'user_id\tends_on_client_quit\tduration_seconds\n'
printf '%s' "${body}" | jq -r '.session_settings[]
  | [.user_id, (.desktop_app_browser_quit | tostring), (.duration | tostring)] | @tsv'
# HTH Guide Excerpt: end api-session-settings
