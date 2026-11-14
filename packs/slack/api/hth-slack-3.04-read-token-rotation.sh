#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: slack-3.4
#   profile: L2
#   mode: read-only
# HTH Slack 3.4; L2 (Walk); NIST IA-5, AC-6
# Guide: https://howtoharden.com/guides/slack/#34-require-oauth-token-rotation-and-review-existing-installations
# Source: https://docs.slack.dev/reference/methods/apps.manifest.export/
# Read only. Requires a configuration token with app_configurations:read.
# Checks an owned/authorized app, NOT organization policy or installed token expiry.
# Exit 0: enabled; 1: disabled; 2: unknown/error. Never run with shell tracing.
# HTH Guide Excerpt: begin read-oauth-token-rotation
set +x
set -euo pipefail
level="${HTH_PROFILE_LEVEL:-1}"
if [[ ! "$level" =~ ^[1-4]$ ]] || (( level < 2 )); then
  echo 'Requires HTH_PROFILE_LEVEL >= 2 (valid range 1-4)' >&2
  exit 2
fi
: "${SLACK_CONFIG_TOKEN:?Set an authorized app configuration token}"
: "${SLACK_APP_ID:?Set the app ID}"
[[ "$SLACK_APP_ID" =~ ^A[A-Z0-9]+$ ]] || { echo 'Invalid app ID' >&2; exit 2; }
[[ "$SLACK_CONFIG_TOKEN" =~ ^[A-Za-z0-9._-]+$ ]] || { echo 'Invalid token format' >&2; exit 2; }
command -v curl >/dev/null || { echo 'Missing curl; rotation unknown' >&2; exit 2; }
command -v jq >/dev/null || { echo 'Missing jq; rotation unknown' >&2; exit 2; }
# Supply credentials via stdin, not command-line arguments; refuse redirects.
if ! response=$(printf 'header = "Authorization: Bearer %s"\n' "$SLACK_CONFIG_TOKEN" |
  curl -q --config - --silent --show-error --fail --proto '=https' \
    --connect-timeout 10 --max-time 30 --request POST \
    --data-urlencode "app_id=$SLACK_APP_ID" https://slack.com/api/apps.manifest.export); then
  echo 'Export failed; rotation unknown' >&2; exit 2
fi
if ! jq -e '.ok == true and (.manifest.settings.token_rotation_enabled | type == "boolean")' >/dev/null 2>&1 <<<"$response"; then
  echo 'Export rejected or rotation field missing/invalid; unknown' >&2; exit 2
fi
if jq -e '.manifest.settings.token_rotation_enabled == true' >/dev/null <<<"$response"; then
  echo 'App manifest OAuth rotation: enabled (installed credentials not verified)'
else
  echo 'App manifest OAuth rotation: disabled'; exit 1
fi
# HTH Guide Excerpt: end read-oauth-token-rotation
