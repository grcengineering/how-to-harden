#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: linear-1.3
#   guide:   https://howtoharden.com/guides/linear/#13-configure-allowed-domains
#   profile: L2
#   mode:    read-only
#   requires: LINEAR_API_KEY(personal API key; Read permission is enough)
# =============================================================================
# HTH Linear Control 1.3: Configure Allowed Domains
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 5.3 | NIST 800-53 AC-2
# Source: https://howtoharden.com/guides/linear/#13-configure-allowed-domains
# Dependencies: bash, curl (7.55+ for -H @-), jq
#
# Read-only audit of WHO MAY INVITE people into the workspace, the half of
# this control that Linear's public API can read.
#
# Vendor surface (Linear's published GraphQL schema,
# https://raw.githubusercontent.com/linear/linear/master/packages/sdk/src/schema.graphql):
#   Organization.securitySettings: JSONObject!  keys typed by
#       OrganizationSecuritySettingsInput. invitationsRole: UserRoleType is
#       "The minimum role required to invite users" (owner | admin | user | guest | app).
#   Organization.allowMembersToInvite: Boolean  deprecated mirror
#       ("Use `securitySettings.invitationsRole` instead"); read only as a fallback.
# Console: Settings > Administration > Security > "Allow users to send invites"
#   (https://linear.app/docs/invite-members). "By default, only Admins can
#   invite members on paid plans"; on the Free plan every member is an admin.
#
# TRAP 1: THE APPROVED-DOMAIN LIST IS NOT READABLE. The schema has
# organizationDomainCreate/Update/Delete mutations but no query that lists a
# workspace's approved email domains. Review that list in the console. This
# pack says so instead of implying it checked the list.
#
# TRAP 2: AN UNSET ROLE IS NOT A COMPLIANT ROLE. If neither invitationsRole nor
# the deprecated mirror is set, the workspace did not state its effective value.
# That is reported UNDETERMINED (exit 2), never assumed to be the default.
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

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-linear-103.XXXXXX")"
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

# HTH Guide Excerpt: begin audit-invitations
Q_INVITATIONS='query HthLinearInvitations { organization { securitySettings allowMembersToInvite } }'

audit_invitations() {
  gql "${Q_INVITATIONS}"
  local role legacy
  role="$(dq -r '(.organization.securitySettings // {}).invitationsRole // ""')"
  legacy="$(dq -r '.organization.allowMembersToInvite | if . == null then "" else tostring end')"
  echo "Linear 1.3: who may invite people into the workspace"

  if [ -n "${role}" ]; then
    echo "  securitySettings.invitationsRole: ${role}"
    case "${role}" in
      owner|admin) ;;
      user|guest)  finding "invitationsRole is '${role}': members below admin can invite people into the workspace (\"Allow users to send invites\" is on)." ;;
      *)           undetermined "invitationsRole has an unrecognised value '${role}'." ;;
    esac
  elif [ -n "${legacy}" ]; then
    echo "  allowMembersToInvite (deprecated mirror): ${legacy}"
    case "${legacy}" in
      false) ;;
      true)  finding "\"Allow users to send invites\" is on: any member can invite people into the workspace." ;;
      *)     undetermined "allowMembersToInvite has an unrecognised value '${legacy}'." ;;
    esac
  else
    # TRAP 2
    undetermined "neither securitySettings.invitationsRole nor allowMembersToInvite is set, so the effective invitation policy could not be read."
  fi

  # TRAP 1
  echo "  approved email domains: NOT CHECKED. No public query lists them; review Settings > Administration > Security."
}
# HTH Guide Excerpt: end audit-invitations

audit_invitations
verdict "only admins or owners can invite (approved email domains still need a console review)"
