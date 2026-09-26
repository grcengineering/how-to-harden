#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: linear-4.1
#   guide:   https://howtoharden.com/guides/linear/#41-configure-audit-logs
#   profile: L1
#   mode:    read-only
#   requires: LINEAR_API_KEY(personal API key of a workspace OWNER; Read permission is enough), LINEAR_AUDIT_WINDOW_DAYS(optional; default 7)
# =============================================================================
# HTH Linear Control 4.1: Configure Audit Logs
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 8.2 | NIST 800-53 AU-2
# Source: https://howtoharden.com/guides/linear/#41-configure-audit-logs
# Dependencies: bash, curl (7.55+ for -H @-), jq
#
# Read-only audit: is the workspace audit log populated and readable for the
# recent window? Prints event-type counts only. Actor, email, and IP address are
# never requested.
#
# Vendor surface:
#   Query.auditEntries(filter: AuditEntryFilter), documented with this exact
#   query shape at https://linear.app/docs/audit-log ("auditEntries(first: 250)
#   { nodes { id type createdAt ... } }"). AuditEntryFilter.createdAt is a
#   DateComparator, and DateTimeOrDuration accepts ISO 8601 durations such as
#   "-P7D" (published schema,
#   https://raw.githubusercontent.com/linear/linear/master/packages/sdk/src/schema.graphql).
# Access: "Only workspace owners can access audit logs", Enterprise plan only,
#   90-day retention (https://linear.app/docs/audit-log). Any other key or plan
#   gets a GraphQL error and the run stops with exit 2. It never reads as an
#   empty, compliant log.
#
# TRAP 1: AN EMPTY WINDOW IS NOT A CLEAN BILL OF HEALTH. Zero entries means the
# scan saw nothing: an idle workspace, too short a window, or a log that isn't
# recording. That is UNDETERMINED (exit 2), never compliant.
#
# TRAP 2: STREAMING IS NOT READABLE. Whether "Stream logs" is on (Workspace
# Settings > Administration > Audit Log) is not exposed for reading
# (auditLogWebhookFailureEvents is [INTERNAL]). Confirm it in the console. This
# pack reports only what it can see.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition, error, or undetermined
# =============================================================================

set -Eeuo pipefail
trap 'echo "ERROR: unexpected failure at line ${LINENO}; no verdict was produced" >&2; exit 2' ERR

if [ "$#" -gt 0 ]; then
  echo "usage: $(basename "$0")   (no arguments; read-only audit)" >&2
  exit 2
fi
if [ -z "${LINEAR_API_KEY:-}" ]; then
  echo "PRECONDITION: LINEAR_API_KEY is not set (a Linear personal API key; Read permission is enough)" >&2
  exit 2
fi
LINEAR_API_URL="${LINEAR_API_URL:-https://api.linear.app/graphql}"
for bin in curl jq; do
  command -v "${bin}" >/dev/null 2>&1 || { echo "PRECONDITION: ${bin} not found" >&2; exit 2; }
done

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-linear-401.XXXXXX")"
TYPES_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-linear-401-types.XXXXXX")"
trap 'rm -f "${BODY_FILE}" "${TYPES_FILE}"' EXIT
GQL_DATA=""

gql_errors() {
  [ -s "${BODY_FILE}" ] || { echo "no response body (network, DNS, or TLS failure)"; return 0; }
  jq -r '[.errors[]? | (.message // "no message") + (if (.extensions.code // null) != null then " [" + (.extensions.code | tostring) + "]" else "" end)]
         | if length == 0 then "no error detail in body" else join("; ") end' "${BODY_FILE}" 2>/dev/null \
    || echo "response body is not JSON"
}

# gql QUERY [VARIABLES_JSON] -> GQL_DATA (the response's .data as compact JSON).
# Fail-closed: a transport error, any status but 200, a body that is not a JSON
# object, or a non-empty errors[] ends the run with exit 2. GraphQL can answer
# HTTP 200 with partial data plus errors[], and partial data is not evidence.
gql() {
  local query="$1" vars="${2:-}" payload code
  [ -n "${vars}" ] || vars='{}'
  payload="$(jq -nc --arg q "${query}" --argjson v "${vars}" '{query: $q, variables: $v}')"
  : > "${BODY_FILE}"
  # The key reaches curl on stdin (-H @-), never on its command line, where ps would show it.
  # errtrace is paused so a failed request is reported below, not by the ERR trap.
  set +E
  code="$(printf 'Authorization: %s\n' "${LINEAR_API_KEY}" \
    | curl -sS --max-time 60 -o "${BODY_FILE}" -w '%{http_code}' \
        -H @- -H 'Content-Type: application/json' \
        --data-binary "${payload}" "${LINEAR_API_URL}")" || code="000"
  set -E
  if [ "${code}" != "200" ]; then
    echo "PRECONDITION: ${LINEAR_API_URL} returned HTTP ${code}: $(gql_errors)" >&2
    exit 2
  fi
  if ! jq -e 'type == "object"' "${BODY_FILE}" >/dev/null 2>&1; then
    echo "PRECONDITION: the response body is not a JSON object" >&2
    exit 2
  fi
  if jq -e '(.errors // []) | length > 0' "${BODY_FILE}" >/dev/null; then
    echo "PRECONDITION: GraphQL errors: $(gql_errors)" >&2
    exit 2
  fi
  GQL_DATA="$(jq -c '.data // empty' "${BODY_FILE}")"
  if [ -z "${GQL_DATA}" ] || [ "${GQL_DATA}" = "null" ]; then
    echo "PRECONDITION: the response carried no data" >&2
    exit 2
  fi
}

