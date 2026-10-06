#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: miro-4.1
#   guide:   https://howtoharden.com/guides/miro/#41-audit-logs-enterprise
#   profile: L1
#   mode:    read-only
#   requires: MIRO_ACCESS_TOKEN(OAuth access token issued by a Company Admin; scope auditlogs:read only), MIRO_AUDIT_SINCE(optional), MIRO_AUDIT_UNTIL(optional)
# =============================================================================
# HTH Miro Control 4.1: Audit Logs (Enterprise)
# Profile Level: L1 (Crawl)
# Frameworks: NIST 800-53 AU-2, AU-3
# Source: https://howtoharden.com/guides/miro/#41-audit-logs-enterprise
# Dependencies: curl, jq
#
# WHAT THIS DOES. Pulls every audit event in a time window and writes them to
# stdout as one JSON object per line, ready for a SIEM or archive; a summary goes
# to stderr. Schedule it well inside the organization's audit-log retention
# period — events deleted by retention cannot be recovered.
#   GET /v2/audit/logs?createdAfter=…&createdBefore=…&limit=100&sorting=ASC[&cursor=…]
#       enterprise-get-audit-logs  (scope auditlogs:read)
# Window defaults to the last 24 hours. Override with MIRO_AUDIT_SINCE /
# MIRO_AUDIT_UNTIL in the documented format, e.g. 2026-09-24T00:00:00.000Z.
#
# ── TRAP 1: the API window is the retention period, not a fixed 90 days ──────
# The endpoint "retrieves a page of audit events within your organization's
# configured audit log retention period". Retention is 30, 90, 180 or 365 days
# (Company settings > Security > Audit logs > Settings), 180 by default, and
# "Once audit logs are deleted, they can't be recovered."
#
# ── TRAP 2: an empty pull is a pipeline finding, not a quiet day ─────────────
# Any active organization produces events. Zero events in the window exits 1
# so a broken schedule, a wrong window or a token that can see nothing alerts.
# Set MIRO_AUDIT_ALLOW_EMPTY=1 only for a window you know was idle.
#
# ── TRAP 3: a truncated pull must never look complete ────────────────────────
# Pagination follows the documented cursor to the end. A repeated cursor or
# more than MIRO_AUDIT_MAX_PAGES pages (default 1000) exits 2, even though some
# events were already written, so a scheduler never records a partial window as
# delivered.
#
# ── TRAP 4: events carry personal data ───────────────────────────────────────
# createdBy includes the actor's name and email. Send stdout only to the SIEM or
# archive that is meant to hold it.
#
# Exit codes: 0 events pulled | 1 zero events (pipeline finding) | 2 precondition
# =============================================================================

set -euo pipefail

: "${MIRO_ACCESS_TOKEN:?set MIRO_ACCESS_TOKEN — a Miro OAuth access token issued by a Company Admin with auditlogs:read}"
MIRO_API_BASE="${MIRO_API_BASE:-https://api.miro.com}"
MIRO_AUDIT_MAX_PAGES="${MIRO_AUDIT_MAX_PAGES:-1000}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

precondition() { echo "PRECONDITION: $*" >&2; exit 2; }

TS_RE='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}Z$'
SINCE="${MIRO_AUDIT_SINCE:-$(jq -rn 'now - 86400 | strftime("%Y-%m-%dT%H:%M:%S.000Z")')}"
UNTIL="${MIRO_AUDIT_UNTIL:-$(jq -rn 'now | strftime("%Y-%m-%dT%H:%M:%S.000Z")')}"
printf '%s' "${SINCE}" | grep -Eq "${TS_RE}" || precondition "MIRO_AUDIT_SINCE must look like 2026-09-24T00:00:00.000Z"
printf '%s' "${UNTIL}" | grep -Eq "${TS_RE}" || precondition "MIRO_AUDIT_UNTIL must look like 2026-09-24T00:00:00.000Z"
[ "${SINCE}" \< "${UNTIL}" ] || precondition "MIRO_AUDIT_SINCE must be earlier than MIRO_AUDIT_UNTIL"
case "${MIRO_AUDIT_MAX_PAGES}" in ''|*[!0-9]*) precondition "MIRO_AUDIT_MAX_PAGES must be a whole number" ;; esac

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-miro.XXXXXX")"
trap 'rm -f "${BODY_FILE}"' EXIT
HTTP_CODE=""; BODY=""

