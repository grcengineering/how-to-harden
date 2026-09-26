#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: linear-2.2
#   guide:   https://howtoharden.com/guides/linear/#22-configure-project-visibility
#   profile: L2
#   mode:    read-only
#   requires: LINEAR_API_KEY(personal API key of a workspace admin or owner; Read permission is enough), LINEAR_SENSITIVE_TEAM_KEYS(comma-separated team keys that must be private)
# =============================================================================
# HTH Linear Control 2.2: Configure Project Visibility
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 5.4 | NIST 800-53 AC-6
# Source: https://howtoharden.com/guides/linear/#22-configure-project-visibility
# Dependencies: bash, curl (7.55+ for -H @-), jq
#
# Read-only audit: is every team you have declared sensitive actually private?
# In Linear, issue and project visibility follows team privacy
# (https://linear.app/docs/private-teams).
#
# Vendor surface (Linear's published GraphQL schema,
# https://raw.githubusercontent.com/linear/linear/master/packages/sdk/src/schema.graphql):
#   Team.visibility: TeamVisibility!  private | public | restricted.
#     "restricted" is "non-private teams inside a private-team boundary", which
#     means every member of the private parent can see and join it.
#   Team.allMembersCanJoin, Team.scimManaged (reported for context).
#   Query.teams: "teams whose issues the user can access", which is public
#     teams plus private teams the user is a member of.
#   Query.administrableTeams: teams whose settings the user can administer,
#     including private teams whose issues they cannot read.
#
# TRAP 1: A PRIVATE TEAM YOU ARE NOT IN IS INVISIBLE TO `teams`. The pack takes
# the union of `teams` and `administrableTeams`, so run it with an admin's or
# owner's key. A declared key that still cannot be found is UNDETERMINED, not
# compliant. It could be a private team this key cannot see, or a typo.
#
# TRAP 2: NOTHING TO JUDGE WITHOUT A DECLARATION. Which teams hold sensitive
# work is your decision, not the API's. With LINEAR_SENSITIVE_TEAM_KEYS unset,
# the pack prints the inventory and exits 2 (no verdict). It never exits 0
# having judged nothing.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition, error, or undetermined
# =============================================================================

set -Eeuo pipefail
trap 'echo "ERROR: unexpected failure at line ${LINENO}; no verdict was produced" >&2; exit 2' ERR

if [ "$#" -gt 0 ]; then
  echo "usage: LINEAR_SENSITIVE_TEAM_KEYS=SEC,HR $(basename "$0")   (no arguments; read-only audit)" >&2
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

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-linear-202.XXXXXX")"
NODES_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-linear-202-nodes.XXXXXX")"
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

# HTH Guide Excerpt: begin audit-team-visibility
TEAM_FIELDS='nodes { id key visibility scimManaged allMembersCanJoin } pageInfo { hasNextPage endCursor }'
Q_TEAMS="query HthLinearTeams(\$after: String) { teams(first: 250, after: \$after) { ${TEAM_FIELDS} } }"
Q_ADMIN_TEAMS="query HthLinearAdminTeams(\$after: String) { administrableTeams(first: 250, after: \$after) { ${TEAM_FIELDS} } }"
SENSITIVE_TEAM_KEYS="${LINEAR_SENSITIVE_TEAM_KEYS:-}"

audit_team_visibility() {
  local readable administrable teams key vis
  paginate "${Q_TEAMS}" "teams";                     readable="${PAGE_NODES}"
  paginate "${Q_ADMIN_TEAMS}" "administrableTeams";  administrable="${PAGE_NODES}"
  # TRAP 1: union by id, so private teams the key administers but cannot read are included.
  teams="$(jq -nc --argjson a "${readable}" --argjson b "${administrable}" '$a + $b | unique_by(.id)')"

  echo "Linear 2.2: team visibility"
  printf '%s' "${teams}" | jq -r '
    "  teams visible to this key: \(length) (private \(map(select(.visibility == "private")) | length),"
    + " restricted \(map(select(.visibility == "restricted")) | length),"
    + " public \(map(select(.visibility == "public")) | length))",
    "  public teams any member can join: \(map(select(.visibility == "public" and .allMembersCanJoin == true)) | length)",
    (sort_by(.key)[] | "    - \(.key): \(.visibility)\(if .scimManaged then " (SCIM-managed)" else "" end)")'

  if [ -z "${SENSITIVE_TEAM_KEYS}" ]; then
    # TRAP 2
    undetermined "LINEAR_SENSITIVE_TEAM_KEYS is not set. Name the teams that hold sensitive work (e.g. SEC,HR) to get a verdict."
    return 0
  fi
  echo "  declared sensitive teams: ${SENSITIVE_TEAM_KEYS}"
  local IFS=','
  for key in ${SENSITIVE_TEAM_KEYS}; do
    key="$(printf '%s' "${key}" | tr -d '[:space:]')"
    [ -n "${key}" ] || continue
    vis="$(printf '%s' "${teams}" | jq -r --arg k "${key}" 'map(select((.key | ascii_upcase) == ($k | ascii_upcase))) | first | .visibility // ""')"
    case "${vis}" in
      private)    ;;
      public)     finding "team ${key} is public. Every workspace member can view and join it, and search its issues, projects and documents." ;;
      restricted) finding "team ${key} is restricted. Every member of its private parent team can see and join it; make it Private." ;;
      "")         undetermined "team ${key} was not visible to this key. It may be private and not administered by this user, or the key may be wrong. Re-run with an admin's or owner's key." ;;
      *)          undetermined "team ${key} has an unrecognised visibility '${vis}'." ;;
    esac
  done
}
# HTH Guide Excerpt: end audit-team-visibility

audit_team_visibility
verdict "every declared sensitive team (${SENSITIVE_TEAM_KEYS}) is private"
