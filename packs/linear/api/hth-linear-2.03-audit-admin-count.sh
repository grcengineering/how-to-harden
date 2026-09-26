#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: linear-2.3
#   guide:   https://howtoharden.com/guides/linear/#23-limit-admin-access
#   profile: L1
#   mode:    read-only
#   requires: LINEAR_API_KEY(personal API key; Read permission is enough), LINEAR_MAX_ADMINS(optional; default 3)
# =============================================================================
# HTH Linear Control 2.3: Limit Admin Access
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 5.4 | NIST 800-53 AC-6(1)
# Source: https://howtoharden.com/guides/linear/#23-limit-admin-access
# Dependencies: bash, curl (7.55+ for -H @-), jq
#
# Read-only audit: how many active humans hold the owner or admin role, measured
# against a ceiling you set. Counts only; no name or email is printed.
#
# Vendor surface (Linear's published GraphQL schema,
# https://raw.githubusercontent.com/linear/linear/master/packages/sdk/src/schema.graphql):
#   Query.users (UserConnection, paginated; disabled users excluded by default)
#     User.owner ("the highest permission level"), User.admin, User.app
#   Organization.securitySettings.adminManagementRole: UserRoleType
#     ("The minimum role required to grant or revoke the workspace admin role";
#     reported for context, not judged)
# Console: Settings > Administration > Members, or Cmd/Ctrl K > "View workspace
#   admins" (https://linear.app/docs/members-roles).
#
# TRAP 1: OWNERS AND ADMINS SKIP LOGIN RESTRICTIONS. Linear lets the highest role
# sign in with any method so it can't be locked out
# (https://linear.app/docs/login-methods). Each extra admin is one more account
# that bypasses control 1.2, so the ceiling matters more here than in most tools.
#
# TRAP 2: FREE PLAN. "On Free plans, all users are Admins." A Free workspace with
# more humans than the ceiling fails this check by construction. That is
# accurate, because the control cannot be met on that plan.
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

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-linear-203.XXXXXX")"
NODES_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-linear-203-nodes.XXXXXX")"
trap 'rm -f "${BODY_FILE}" "${NODES_FILE}"' EXIT
GQL_DATA=""
PAGE_NODES="[]"

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

# paginate QUERY FIELD -> PAGE_NODES (every node of connection FIELD, all pages).
# QUERY takes `$after: String` and selects `nodes` and
# `pageInfo { hasNextPage endCursor }`. A run that cannot reach the last page
# stops with exit 2 rather than judging a truncated list.
paginate() {
  local query="$1" field="$2" after="" more pages=0 vars
  : > "${NODES_FILE}"
  while :; do
    if [ -n "${after}" ]; then vars="$(jq -nc --arg a "${after}" '{after: $a}')"; else vars='{"after": null}'; fi
    gql "${query}" "${vars}"
    dq -c --arg f "${field}" '.[$f].nodes[]' >> "${NODES_FILE}"
    more="$(dq -r --arg f "${field}" '.[$f].pageInfo.hasNextPage')"
    after="$(dq -r --arg f "${field}" '.[$f].pageInfo.endCursor // ""')"
    pages=$((pages + 1))
    case "${more}" in
      false) break ;;
      true)  ;;
      *)     echo "PRECONDITION: ${field}.pageInfo.hasNextPage came back as '${more}'" >&2; exit 2 ;;
    esac
    if [ -z "${after}" ] || [ "${pages}" -ge 400 ]; then
      echo "PRECONDITION: pagination of ${field} stopped before the last page" >&2
      exit 2
    fi
  done
  PAGE_NODES="$(jq -s -c '.' "${NODES_FILE}")"
}

FINDINGS=0
UNDETERMINED=0
finding()      { echo "FINDING: $*"; FINDINGS=$((FINDINGS + 1)); }
undetermined() { echo "UNDETERMINED: $*"; UNDETERMINED=$((UNDETERMINED + 1)); }
# Exit 0 only when every check was positively determined to be compliant.
verdict() {
  if [ "${FINDINGS}" -gt 0 ]; then echo "RESULT: ${FINDINGS} finding(s)"; exit 1; fi
  if [ "${UNDETERMINED}" -gt 0 ]; then echo "RESULT: no verdict (${UNDETERMINED} check(s) undetermined)"; exit 2; fi
  echo "RESULT: compliant: $1"
  exit 0
}

# HTH Guide Excerpt: begin audit-admin-count
Q_USERS='query HthLinearPrivilegedUsers($after: String) {
  users(first: 250, after: $after) { nodes { active admin owner app } pageInfo { hasNextPage endCursor } }
}'
Q_ADMIN_MGMT='query HthLinearAdminManagement { organization { securitySettings } }'
MAX_ADMINS="${LINEAR_MAX_ADMINS:-3}"
PRIVILEGED=0

audit_admin_count() {
  case "${MAX_ADMINS}" in
    ''|*[!0-9]*|0) echo "PRECONDITION: LINEAR_MAX_ADMINS must be a whole number of 1 or more (got '${MAX_ADMINS}')" >&2; exit 2 ;;
  esac
  paginate "${Q_USERS}" "users"
  local humans owners admins mgmt
  humans="$(printf '%s' "${PAGE_NODES}" | jq '[ .[] | select(.active == true and .app != true) ] | length')"
  owners="$(printf '%s' "${PAGE_NODES}" | jq '[ .[] | select(.active == true and .app != true and .owner == true) ] | length')"
  admins="$(printf '%s' "${PAGE_NODES}" | jq '[ .[] | select(.active == true and .app != true and .owner != true and .admin == true) ] | length')"
  PRIVILEGED=$((owners + admins))
  echo "Linear 2.3: privileged accounts"
  echo "  active humans: ${humans}; owners: ${owners}; admins: ${admins}; privileged total: ${PRIVILEGED}; ceiling (LINEAR_MAX_ADMINS): ${MAX_ADMINS}"

  gql "${Q_ADMIN_MGMT}"
  mgmt="$(dq -r '(.organization.securitySettings // {}).adminManagementRole // "unset"')"
  echo "  securitySettings.adminManagementRole: ${mgmt} (informational)"

  if [ "${humans}" -eq 0 ]; then
    undetermined "the users query returned no active human users, so the privileged count could not be assessed."
  elif [ "${PRIVILEGED}" -eq 0 ]; then
    undetermined "no active human holds the owner or admin role, which a working workspace cannot have. Check the key's visibility."
  elif [ "${PRIVILEGED}" -gt "${MAX_ADMINS}" ]; then
    finding "${PRIVILEGED} active humans hold owner or admin (ceiling ${MAX_ADMINS}). Each one can change sign-in, SAML, API and membership settings, and bypasses login-method restrictions."
  fi
}
# HTH Guide Excerpt: end audit-admin-count

audit_admin_count
verdict "${PRIVILEGED} privileged accounts, within the ceiling of ${MAX_ADMINS}"
