#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: goto-meeting-1.1
#   guide: https://howtoharden.com/guides/goto-meeting/#11-constrain-organizer-and-administrator-access
#   profile: L1
#   mode: read-only
#   requires: curl, jq, GoTo Admin access token
# Source (reviewed 2026-11-27): https://developer.goto.com/guides/GoToConnect/09_HOW_fetchAccountUsers/
# HTH Guide Excerpt: begin check-admin-account-visibility
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${GOTO_ACCESS_TOKEN:-}" =~ ^[[:alnum:]_.~+/=-]+$ ]] || fail 'Missing or invalid GOTO_ACCESS_TOKEN'
[[ "${GOTO_ACCOUNT_KEY:-}" =~ ^[0-9]{1,30}$ ]] || fail 'Missing or invalid GOTO_ACCOUNT_KEY'

auth=$GOTO_ACCESS_TOKEN
response=$(printf 'header = "Authorization: Bearer %s"\n' "$auth" |
  curl --disable --config - --silent --show-error --fail --proto '=https' \
    --connect-timeout 10 --max-time 45 "https://api.getgo.com/admin/rest/v1/me") || fail 'Read request did not succeed'

jq -e --arg expected "$GOTO_ACCOUNT_KEY" '
  (.accounts|type=="array") and all(.accounts[];(.key|type=="string")) and
  any(.accounts[];.key==$expected)
' <<<"$response" >/dev/null 2>&1 || fail 'Expected account not visible or response malformed'
jq '{expected_account_visible:true,visible_account_count:(.accounts|length),meeting_license_checked:false,sso_enforcement_checked:false}' <<<"$response"
# HTH Guide Excerpt: end check-admin-account-visibility
