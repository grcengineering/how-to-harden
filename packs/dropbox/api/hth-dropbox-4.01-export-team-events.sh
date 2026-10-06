#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: dropbox-4.1
#   guide:   https://howtoharden.com/guides/dropbox/#41-enable-audit-logging
#   profile: L1
#   mode:    read-only
#   requires: DROPBOX_TEAM_TOKEN(team-scoped access token with events.read), HTH_DROPBOX_EVENTS_START(optional ISO 8601), HTH_DROPBOX_EVENTS_END(optional ISO 8601), HTH_DROPBOX_EVENTS_CATEGORY(optional)
# =============================================================================
# HTH Dropbox Control 4.1: Enable Audit Logging
# Profile Level: L1 (Crawl)
# Frameworks: NIST 800-53 AU-2, AU-3
# Source: https://howtoharden.com/guides/dropbox/#41-enable-audit-logging
# Dependencies: curl, jq
# Token: a token generated in the Dropbox App Console carries more than the
#   requires: line above lists. The console would not save team scopes without
#   team_data.member, and ticking team_data.member locks team_data.governance.read
#   and team_data.governance.write on (observed 2026-09-25). This pack calls read
#   routes only, but the token it runs with can write: store and rotate it as a
#   write-capable credential.
#
# WHY THIS IS AN EXPORTER. The Activity page produces CSV reports by hand and
# streams nothing. The continuous feed the guide says you must build yourself
# is team_log/get_events + team_log/get_events/continue (events.read) - the
# same event log, returned as JSON. This pack pulls one time window of it and
# writes one event per line (NDJSON) to stdout, so a scheduler or log shipper
# can wrap it. Every diagnostic goes to stderr, so `> events.ndjson` stays clean.
#
# There is nothing to enable and nothing to write: the log is always on, and no
# endpoint sets its retention or a destination.
#
# TRAP 1: `has_more` may be true while `events` is empty. Keep calling
#   get_events/continue until has_more is false; an empty page is not the end.
# TRAP 2: the cursor can change on every response and old cursors expire, so
#   each call uses the cursor from the response before it, never an earlier one.
# TRAP 3: events are not guaranteed to be sorted by timestamp.
# TRAP 4: "the file_operations category ... [is] not available on all Dropbox
#   Business plans". Dropbox does not document how a plan without it answers a
#   file_operations filter, so this pack treats both possible answers as
#   not-clean: an HTTP error is a precondition (exit 2) and an empty window is
#   "no events returned" (exit 1, TRAP 6).
# TRAP 5: time.start_time is inclusive and time.end_time is exclusive. Reuse
#   one run's end as the next run's start, unchanged, for a gap-free feed.
# TRAP 6: a window that returns zero events is NOT success. It exits 1 with
#   "no events returned", because an empty feed and a broken feed look the same
#   downstream.
# TRAP 7: has_more with no cursor, or 5000 pages with has_more still true, exits
#   2. Events already written to stdout are then a partial window, not a feed.
#
# Exit codes: 0 exported >=1 event | 1 no events in window | 2 precondition
# =============================================================================

set -euo pipefail

[ -n "${DROPBOX_TEAM_TOKEN:-}" ] || { echo "PRECONDITION: set DROPBOX_TEAM_TOKEN to a team-scoped access token with events.read" >&2; exit 2; }
DROPBOX_API_BASE="${DROPBOX_API_BASE:-https://api.dropboxapi.com/2}"
CATEGORY="${HTH_DROPBOX_EVENTS_CATEGORY:-}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-dropbox.XXXXXX")" || { echo "PRECONDITION: mktemp failed" >&2; exit 2; }
trap 'rm -f "${BODY_FILE}"' EXIT
RPC_CODE=""; RPC_BODY=""

# Every Dropbox RPC route is an HTTP POST with a JSON body. curl implies POST
# when --data is given. The bearer token reaches curl on stdin (-K -), never argv.
rpc() { # rpc <route> <json-body> [extra curl header args...]
  local route="$1" body="$2" rc
  shift 2
  set +e
  RPC_CODE=$(printf 'header = "Authorization: Bearer %s"\n' "${DROPBOX_TEAM_TOKEN}" |
    curl -sS --max-time 60 -K - -o "${BODY_FILE}" -w '%{http_code}' \
      -H "Content-Type: application/json" "$@" \
      --data "${body}" "${DROPBOX_API_BASE}/${route}" 2>/dev/null)
  rc=$?
  set -e
  [ "${rc}" -eq 0 ] || RPC_CODE="000"
  RPC_BODY="$(cat "${BODY_FILE}" 2>/dev/null || true)"
}