# GET only — no -X flag anywhere, so check 14 sees a read-only file.
api_get() {
  local label="$1" path="$2" rc code msg
  set +e
  HTTP_CODE=$(curl -sS -o "${BODY_FILE}" -w '%{http_code}' \
    -H "Authorization: Bearer ${MIRO_ACCESS_TOKEN}" \
    -H "Accept: application/json" \
    "${MIRO_API_BASE}${path}" 2>/dev/null)
  rc=$?
  set -e
  [ "${rc}" -eq 0 ] || HTTP_CODE="000"
  BODY=$(cat "${BODY_FILE}" 2>/dev/null || true)
  if [ "${HTTP_CODE}" = "200" ]; then
    printf '%s' "${BODY}" | jq -e . >/dev/null 2>&1 || precondition "GET ${label} returned 200 with a body that is not JSON"
    return 0
  fi
  code=$(printf '%s' "${BODY}" | jq -r '.code // "unknown"' 2>/dev/null || echo unknown)
  msg=$(printf '%s' "${BODY}" | jq -r '.message // "no message"' 2>/dev/null || echo "no message")
  case "${HTTP_CODE}" in
    000)     precondition "GET ${label} — no HTTP response (network, DNS, or TLS failure)" ;;
    401)     precondition "GET ${label} returned 401 (${code}) — the token is invalid or expired" ;;
    403|404) precondition "GET ${label} returned ${HTTP_CODE} (${code}) — needs an Enterprise org, a Company Admin token, and scope auditlogs:read. ${msg}" ;;
    429)     precondition "GET ${label} returned 429 — rate limited; re-run later" ;;
    *)       precondition "GET ${label} returned HTTP ${HTTP_CODE} (${code}) — ${msg}" ;;
  esac
}

# HTH Guide Excerpt: begin audit-log-pull
# Walk the window page by page, emit each event as one JSON line, and refuse to
# report success on a window that returned nothing or was cut short.
EVENTS=0; PAGES=0; CURSOR=""; PREV=""
BASE_Q="createdAfter=$(jq -rn --arg v "${SINCE}" '$v|@uri')&createdBefore=$(jq -rn --arg v "${UNTIL}" '$v|@uri')&limit=100&sorting=ASC"
while :; do
  Q="${BASE_Q}"
  [ -z "${CURSOR}" ] || Q="${Q}&cursor=$(jq -rn --arg c "${CURSOR}" '$c|@uri')"
  api_get "/v2/audit/logs" "/v2/audit/logs?${Q}"
  printf '%s' "${BODY}" | jq -e '.data | type == "array"' >/dev/null 2>&1 || precondition "audit page has no data array"
  printf '%s' "${BODY}" | jq -c '.data[]'
  EVENTS=$((EVENTS + $(printf '%s' "${BODY}" | jq '.data | length')))
  PAGES=$((PAGES + 1))
  PREV="${CURSOR}"
  CURSOR=$(printf '%s' "${BODY}" | jq -r '.cursor // ""')
  [ -n "${CURSOR}" ] || break
  [ "${CURSOR}" != "${PREV}" ] || precondition "audit pagination repeated its cursor after ${EVENTS} events — window NOT complete"
  [ "${PAGES}" -lt "${MIRO_AUDIT_MAX_PAGES}" ] || precondition "audit pull hit ${MIRO_AUDIT_MAX_PAGES} pages after ${EVENTS} events — window NOT complete; narrow it"
done

echo "Miro 4.1 — audit events ${SINCE} .. ${UNTIL}: ${EVENTS} events in ${PAGES} page(s)" >&2
if [ "${EVENTS}" -eq 0 ] && [ "${MIRO_AUDIT_ALLOW_EMPTY:-0}" != "1" ]; then
  echo "  FINDING: zero audit events in the window — treat as a broken export until proven idle" >&2
  exit 1
fi
# HTH Guide Excerpt: end audit-log-pull
exit 0
