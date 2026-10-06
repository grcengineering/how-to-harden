#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cursor-10.1
#   guide:   https://howtoharden.com/guides/cursor/#101-enable-cursor-usage-logging
#   profile: L2
#   mode:    read-only
#   requires: CURSOR_ADMIN_API_KEY(team Admin API key from Dashboard > API Keys; audit logs need an Enterprise team), HTH_WINDOW(optional, default 1d, max 30d), HTH_AUDIT_OUT(optional JSONL path), curl, jq
# =============================================================================
# HTH Cursor Control 10.1: Enable Cursor Usage Logging
# Profile Level: L2 (Walk) | NIST 800-53: AU-2, AU-6
# Source: https://howtoharden.com/guides/cursor/#101-enable-cursor-usage-logging
#
# Cursor's audit log is always on for Enterprise teams — there is nothing to
# "enable" — and self-serve streaming does not exist (streaming is arranged
# through hi@cursor.com). The documented pull path is the Admin API:
# GET /teams/audit-logs, rate limited to 20 requests/minute, max 30-day range
# (https://cursor.com/docs/account/teams/admin-api#get-audit-logs). Run this on
# a schedule and ship HTH_AUDIT_OUT to your SIEM.
#
# The summary also calls out event types that change security posture:
# privacy_mode, team_api_key, user_api_key, update_user_role, mcp_server_config,
# team_hook, team_settings.
#
# Exit codes: 0 exported | 2 precondition (missing key, HTTP error, no audit log
# on this plan, or an HTTP 200 page without the documented events/pagination
# shape). An empty window is reported, not treated as success silently.
# =============================================================================

set -euo pipefail

[ -n "${CURSOR_ADMIN_API_KEY:-}" ] || { echo "PRECONDITION: set CURSOR_ADMIN_API_KEY — a team Admin API key (cursor.com/dashboard > API Keys)" >&2; exit 2; }
CURSOR_API_BASE="${CURSOR_API_BASE:-https://api.cursor.com}"
HTH_WINDOW="${HTH_WINDOW:-1d}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-cursor-1001.XXXXXX")"
EVENTS="$(mktemp "${TMPDIR:-/tmp}/hth-cursor-1001-events.XXXXXX")"
trap 'rm -f "${BODY_FILE}" "${EVENTS}"' EXIT

# GET <path>. The key reaches curl on stdin as a config line (-K -), never in argv.
api_get() {
  local code rc
  set +e
  code=$(printf 'user = "%s:"\n' "${CURSOR_ADMIN_API_KEY}" \
    | curl -sS -K - -o "${BODY_FILE}" -w '%{http_code}' "${CURSOR_API_BASE}$1" 2>/dev/null)
  rc=$?
  set -e
  if [ "${rc}" -ne 0 ]; then echo "PRECONDITION: GET $1 — no HTTP response (curl exit ${rc})" >&2; exit 2; fi
  case "${code}" in
    200) return 0 ;;
    401) echo "PRECONDITION: GET $1 returned HTTP 401 — invalid key or missing scope" >&2; exit 2 ;;
    403) echo "PRECONDITION: GET $1 returned HTTP 403 — audit logs require an Enterprise team" >&2; exit 2 ;;
    429) echo "PRECONDITION: GET $1 returned HTTP 429 — rate limited (20/min); retry after 60s" >&2; exit 2 ;;
    *)   echo "PRECONDITION: GET $1 returned HTTP ${code}" >&2; exit 2 ;;
  esac
}

# HTH Guide Excerpt: begin api-export-audit-logs
# A 200 is not proof of data: a page without the documented `events` array and
# `pagination.hasNextPage` flag is refused rather than exported as zero events.
PAGE=1
while :; do
  api_get "/teams/audit-logs?startTime=${HTH_WINDOW}&endTime=now&pageSize=500&page=${PAGE}"
  jq -e '(.events | type == "array") and (.pagination.hasNextPage | type == "boolean")' "${BODY_FILE}" >/dev/null 2>&1 || {
    echo "PRECONDITION: audit-logs page ${PAGE} returned HTTP 200 without the documented events/pagination shape — nothing was exported" >&2
    exit 2
  }
  jq -c '.events[]' "${BODY_FILE}" >> "${EVENTS}"
  [ "$(jq -r '.pagination.hasNextPage // false' "${BODY_FILE}")" = "true" ] || break
  PAGE=$((PAGE + 1))
  [ "${PAGE}" -le 100 ] || { echo "PRECONDITION: more than 100 pages — narrow HTH_WINDOW" >&2; exit 2; }
done

COUNT=$(wc -l < "${EVENTS}" | tr -d ' ')
echo "=== Audit events in the last ${HTH_WINDOW}: ${COUNT} ==="
jq -s -r 'group_by(.event_type) | map("  \(.[0].event_type): \(length)") | .[]' "${EVENTS}"

echo "=== Posture-changing events (review each) ==="
jq -r 'select(.event_type | IN("privacy_mode","team_api_key","user_api_key","update_user_role","mcp_server_config","team_hook","team_settings"))
  | "  \(.timestamp)  \(.event_type)  by \(.user_email // "(unknown)")"' "${EVENTS}"

if [ -n "${HTH_AUDIT_OUT:-}" ]; then
  cp "${EVENTS}" "${HTH_AUDIT_OUT}"
  echo "Exported ${COUNT} event(s) as JSONL to ${HTH_AUDIT_OUT}"
fi
[ "${COUNT}" -gt 0 ] || echo "NOTE: zero events — confirm the window and that this key belongs to the Enterprise team"
exit 0
# HTH Guide Excerpt: end api-export-audit-logs
