#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: atlassian-5.1
#   guide:   https://howtoharden.com/guides/atlassian/#51-enable-audit-logging
#   profile: L1
#   mode:    read-only
#   requires: ORG_ID(organization id), ATLASSIAN_ORG_API_KEY(Organization API key with scopes, read:events:admin only)
# =============================================================================
# HTH Atlassian Control 5.1: Enable Audit Logging — export the org audit log
# Profile Level: L1 (Crawl) | NIST 800-53: AU-2, AU-3
# Source: https://developer.atlassian.com/cloud/admin/organization/rest/api-group-events/
#         GET /v1/orgs/{orgId}/events-stream  (cursor, from, to, limit<=500, sortOrder;
#         PollingEventPage with meta.next)
# Dependencies: bash 3.2+, curl 7.55+ (-H @file), jq
#
#  - Emits every organization audit event since LOOKBACK_HOURS ago (or since a
#    saved CURSOR) as one JSON object per line on stdout, ready for a SIEM
#    file or HTTP collector. Progress and the resume cursor go to stderr.
#  - Any non-200 is reported as "could not export", never as "no events". The
#    reference documents no 403 for this operation and says nothing about an
#    organization without Guard, so that case is not assumed to error.
#  - Streaming configuration (the console's audit log streaming to a SIEM)
#    has no REST resource. This pack is the pull alternative, not that setting.
#  - Events API rate limit is 10 requests/minute; pages are spaced PAGE_DELAY s.
#
# Exit codes: 0 exported | 2 could not export | 3 partial (page cap; resume with the printed CURSOR)
#             any other non-zero: a response that was not the documented JSON (never read as clean)
# =============================================================================
set -euo pipefail

: "${ORG_ID:?set ORG_ID}"
: "${ATLASSIAN_ORG_API_KEY:?set ATLASSIAN_ORG_API_KEY (Organization API key, scope read:events:admin)}"
API="${ATLASSIAN_API_BASE:-https://api.atlassian.com}"
LOOKBACK_HOURS="${LOOKBACK_HOURS:-24}"
CURSOR="${CURSOR:-}"
MAX_PAGES="${MAX_PAGES:-50}"
PAGE_DELAY="${PAGE_DELAY:-6}"
command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

# HTH Guide Excerpt: begin api-export-audit-log
api_get() {  # key in a process-substitution header file, never in argv; non-200 -> 2
  local resp code
  resp=$(curl -sS --max-time 60 -w '\n%{http_code}' \
    -H @<(printf 'Authorization: Bearer %s\n' "$ATLASSIAN_ORG_API_KEY") \
    -H 'Accept: application/json' "${API}$1") || { echo "ERROR: GET ${1%%\?*} failed in transport" >&2; return 2; }
  code=${resp##*$'\n'}
  [ "$code" = "200" ] || { echo "ERROR: GET ${1%%\?*} -> HTTP ${code} (check the key is valid and carries read:events:admin)" >&2; return 2; }
  printf '%s\n' "${resp%$'\n'*}"
}

from_ms=$(( ( $(date +%s) - LOOKBACK_HOURS * 3600 ) * 1000 ))
query="from=${from_ms}&limit=500&sortOrder=asc${CURSOR:+&cursor=$(jq -rn --arg c "$CURSOR" '$c|@uri')}"
pages=0; total=0; last=''
while :; do
  page=$(api_get "/admin/v1/orgs/${ORG_ID}/events-stream?${query}")
  n_rows=$(printf '%s' "$page" | jq -e '.data | if type == "array" then length else error("no data array") end')
  [ "$n_rows" -eq 0 ] || printf '%s' "$page" | jq -c '.data[]'
  total=$(( total + n_rows )); pages=$(( pages + 1 ))
  next=$(printf '%s' "$page" | jq -r '.meta.next // empty')
  [ -z "$next" ] || last="$next"
  # events-stream is a poll: it returns a cursor even at the end, so an empty page ends the walk.
  if [ -z "$next" ] || [ "$n_rows" -eq 0 ]; then break; fi
  if [ "$pages" -ge "$MAX_PAGES" ]; then
    echo "exported ${total} events in ${pages} pages; stopped at MAX_PAGES" >&2
    echo "ERROR: partial export. Resume with CURSOR=${last}" >&2
    exit 3
  fi
  query="from=${from_ms}&limit=500&sortOrder=asc&cursor=$(jq -rn --arg c "$next" '$c|@uri')"
  sleep "$PAGE_DELAY"
done
echo "exported ${total} events in ${pages} pages (since ${LOOKBACK_HOURS}h ago)" >&2
[ -z "$last" ] || echo "next poll: CURSOR=${last}" >&2
# HTH Guide Excerpt: end api-export-audit-log
