#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: asana-4.1
#   guide:   https://howtoharden.com/guides/asana/#41-configure-audit-logging
#   profile: L1
#   mode:    read-only
#   requires: ASANA_SERVICE_ACCOUNT_PAT(service account with Scoped permissions > Audit logs; Enterprise+ or Legacy Enterprise), ASANA_WORKSPACE_GID, ASANA_START_AT(optional ISO-8601, default 24h ago), ASANA_END_AT(optional ISO-8601)
# =============================================================================
# HTH Asana Control 4.1: Configure Audit Logging
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 8.2 | NIST 800-53 AU-2
# Source: https://howtoharden.com/guides/asana/#41-configure-audit-logging
# Dependencies: bash, curl (7.55+ for -H @file), jq, date
# API (verified against Asana's OpenAPI spec asana_oas.yaml and
#      https://developers.asana.com/docs/audit-log-events, 2026-09-24):
#   GET /workspaces/{workspace_gid}/audit_log_events   getAuditLogEvents
#   query: start_at (inclusive), end_at (exclusive), event_type, actor_type, actor_gid,
#          resource_gid, limit (1-100), offset. Events are returned oldest first.
#
# The collector a SIEM runs: every event in [start_at, end_at) is written to
# stdout as one JSON object per line (NDJSON); progress and the summary go to
# stderr so stdout stays clean for the shipper. Schedule it well inside the
# 90-day retention window with overlapping windows (hourly, 2h window) and
# de-duplicate on the event `gid` downstream.
#
# ── TRAP 1: the stream never ends on its own ────────────────────────────────
# Asana keeps returning next_page for a filter with matches "even when there are
# no more events", so the stream can be polled forever. An empty data page is
# the end of the current events; the loop stops there.
#
# ── TRAP 2: retention is 90 days ────────────────────────────────────────────
# Events are "permanently deleted from our systems after 90 days". A start_at
# older than that exports less than it appears to; the pack warns on stderr.
#
# ── TRAP 3: zero events is only an answer after a 200 ───────────────────────
# Every non-200 exits 2 with nothing claimed. An empty window after HTTP 200 is
# a real answer, and the summary says it was an empty window, not a clean one.
#
# Exit codes: 0 exported (including an empty window) | 2 precondition (auth, tier, network, bad input, unexpected error)
# =============================================================================

set -eEuo pipefail
trap 'echo "PRECONDITION: unexpected failure at line ${LINENO}" >&2; exit 2' ERR

# A missing input is a precondition (exit 2), never a finding (exit 1).
need() { if [ -z "${!1:-}" ]; then echo "PRECONDITION: set $1 — $2" >&2; exit 2; fi; }
need ASANA_SERVICE_ACCOUNT_PAT "service account token scoped to Audit logs"
need ASANA_WORKSPACE_GID "the workspace gid of the organization"
ASANA_API_BASE="${ASANA_API_BASE:-https://app.asana.com/api/1.0}"
# BSD date (macOS) first, GNU date second.
START_AT="${ASANA_START_AT:-$(date -u -v-24H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)}"
RETENTION_FLOOR=$(date -u -v-90d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '90 days ago' +%Y-%m-%dT%H:%M:%SZ)

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }
for ts in "${START_AT}" "${ASANA_END_AT:-}"; do
  case "${ts}" in
    ""|[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T*) ;;
    *) echo "PRECONDITION: timestamps must be ISO-8601 (e.g. 2026-09-24T00:00:00Z)" >&2; exit 2 ;;
  esac
done
if [[ "${START_AT}" < "${RETENTION_FLOOR}" ]]; then
  echo "WARNING: start_at ${START_AT} is older than the 90-day retention floor; earlier events no longer exist (TRAP 2)" >&2
fi

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-asana-401.XXXXXX")"
trap 'rm -f "${BODY_FILE}"' EXIT

# One GET. Fails closed: anything but HTTP 200 with a data array exits 2.
# The token reaches curl through a process-substitution header file, never argv.
asana_get() {
  local code rc=0
  code=$(curl -sS --max-time 120 -o "${BODY_FILE}" -w '%{http_code}' \
    -H @<(printf 'Authorization: Bearer %s\n' "${ASANA_SERVICE_ACCOUNT_PAT}") \
    -H 'Accept: application/json' "${ASANA_API_BASE}$1" 2>/dev/null) || rc=$?
  if [ "${rc}" -ne 0 ]; then
    echo "PRECONDITION: GET ${1%%\?*} got no HTTP response (curl exit ${rc})" >&2; exit 2
  fi
  if [ "${code}" != "200" ]; then
    echo "PRECONDITION: GET ${1%%\?*} returned HTTP ${code}: $(jq -r '[.errors[]?.message] | join("; ")' "${BODY_FILE}" 2>/dev/null || true)" >&2
    echo "  The Audit Log API needs a service account token with the Audit logs scope (Enterprise+ or Legacy Enterprise)." >&2
    exit 2
  fi
  if ! jq -e 'type == "object" and (.data | type == "array")' "${BODY_FILE}" >/dev/null 2>&1; then
    echo "PRECONDITION: GET ${1%%\?*} returned no data array" >&2; exit 2
  fi
}

# HTH Guide Excerpt: begin audit-log-export
query="start_at=${START_AT}&limit=100"
[ -z "${ASANA_END_AT:-}" ] || query="${query}&end_at=${ASANA_END_AT}"
offset=""; pages=0; events=0
while :; do
  if [ -n "${offset}" ]; then
    asana_get "/workspaces/${ASANA_WORKSPACE_GID}/audit_log_events?${query}&offset=${offset}"
  else
    asana_get "/workspaces/${ASANA_WORKSPACE_GID}/audit_log_events?${query}"
  fi
  pages=$((pages + 1))
  n=$(jq '.data | length' "${BODY_FILE}")
  [ "${n}" -gt 0 ] || break                       # TRAP 1: empty page = end of current events
  jq -c '.data[]' "${BODY_FILE}"                  # NDJSON to stdout for the SIEM shipper
  events=$((events + n))
  offset=$(jq -r '.next_page.offset // "" | @uri' "${BODY_FILE}")
  [ -n "${offset}" ] || break
  if [ "${pages}" -ge 5000 ]; then echo "PRECONDITION: audit log paging exceeded 5000 pages" >&2; exit 2; fi
done
# HTH Guide Excerpt: end audit-log-export

if [ "${events}" -eq 0 ]; then
  echo "exported 0 events: HTTP 200 on every page, empty window [${START_AT}, ${ASANA_END_AT:-now}) (TRAP 3)" >&2
else
  echo "exported ${events} events across ${pages} page(s) for [${START_AT}, ${ASANA_END_AT:-now})" >&2
fi
exit 0
