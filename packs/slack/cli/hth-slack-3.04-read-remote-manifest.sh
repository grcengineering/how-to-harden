#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: slack-3.4
#   profile: L2
#   mode: read-only
# HTH Slack 3.4; L2 (Walk); NIST IA-5, AC-6
# Guide: https://howtoharden.com/guides/slack/#34-require-oauth-token-rotation-and-review-existing-installations
# Source: https://docs.slack.dev/tools/slack-cli/reference/commands/slack_manifest/
# Read only, using an existing authorized Slack CLI login. No token argument.
# Output may contain internal app configuration; keep it private.
# This reads app settings, not organization policy or installed credential expiry.
# HTH Guide Excerpt: begin read-remote-manifest
set +x
set -euo pipefail
level="${HTH_PROFILE_LEVEL:-1}"
if [[ ! "$level" =~ ^[1-4]$ ]] || (( level < 2 )); then
  echo 'Requires HTH_PROFILE_LEVEL >= 2 (valid range 1-4)' >&2
  exit 2
fi
: "${SLACK_APP_ID:?Set the authorized app ID}"
[[ "$SLACK_APP_ID" =~ ^A[A-Z0-9]+$ ]] || { echo 'Invalid app ID' >&2; exit 2; }
slack manifest --source remote --app "$SLACK_APP_ID" --no-color --skip-update
# HTH Guide Excerpt: end read-remote-manifest
