#!/usr/bin/env bash
# HTH Box Control 3.2: Service Account Security
# Profile: L2 | NIST 800-53: IA-5
# https://howtoharden.com/guides/box/#32-service-account-security
#
# Inventories Box app users (the service accounts behind JWT/CCG platform apps)
# and reviews their recent enterprise-event activity using the first-party Box CLI.
#   CLI docs:      https://developer.box.com/guides/tooling/cli/
#   users command: https://github.com/box/boxcli/blob/main/docs/users.md (--app-users)
#   events command: https://github.com/box/boxcli/blob/main/docs/events.md
#   Events API:    https://developer.box.com/reference/get-events/ (stream_type=admin_logs)
#
# Prerequisites: Box CLI authenticated with admin privileges (admin_logs requires
# admin access and the "manage enterprise properties" scope), jq installed.
set -euo pipefail

command -v box >/dev/null 2>&1 || { echo "ERROR: box CLI not found" >&2; exit 1; }
command -v jq  >/dev/null 2>&1 || { echo "ERROR: jq not found" >&2; exit 1; }

# How far back to pull enterprise events (Box CLI shorthand: 2w = two weeks)
LOOKBACK="${LOOKBACK:-2w}"

# HTH Guide Excerpt: begin cli-inventory-app-users
# Inventory every app user (service account). Each row is a non-human identity
# holding standing, non-interactive access that user MFA does not protect.
APP_USERS_JSON=$(box users --app-users --json --fields id,name,login,created_at,modified_at)

echo "App users (service accounts): $(echo "${APP_USERS_JSON}" | jq 'length')"
echo "${APP_USERS_JSON}" | jq -r '.[] | "  \(.id)\t\(.name)\t\(.login)"'
# HTH Guide Excerpt: end cli-inventory-app-users

# HTH Guide Excerpt: begin cli-service-account-activity
# Pull recent enterprise events and keep only those performed by an app user,
# so anomalous automated access stands out for review.
EVENTS_JSON=$(box events --enterprise --stream-type admin_logs \
  --created-after "${LOOKBACK}" --json)

APP_USER_IDS=$(echo "${APP_USERS_JSON}" | jq '[.[].id]')

echo "Enterprise events by service accounts (last ${LOOKBACK}):"
echo "${EVENTS_JSON}" | jq -r --argjson ids "${APP_USER_IDS}" \
  '.[] | select(.created_by.id as $u | $ids | index($u))
       | "  \(.created_at)\t\(.event_type)\t\(.created_by.login // .created_by.id)"'
# HTH Guide Excerpt: end cli-service-account-activity

# HTH Guide Excerpt: begin cli-flag-dormant-service-accounts
# Service accounts with zero activity in the lookback window are candidates
# for removal — dormant automation is a forgotten access path into Box data.
ACTIVE_IDS=$(echo "${EVENTS_JSON}" | jq '[.[].created_by.id] | unique')
echo "App users with NO events in the last ${LOOKBACK} (review for removal):"
echo "${APP_USERS_JSON}" | jq -r --argjson active "${ACTIVE_IDS}" \
  '.[] | select(.id as $u | $active | index($u) | not)
       | "  DORMANT: \(.id)\t\(.name)\t\(.login)"'
# HTH Guide Excerpt: end cli-flag-dormant-service-accounts
