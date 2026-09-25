#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: linear-2.1
#   guide:   https://howtoharden.com/guides/linear/#21-configure-team-permissions
#   profile: L1
#   mode:    read-only
#   requires: LINEAR_API_KEY(personal API key; Read permission is enough)
# =============================================================================
# HTH Linear Control 2.1: Configure Team Permissions
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 5.4 | NIST 800-53 AC-6
# Source: https://howtoharden.com/guides/linear/#21-configure-team-permissions
# Dependencies: bash, curl (7.55+ for -H @-), jq
#
# Read-only audit: how active users split across Linear's roles, and whether
# team creation is limited to admins. Counts only; no name or email is printed.
#
# Vendor surface (Linear's published GraphQL schema,
# https://raw.githubusercontent.com/linear/linear/master/packages/sdk/src/schema.graphql):
#   Query.users (UserConnection, paginated; disabled users excluded by default)
#     User.active / owner ("the highest permission level") / admin ("On Free
#     plans, all members are treated as admins") / guest / app
#   Organization.securitySettings.teamCreationRole: UserRoleType
#     ("The minimum role required to create teams"; OrganizationSecuritySettingsInput)
#   Organization.restrictTeamCreationToAdmins: Boolean  deprecated mirror
# Console: Settings > Administration > Members (roles), Settings >
#   Administration > Security > "Restrict team creation"
#   (https://linear.app/docs/members-roles, https://linear.app/docs/teams).
#
# TRAP 1: FREE PLAN. On the Free plan every user is an admin, so role
# separation does not exist. An all-admin workspace with more than one human is
# reported as a finding, because least privilege is not possible there.
#
# TRAP 2: APPS ARE USERS. Integration and agent users come back from `users`
# with app: true. They are counted separately and never mixed into human role
# counts.
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

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-linear-201.XXXXXX")"
NODES_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-linear-201-nodes.XXXXXX")"
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

# HTH Guide Excerpt: begin audit-roles
Q_USERS='query HthLinearUsers($after: String) {
  users(first: 250, after: $after) { nodes { active admin owner guest app } pageInfo { hasNextPage endCursor } }
}'
Q_TEAM_CREATION='query HthLinearTeamCreation { organization { securitySettings restrictTeamCreationToAdmins } }'

audit_roles() {
  paginate "${Q_USERS}" "users"
  local counts humans owners admins members guests apps role legacy
  # TRAP 2: apps are counted apart from humans.
  counts="$(printf '%s' "${PAGE_NODES}" | jq -c '
    [ .[] | select(.active == true) ] as $a
    | ($a | map(select(.app != true))) as $h
    | { humans:  ($h | length),
        owners:  ($h | map(select(.owner == true)) | length),
        admins:  ($h | map(select(.owner != true and .admin == true)) | length),
        guests:  ($h | map(select(.owner != true and .admin != true and .guest == true)) | length),
        members: ($h | map(select(.owner != true and .admin != true and .guest != true)) | length),
        apps:    ($a | map(select(.app == true)) | length) }')"
  humans="$(printf '%s' "${counts}" | jq '.humans')"
  owners="$(printf '%s' "${counts}" | jq '.owners')"
  admins="$(printf '%s' "${counts}" | jq '.admins')"
  members="$(printf '%s' "${counts}" | jq '.members')"
  guests="$(printf '%s' "${counts}" | jq '.guests')"
  apps="$(printf '%s' "${counts}" | jq '.apps')"
  echo "Linear 2.1: role distribution and team creation"
  echo "  active humans: ${humans} (owners ${owners}, admins ${admins}, members ${members}, guests ${guests}); app users: ${apps}"

  if [ "${humans}" -eq 0 ]; then
    undetermined "the users query returned no active human users, so the role split could not be assessed."
  elif [ "${humans}" -gt 1 ] && [ "$((owners + admins))" -eq "${humans}" ]; then
    # TRAP 1
    finding "every active user holds an owner or admin role, so no one has least privilege (Linear's Free plan makes every user an admin)."
  fi

  gql "${Q_TEAM_CREATION}"
  role="$(dq -r '(.organization.securitySettings // {}).teamCreationRole // ""')"
  legacy="$(dq -r '.organization.restrictTeamCreationToAdmins | if . == null then "" else tostring end')"
  if [ -n "${role}" ]; then
    echo "  securitySettings.teamCreationRole: ${role}"
    case "${role}" in
      owner|admin) ;;
      user|guest)  finding "teamCreationRole is '${role}': members below admin can create teams (\"Restrict team creation\" is off)." ;;
      *)           undetermined "teamCreationRole has an unrecognised value '${role}'." ;;
    esac
  elif [ -n "${legacy}" ]; then
    echo "  restrictTeamCreationToAdmins (deprecated mirror): ${legacy}"
    case "${legacy}" in
      true)  ;;
      false) finding "\"Restrict team creation\" is off: any member can create teams." ;;
      *)     undetermined "restrictTeamCreationToAdmins has an unrecognised value '${legacy}'." ;;
    esac
  else
    undetermined "neither securitySettings.teamCreationRole nor restrictTeamCreationToAdmins is set, so the team-creation policy could not be read."
  fi
}
# HTH Guide Excerpt: end audit-roles

audit_roles
verdict "roles are separated and team creation is limited to admins"