dq() { printf '%s' "${GQL_DATA}" | jq "$@"; }

FINDINGS=0
UNDETERMINED=0
undetermined() { echo "UNDETERMINED: $*"; UNDETERMINED=$((UNDETERMINED + 1)); }
# Exit 0 only when every check was positively determined to be compliant.
verdict() {
  if [ "${FINDINGS}" -gt 0 ]; then echo "RESULT: ${FINDINGS} finding(s)"; exit 1; fi
  if [ "${UNDETERMINED}" -gt 0 ]; then echo "RESULT: no verdict (${UNDETERMINED} check(s) undetermined)"; exit 2; fi
  echo "RESULT: compliant: $1"
  exit 0
}

# HTH Guide Excerpt: begin audit-log-entries
Q_AUDIT='query HthLinearAuditEntries($since: DateTimeOrDuration!, $after: String) {
  auditEntries(first: 250, after: $after, filter: { createdAt: { gte: $since } }) {
    nodes { type createdAt } pageInfo { hasNextPage endCursor }
  }
}'
WINDOW_DAYS="${LINEAR_AUDIT_WINDOW_DAYS:-7}"

audit_log_entries() {
  case "${WINDOW_DAYS}" in
    ''|*[!0-9]*|0) echo "PRECONDITION: LINEAR_AUDIT_WINDOW_DAYS must be a whole number from 1 to 90 (got '${WINDOW_DAYS}')" >&2; exit 2 ;;
  esac
  if [ "${WINDOW_DAYS}" -gt 90 ]; then
    echo "PRECONDITION: LINEAR_AUDIT_WINDOW_DAYS exceeds Linear's 90-day audit retention" >&2
    exit 2
  fi
  local since="-P${WINDOW_DAYS}D" after="" more pages=0 vars count=0 page_count
  : > "${TYPES_FILE}"
  while :; do
    vars="$(jq -nc --arg s "${since}" --arg a "${after}" '{since: $s, after: (if $a == "" then null else $a end)}')"
    gql "${Q_AUDIT}" "${vars}"
    dq -r '.auditEntries.nodes[].type' >> "${TYPES_FILE}"
    page_count="$(dq '.auditEntries.nodes | length')"
    count=$((count + page_count))
    more="$(dq -r '.auditEntries.pageInfo.hasNextPage')"
    after="$(dq -r '.auditEntries.pageInfo.endCursor // ""')"
    pages=$((pages + 1))
    case "${more}" in
      false) break ;;
      true)  ;;
      *)     echo "PRECONDITION: auditEntries.pageInfo.hasNextPage came back as '${more}'" >&2; exit 2 ;;
    esac
    if [ -z "${after}" ] || [ "${pages}" -ge 400 ]; then
      echo "PRECONDITION: pagination of auditEntries stopped before the last page" >&2
      exit 2
    fi
  done

  echo "Linear 4.1: audit log, last ${WINDOW_DAYS} day(s)"
  echo "  entries read: ${count}"
  if [ "${count}" -eq 0 ]; then
    # TRAP 1
    undetermined "no audit entries in the last ${WINDOW_DAYS} day(s). An empty read is not evidence the log is recording; widen LINEAR_AUDIT_WINDOW_DAYS or generate a known event and re-run."
  else
    echo "  top event types:"
    sort "${TYPES_FILE}" | uniq -c | sort -rn | awk 'NR <= 10 {printf "    - %s: %s\n", $2, $1}'
  fi
  # TRAP 2
  echo "  stream logs to SIEM: NOT CHECKED. Not readable through the public API; confirm under Settings > Administration > Audit Log."
}
# HTH Guide Excerpt: end audit-log-entries

audit_log_entries
verdict "the audit log is readable and recorded events in the last ${WINDOW_DAYS} day(s)"
