#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cursor-3.3
#   guide:   https://howtoharden.com/guides/cursor/#33-monitor-api-key-usage-and-costs
#   profile: L2
#   mode:    read-only
#   requires: CURSOR_ADMIN_API_KEY(team Admin API key from Dashboard > API Keys), HTH_SPEND_ALERT_DOLLARS(optional, default 200), curl, jq
# =============================================================================
# HTH Cursor Control 3.3: Monitor API Key Usage and Costs
# Profile Level: L2 (Walk)
# Source: https://howtoharden.com/guides/cursor/#33-monitor-api-key-usage-and-costs
#
# Covers the Cursor-billed half of this control. Provider-side usage and
# billing alerts for keys you bring yourself (OpenAI, Anthropic) live in those
# providers' consoles. For team usage billed by Cursor, the Admin API returns
# per-member spend for the current billing cycle with the limit actually
# enforced on each member (POST /teams/spend,
# https://cursor.com/docs/account/teams/admin-api#get-spending-data).
#
# /teams/spend is a READ that happens to use POST (it takes a JSON body). No -X
# flag is used: curl implies POST when -d is given, so the file carries no
# mutation verb and nothing on the team is changed.
#
# Flags: a member whose cycle spend exceeds HTH_SPEND_ALERT_DOLLARS, and a
# member with no effective per-user limit (a leaked session or runaway agent on
# that account has no ceiling).
#
# Exit codes: 0 pass | 1 finding | 2 precondition (incl. an HTTP 200 whose body
# lacks the documented teamMemberSpend shape, or that lists zero members)
# =============================================================================

set -euo pipefail

[ -n "${CURSOR_ADMIN_API_KEY:-}" ] || { echo "PRECONDITION: set CURSOR_ADMIN_API_KEY — a team Admin API key (cursor.com/dashboard > API Keys)" >&2; exit 2; }
CURSOR_API_BASE="${CURSOR_API_BASE:-https://api.cursor.com}"
HTH_SPEND_ALERT_DOLLARS="${HTH_SPEND_ALERT_DOLLARS:-200}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }
case "${HTH_SPEND_ALERT_DOLLARS}" in ''|*[!0-9]*) echo "PRECONDITION: HTH_SPEND_ALERT_DOLLARS must be a whole number" >&2; exit 2 ;; esac

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-cursor-303.XXXXXX")"
ROWS="$(mktemp "${TMPDIR:-/tmp}/hth-cursor-303-rows.XXXXXX")"
trap 'rm -f "${BODY_FILE}" "${ROWS}"' EXIT

# POST-as-read <path> <json>. The key reaches curl on stdin (-K -), never in argv.
api_read() {
  local code rc
  set +e
  code=$(printf 'user = "%s:"\n' "${CURSOR_ADMIN_API_KEY}" \
    | curl -sS -K - -o "${BODY_FILE}" -w '%{http_code}' \
        -H "Content-Type: application/json" -d "$2" "${CURSOR_API_BASE}$1" 2>/dev/null)
  rc=$?
  set -e
  if [ "${rc}" -ne 0 ]; then echo "PRECONDITION: $1 — no HTTP response (curl exit ${rc})" >&2; exit 2; fi
  case "${code}" in
    200) return 0 ;;
    401) echo "PRECONDITION: $1 returned HTTP 401 — invalid key or missing scope" >&2; exit 2 ;;
    403) echo "PRECONDITION: $1 returned HTTP 403 — not available for this team's plan" >&2; exit 2 ;;
    *)   echo "PRECONDITION: $1 returned HTTP ${code}" >&2; exit 2 ;;
  esac
}

# HTH Guide Excerpt: begin api-audit-team-spend
# A 200 is not proof of data: a proxy, a captive portal or an API change can
# answer 200 with a body this pack cannot read. Every page must carry the
# documented teamMemberSpend array with numeric spend and limit fields, or the
# pack refuses to report (a missing spend field would otherwise read as $0).
SHAPE='(.teamMemberSpend | type == "array")
  and ((.totalPages // 1) | type == "number")
  and all(.teamMemberSpend[]; (.overallSpendCents | type == "number")
                              and (.effectivePerUserLimitDollars | type == "number"))'
PAGE=1
while :; do
  api_read "/teams/spend" "{\"page\": ${PAGE}, \"pageSize\": 100, \"sortBy\": \"amount\", \"sortDirection\": \"desc\"}"
  jq -e "${SHAPE}" "${BODY_FILE}" >/dev/null 2>&1 || {
    echo "PRECONDITION: /teams/spend page ${PAGE} returned HTTP 200 without the documented teamMemberSpend shape — nothing was audited" >&2
    exit 2
  }
  jq -c '.teamMemberSpend[]' "${BODY_FILE}" >> "${ROWS}"
  TOTAL_PAGES=$(jq -r '.totalPages // 1' "${BODY_FILE}")
  [ "${PAGE}" -lt "${TOTAL_PAGES}" ] || break
  PAGE=$((PAGE + 1))
  [ "${PAGE}" -le 100 ] || { echo "PRECONDITION: more than 100 pages of spend data" >&2; exit 2; }
done

MEMBERS=$(wc -l < "${ROWS}" | tr -d ' ')
# Every team has at least one member (the admin who issued this key), so an
# empty list means the response did not describe the team: not a clean team.
[ "${MEMBERS}" -gt 0 ] || { echo "PRECONDITION: /teams/spend returned zero members — nothing was audited" >&2; exit 2; }
echo "=== Current billing cycle: ${MEMBERS} members ==="
LIMIT_CENTS=$((HTH_SPEND_ALERT_DOLLARS * 100))
OVER=$(jq -s --argjson c "${LIMIT_CENTS}" '[.[] | select((.overallSpendCents // 0) > $c)] | length' "${ROWS}")
NOLIMIT=$(jq -s '[.[] | select((.effectivePerUserLimitDollars // 0) <= 0 and .monthlyLimitDollars == null)] | length' "${ROWS}")

jq -s -r --argjson c "${LIMIT_CENTS}" '.[] | select((.overallSpendCents // 0) > $c)
  | "  OVER ALERT: \(.email)  $\((.overallSpendCents / 100 * 100 | floor) / 100)  limit=$\(.effectivePerUserLimitDollars // "none")"' "${ROWS}"
jq -s -r '.[] | select((.effectivePerUserLimitDollars // 0) <= 0 and .monthlyLimitDollars == null)
  | "  NO LIMIT: \(.email)"' "${ROWS}"

if [ "${OVER}" -eq 0 ] && [ "${NOLIMIT}" -eq 0 ]; then
  echo "PASS: every member has a spend limit and none is above \$${HTH_SPEND_ALERT_DOLLARS} this cycle"
  exit 0
fi
echo "FINDING: ${OVER} member(s) above \$${HTH_SPEND_ALERT_DOLLARS}, ${NOLIMIT} member(s) with no per-user limit"
exit 1
# HTH Guide Excerpt: end api-audit-team-spend
