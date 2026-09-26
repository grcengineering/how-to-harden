#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: linear-3.2
#   guide:   https://howtoharden.com/guides/linear/#32-configure-api-tokens
#   profile: L2
#   mode:    read-only
#   requires: LINEAR_API_KEY(personal API key; Read permission is enough)
# =============================================================================
# HTH Linear Control 3.2: Configure API Tokens
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 3.11 | NIST 800-53 SC-12
# Source: https://howtoharden.com/guides/linear/#32-configure-api-tokens
# Dependencies: bash, curl (7.55+ for -H @-), jq
#
# Read-only audit: which role may create personal API keys (the workspace's
# "Member API keys" setting), plus an inventory of the key owner's own active
# sessions, by count and age only.
#
# Vendor surface (Linear's published GraphQL schema,
# https://raw.githubusercontent.com/linear/linear/master/packages/sdk/src/schema.graphql):
#   Organization.securitySettings.personalApiKeysRole: UserRoleType
#     ("The minimum role required to create personal API keys")
#   Query.authenticationSessions: "User's active sessions"
#     (AuthenticationSession: createdAt, lastActiveAt, isCurrentSession, type)
# Console: Settings > Administration > API > "Member API keys" and Settings >
#   Account > Security & Access (https://linear.app/docs/api-and-webhooks,
#   https://linear.app/docs/security-and-access).
#
# TRAP 1: NO API LISTS PERSONAL API KEYS. The schema has no key type or key
# query. Reviewing and revoking existing keys is console-only (Settings >
# Administration > API lists the workspace's keys). This pack says so and does
# not pretend to have reviewed them.
#
# TRAP 2: SESSIONS ARE THE KEY OWNER'S, NOT THE WORKSPACE'S. authenticationSessions
# returns the calling user's sessions. userSessions(id) covers other users but is
# admin-only and per user. The inventory here is informational. IP address and
# location are never printed.
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

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-linear-302.XXXXXX")"
trap 'rm -f "${BODY_FILE}"' EXIT
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
finding()      { echo "FINDING: $*"; FINDINGS=$((FINDINGS + 1)); }
undetermined() { echo "UNDETERMINED: $*"; UNDETERMINED=$((UNDETERMINED + 1)); }
# Exit 0 only when every check was positively determined to be compliant.
verdict() {
  if [ "${FINDINGS}" -gt 0 ]; then echo "RESULT: ${FINDINGS} finding(s)"; exit 1; fi
  if [ "${UNDETERMINED}" -gt 0 ]; then echo "RESULT: no verdict (${UNDETERMINED} check(s) undetermined)"; exit 2; fi
  echo "RESULT: compliant: $1"
  exit 0
}

# HTH Guide Excerpt: begin audit-api-keys-and-sessions
Q_API_KEY_POLICY='query HthLinearApiKeyPolicy { organization { securitySettings } }'
Q_SESSIONS='query HthLinearSessions { authenticationSessions { createdAt lastActiveAt isCurrentSession type } }'

audit_api_keys_and_sessions() {
  local role
  gql "${Q_API_KEY_POLICY}"
  role="$(dq -r '(.organization.securitySettings // {}).personalApiKeysRole // ""')"
  echo "Linear 3.2: personal API key policy and sessions"
  case "${role}" in
    owner|admin) echo "  securitySettings.personalApiKeysRole: ${role} (members cannot create personal API keys)" ;;
    user|guest)  echo "  securitySettings.personalApiKeysRole: ${role}"
                 finding "personalApiKeysRole is '${role}': members below admin can mint long-lived personal API keys (\"Member API keys\" is on)." ;;
    "")          undetermined "securitySettings.personalApiKeysRole is not set, so who may create personal API keys could not be read." ;;
    *)           undetermined "personalApiKeysRole has an unrecognised value '${role}'." ;;
  esac
  # TRAP 1
  echo "  existing personal API keys: NOT CHECKED. No public query lists them; review Settings > Administration > API."

  # TRAP 2: informational inventory of the key owner's sessions, with no IP or location.
  gql "${Q_SESSIONS}"
  dq -r '
    def age_days: (now - (sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601)) / 86400 | floor;
    .authenticationSessions as $s
    | "  active sessions of the key owner: \($s | length)"
      + " (by client: \($s | group_by(.type) | map("\(.[0].type)=\(length)") | join(", ")))",
      (if ($s | length) > 0 then
         "  oldest session created \($s | map(.createdAt | age_days) | max) day(s) ago;"
         + " least recently active \($s | map((.lastActiveAt // .createdAt) | age_days) | max) day(s) ago"
       else empty end)'
}
# HTH Guide Excerpt: end audit-api-keys-and-sessions

audit_api_keys_and_sessions
verdict "only admins or owners can create personal API keys (existing keys still need a console review)"
