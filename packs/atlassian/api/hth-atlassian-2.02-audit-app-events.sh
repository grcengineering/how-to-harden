#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: atlassian-2.2
#   guide:   https://howtoharden.com/guides/atlassian/#22-monitor-app-activity
#   profile: L2
#   mode:    read-only
#   requires: ORG_ID(organization id from admin.atlassian.com/o/<orgId>/), ATLASSIAN_ORG_API_KEY(Organization API key with scopes, read:events:admin only)
# =============================================================================
# HTH Atlassian Control 2.2: Monitor App Activity
# Profile Level: L2 (Walk) | NIST 800-53: AU-6
# Source: https://developer.atlassian.com/cloud/admin/organization/rest/api-group-events/
#         GET /v1/orgs/{orgId}/event-actions ; GET /v1/orgs/{orgId}/events-stream
# Dependencies: bash 3.2+, curl 7.55+ (-H @file), jq
#
# Reads the organization audit log (an Atlassian Guard capability) and prints
# only app-related events from the last LOOKBACK_DAYS days, one JSON line each.
#  - App actions are DISCOVERED from GET /v1/orgs/{orgId}/event-actions, never
#    hard-coded: an event's attributes.action is one of those ids.
#  - Any non-200 is a hard failure, never "no app activity". The reference
#    documents no 403 for these operations and says nothing about an
#    organization without Guard, so that case is not assumed to error.
#  - An empty app-action catalogue exits 2, and a window with no audit events
#    of any kind exits 4: an audit that selected or scanned nothing must never
#    read as clean.
#  - The key travels in a process-substitution header file, never in argv.
#  - Events API rate limit is 10 requests/minute; pages are spaced PAGE_DELAY s.
#  - Replaces an earlier version that called an undocumented
#    /audit-events?filter=app resource and exited 0 on HTTP 401.
#
# Exit codes: 0 audited (app events printed, possibly none) | 2 could not audit | 3 partial (page cap)
#             4 inconclusive (the audit log returned no events at all in the window)
#             any other non-zero: a response that was not the documented JSON (never read as clean)
# =============================================================================
set -euo pipefail

: "${ORG_ID:?set ORG_ID}"
: "${ATLASSIAN_ORG_API_KEY:?set ATLASSIAN_ORG_API_KEY (Organization API key, scope read:events:admin)}"
API="${ATLASSIAN_API_BASE:-https://api.atlassian.com}"
LOOKBACK_DAYS="${LOOKBACK_DAYS:-30}"
MAX_PAGES="${MAX_PAGES:-20}"
PAGE_DELAY="${PAGE_DELAY:-6}"
command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

# HTH Guide Excerpt: begin api-audit-app-events
api_get() {  # $1 = path + query; prints the body; returns 2 on any non-200
  local resp code
  resp=$(curl -sS --max-time 60 -w '\n%{http_code}' \
    -H @<(printf 'Authorization: Bearer %s\n' "$ATLASSIAN_ORG_API_KEY") \
    -H 'Accept: application/json' "${API}$1") || { echo "ERROR: GET ${1%%\?*} failed in transport" >&2; return 2; }
  code=${resp##*$'\n'}
  if [ "$code" != "200" ]; then
    echo "ERROR: GET ${1%%\?*} -> HTTP ${code} (check the key is valid and carries read:events:admin)" >&2
    return 2
  fi
  printf '%s\n' "${resp%$'\n'*}"
}

# 1. Discover app-related action ids from the documented catalogue.
catalogue=$(api_get "/admin/v1/orgs/${ORG_ID}/event-actions")
app_ids=$(printf '%s' "$catalogue" | jq -c '[.data[] | select((.attributes.displayName + " " + .attributes.groupDisplayName) | test("\\bapps?\\b"; "i")) | .id]')
n_ids=$(printf '%s' "$app_ids" | jq 'length')
if [ "$n_ids" -eq 0 ]; then
  echo "ERROR: event-actions returned no app-related actions; nothing was audited" >&2
  exit 2
fi
echo "app-related actions in catalogue: ${n_ids}" >&2

# 2. Page the audit log for the look-back window; keep only app actions.
#    events-stream keeps returning a cursor at the end (it is a poll), so an
#    empty page ends the walk.
from_ms=$(( ( $(date +%s) - LOOKBACK_DAYS * 86400 ) * 1000 ))
query="from=${from_ms}&limit=500"
pages=0; matched=0; scanned=0
while :; do
  page=$(api_get "/admin/v1/orgs/${ORG_ID}/events-stream?${query}")
  n_rows=$(printf '%s' "$page" | jq -e '.data | if type == "array" then length else error("no data array") end')
  scanned=$(( scanned + n_rows ))
  hits=$(printf '%s' "$page" | jq -c --argjson ids "$app_ids" \
    '.data[] | select(.attributes.action as $a | $ids | index($a)) | {time: .attributes.time, action: .attributes.action, actor: .attributes.actor.id}')
  if [ -n "$hits" ]; then printf '%s\n' "$hits"; matched=$(( matched + $(printf '%s\n' "$hits" | grep -c .) )); fi
  pages=$(( pages + 1 ))
  next=$(printf '%s' "$page" | jq -r '.meta.next // empty')
  if [ -z "$next" ] || [ "$n_rows" -eq 0 ]; then break; fi
  if [ "$pages" -ge "$MAX_PAGES" ]; then
    echo "ERROR: stopped at MAX_PAGES=${MAX_PAGES}; results are partial (raise MAX_PAGES or shorten LOOKBACK_DAYS)" >&2
    exit 3
  fi
  query="from=${from_ms}&limit=500&cursor=$(jq -rn --arg c "$next" '$c|@uri')"
  sleep "$PAGE_DELAY"
done
echo "pages read: ${pages}; events scanned: ${scanned}; app events in last ${LOOKBACK_DAYS} days: ${matched}" >&2
if [ "$scanned" -eq 0 ]; then
  echo "INCONCLUSIVE: the audit log returned no events at all in the window, so it shows nothing about apps" >&2
  exit 4
fi
# HTH Guide Excerpt: end api-audit-app-events
