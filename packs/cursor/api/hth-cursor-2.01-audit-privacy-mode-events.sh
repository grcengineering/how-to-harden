#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cursor-2.1
#   guide:   https://howtoharden.com/guides/cursor/#21-enable-privacy-mode-for-sensitive-codebases
#   profile: L1
#   mode:    read-only
#   requires: CURSOR_ADMIN_API_KEY(team Admin API key from Dashboard > API Keys; audit logs need an Enterprise team), curl, jq
# =============================================================================
# HTH Cursor Control 2.1: Enable Privacy Mode for Sensitive Codebases
# Profile Level: L1 (Crawl) | NIST 800-53: SC-4
# Source: https://howtoharden.com/guides/cursor/#21-enable-privacy-mode-for-sensitive-codebases
#
# WHY AN AUDIT-LOG READ AND NOT A SETTINGS FILE.
# Cursor documents Privacy Mode as a dashboard (team) or in-app (individual)
# setting. There is no settings.json key and no MDM policy for it
# (https://cursor.com/docs/enterprise/privacy-and-data-governance,
# https://cursor.com/docs/enterprise/deployment-patterns — policy table), so a
# script that writes a "privacyMode" key into settings.json changes nothing.
# What Cursor DOES document is that Privacy Mode changes "at user or team level"
# are audit-logged, with event type `privacy_mode`, and readable through the
# Admin API (GET /teams/audit-logs). That is the evidence an auditor needs:
# "nobody turned Privacy Mode off during the period".
#
# Window: HTH_WINDOW (default 7d, the API's own default). The API rejects ranges
# longer than 30 days — run it more often rather than widening the window.
#
# Exit codes: 0 no Privacy Mode change in the window | 1 changes found (review
# each) | 2 precondition (missing key, HTTP error, plan without audit logs, or
# an HTTP 200 page without the documented events/pagination shape)
# =============================================================================

set -euo pipefail

[ -n "${CURSOR_ADMIN_API_KEY:-}" ] || { echo "PRECONDITION: set CURSOR_ADMIN_API_KEY — a team Admin API key (cursor.com/dashboard > API Keys)" >&2; exit 2; }
CURSOR_API_BASE="${CURSOR_API_BASE:-https://api.cursor.com}"
HTH_WINDOW="${HTH_WINDOW:-7d}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-cursor-201.XXXXXX")"
EVENTS="$(mktemp "${TMPDIR:-/tmp}/hth-cursor-201-events.XXXXXX")"
trap 'rm -f "${BODY_FILE}" "${EVENTS}"' EXIT

# GET <path>. The key reaches curl on stdin as a config line (-K -), never in
# argv, so it does not show up in the process list.
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
    *)   echo "PRECONDITION: GET $1 returned HTTP ${code}" >&2; exit 2 ;;
  esac
}

# HTH Guide Excerpt: begin api-audit-privacy-mode-events
# Pull every Privacy Mode change (user or team level) in the window, following
# pagination to the end, and report each one for review.
# A 200 is not proof of data: a page without the documented `events` array and
# `pagination.hasNextPage` flag is refused, so "no events" can only ever mean the
# API said there were none, never that the pack could not read what it got.
PAGE=1
while :; do
  api_get "/teams/audit-logs?eventTypes=privacy_mode&startTime=${HTH_WINDOW}&endTime=now&pageSize=500&page=${PAGE}"
  jq -e '(.events | type == "array") and (.pagination.hasNextPage | type == "boolean")' "${BODY_FILE}" >/dev/null 2>&1 || {
    echo "PRECONDITION: audit-logs page ${PAGE} returned HTTP 200 without the documented events/pagination shape — nothing was audited" >&2
    exit 2
  }
  jq -c '.events[]' "${BODY_FILE}" >> "${EVENTS}"
  [ "$(jq -r '.pagination.hasNextPage // false' "${BODY_FILE}")" = "true" ] || break
  PAGE=$((PAGE + 1))
  [ "${PAGE}" -le 100 ] || { echo "PRECONDITION: more than 100 pages — narrow HTH_WINDOW" >&2; exit 2; }
done

COUNT=$(wc -l < "${EVENTS}" | tr -d ' ')
echo "=== Privacy Mode changes in the last ${HTH_WINDOW} ==="
if [ "${COUNT}" -eq 0 ]; then
  echo "PASS: no privacy_mode events — Privacy Mode was not changed at user or team level"
  exit 0
fi
jq -r '"  \(.timestamp)  \(.user_email // "(unknown user)")  app=\(.application_type // "")  data=\(.event_data | tojson)"' "${EVENTS}"
echo "FINDING: ${COUNT} Privacy Mode change(s) — confirm each one left Privacy Mode ON and was authorized"
exit 1
# HTH Guide Excerpt: end api-audit-privacy-mode-events