rpc_strict() {
  rpc "$@"
  [ "${RPC_CODE}" = "200" ] && return 0
  local summary
  summary=$(printf '%s' "${RPC_BODY}" | jq -r '.error_summary // empty' 2>/dev/null || true)
  case "${RPC_CODE}" in
    000) echo "PRECONDITION: $1 - no HTTP response (network, DNS or TLS failure)" >&2 ;;
    401) echo "PRECONDITION: $1 returned HTTP 401 (${summary:-no summary}) - token invalid or expired, or missing the scope this route needs" >&2 ;;
    403) echo "PRECONDITION: $1 returned HTTP 403 (${summary:-no summary}) - the team or plan cannot use this route" >&2 ;;
    409) echo "PRECONDITION: $1 returned HTTP 409 (${summary:-no summary}) - e.g. invalid_time_range, invalid_filters, or a category this plan does not serve" >&2 ;;
    429) echo "PRECONDITION: $1 returned HTTP 429 - rate limited; retry after the Retry-After interval" >&2 ;;
    *)   echo "PRECONDITION: $1 returned HTTP ${RPC_CODE}: ${summary:-$(printf '%s' "${RPC_BODY}" | head -c 200)}" >&2 ;;
  esac
  exit 2
}

# HTH Guide Excerpt: begin team-log-ndjson-export
# Portable ISO 8601: GNU and BSD date disagree on relative arithmetic.
iso_now()       { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
iso_hours_ago() {
  date -u -d "$1 hours ago" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null \
    || date -u -v-"$1"H '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null \
    || { echo "PRECONDITION: neither GNU nor BSD date worked - set HTH_DROPBOX_EVENTS_START" >&2; exit 2; }
}

END="${HTH_DROPBOX_EVENTS_END:-$(iso_now)}"
START="${HTH_DROPBOX_EVENTS_START:-$(iso_hours_ago 24)}"
echo "window [start, end) = [${START}, ${END})  (reuse end, unchanged, as the next start)" >&2

# category and event_type must not be combined; this pack only filters by category.
body=$(jq -nc --arg s "${START}" --arg e "${END}" --arg c "${CATEGORY}" \
  '{limit: 1000, time: {start_time: $s, end_time: $e}}
   + (if $c == "" then {} else {category: {".tag": $c}} end)')
route="team_log/get_events"; pages=0; emitted=0
while :; do
  rpc_strict "${route}" "${body}"
  n=$(printf '%s' "${RPC_BODY}" | jq '(.events // []) | length')
  printf '%s' "${RPC_BODY}" | jq -c '.events[]?'
  emitted=$((emitted + n))
  more=$(printf '%s' "${RPC_BODY}" | jq -r '.has_more // false')
  cursor=$(printf '%s' "${RPC_BODY}" | jq -r '.cursor // ""')
  pages=$((pages + 1))
  # TRAP 1 + TRAP 2: follow the newest cursor until has_more is false.
  [ "${more}" = "true" ] || break
  if [ -z "${cursor}" ]; then
    echo "PRECONDITION: ${route} answered has_more=true with no cursor after ${pages} page(s) - the window cannot be exported to the end; ${emitted} event(s) already written are a partial window" >&2
    exit 2
  fi
  if [ "${pages}" -ge 5000 ]; then
    echo "PRECONDITION: stopped after ${pages} pages with has_more still true - narrow the window and re-run" >&2
    exit 2
  fi
  route="team_log/get_events/continue"
  body=$(jq -nc --arg c "${cursor}" '{cursor: $c}')
done

echo "pages: ${pages} | events exported: ${emitted}" >&2
if [ "${emitted}" -eq 0 ]; then
  echo "no events returned for [${START}, ${END})${CATEGORY:+ in category ${CATEGORY}} - not a success: an empty feed and a broken feed look the same downstream" >&2
  exit 1
fi
exit 0
# HTH Guide Excerpt: end team-log-ndjson-export
