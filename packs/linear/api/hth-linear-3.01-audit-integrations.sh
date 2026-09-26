#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: linear-3.1
#   guide:   https://howtoharden.com/guides/linear/#31-configure-integration-access
#   profile: L2
#   mode:    read-only
#   requires: LINEAR_API_KEY(personal API key of a workspace admin; Read permission is enough), LINEAR_APPROVED_INTEGRATIONS(comma-separated integration service names you have approved)
# =============================================================================
# HTH Linear Control 3.1: Configure Integration Access
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 3.11 | NIST 800-53 SC-12
# Source: https://howtoharden.com/guides/linear/#31-configure-integration-access
# Dependencies: bash, curl (7.55+ for -H @-), jq
#
# Read-only audit of the workspace's integration surface: which integrations are
# connected, which webhooks deliver workspace data and where to, and which role
# may install new integrations.
#
# Vendor surface (Linear's published GraphQL schema,
# https://raw.githubusercontent.com/linear/linear/master/packages/sdk/src/schema.graphql):
#   Query.integrations: "All integrations for the workspace" (Integration.service, createdAt)
#   Query.webhooks: "All webhooks for the current workspace"
#     (Webhook.enabled, url, allPublicTeams, resourceTypes, label)
#   Organization.securitySettings.integrationCreationRole: UserRoleType
#     ("The minimum role required to install and connect new integrations")
# Webhook reads are admin-only: "Only workspace admins, or OAuth applications
# with the admin scope, can create or read webhooks"
# (https://linear.app/developers/webhooks). A non-admin key gets a GraphQL
# permission error, and the run stops with exit 2.
#
# TRAP 1: WEBHOOK URLS CAN CARRY SECRETS. Receivers often put a token in the
# query string. Only scheme and host are printed, never the path or query.
#
# TRAP 2: THE APPROVAL GATE IS NOT READABLE. "Third-party application approvals"
# is settable (OrganizationUpdateInput.oauthAppReview), but the Organization type
# does not expose it for reading. Confirm it in Settings > Administration >
# Security. This pack does not claim to have checked it.
#
# TRAP 3: "UNUSED" IS YOUR CALL. The API cannot tell which integration is still
# in use. Declare the approved set in LINEAR_APPROVED_INTEGRATIONS (service names
# as this pack prints them). Anything else is a finding. Unset means no verdict,
# never an assumed pass.
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

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-linear-301.XXXXXX")"
NODES_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-linear-301-nodes.XXXXXX")"
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

# HTH Guide Excerpt: begin audit-integrations
Q_INTEGRATIONS='query HthLinearIntegrations($after: String) {
  integrations(first: 250, after: $after) { nodes { service createdAt } pageInfo { hasNextPage endCursor } }
}'
Q_WEBHOOKS='query HthLinearWebhooks($after: String) {
  webhooks(first: 250, after: $after) { nodes { enabled url allPublicTeams resourceTypes label } pageInfo { hasNextPage endCursor } }
}'
Q_INTEGRATION_ROLE='query HthLinearIntegrationRole { organization { securitySettings } }'
APPROVED_INTEGRATIONS="${LINEAR_APPROVED_INTEGRATIONS:-}"

audit_integrations() {
  local integrations webhooks unapproved insecure role
  paginate "${Q_INTEGRATIONS}" "integrations"; integrations="${PAGE_NODES}"
  paginate "${Q_WEBHOOKS}" "webhooks";         webhooks="${PAGE_NODES}"

  echo "Linear 3.1: integrations, webhooks, and who may install integrations"
  printf '%s' "${integrations}" | jq -r '
    "  integrations: \(length)",
    (group_by(.service)[] | "    - \(.[0].service): \(length) connection(s), oldest \(map(.createdAt) | min | .[0:10])")'
  # TRAP 1: scheme://host only.
  printf '%s' "${webhooks}" | jq -r '
    "  webhooks: \(length) (enabled \(map(select(.enabled == true)) | length))",
    (.[] | "    - \((.url // "(no url)") | capture("^(?<o>[A-Za-z][A-Za-z0-9+.-]*://[^/?#]*)").o // "(unparseable url)")"
           + " enabled=\(.enabled) allPublicTeams=\(.allPublicTeams) resources=\((.resourceTypes // []) | join(","))")'

  insecure="$(printf '%s' "${webhooks}" | jq '[ .[] | select(.enabled == true and ((.url // "") | test("^https://"; "i") | not)) ] | length')"
  if [ "${insecure}" -gt 0 ]; then
    finding "${insecure} enabled webhook(s) deliver workspace data to a non-HTTPS URL."
  fi

  if [ -z "${APPROVED_INTEGRATIONS}" ]; then
    # TRAP 3
    undetermined "LINEAR_APPROVED_INTEGRATIONS is not set. Name the integration services you have approved to get a verdict on the list above."
  else
    unapproved="$(printf '%s' "${integrations}" | jq -r --arg ok "${APPROVED_INTEGRATIONS}" '
      ($ok | split(",") | map(ascii_downcase | gsub("^\\s+|\\s+$"; "")) | map(select(. != ""))) as $approved
      | [ .[].service | select((ascii_downcase) as $s | ($approved | index($s)) == null) ] | unique | join(", ")')"
    if [ -n "${unapproved}" ]; then
      finding "integrations outside LINEAR_APPROVED_INTEGRATIONS are connected: ${unapproved}"
    fi
  fi

  gql "${Q_INTEGRATION_ROLE}"
  role="$(dq -r '(.organization.securitySettings // {}).integrationCreationRole // ""')"
  case "${role}" in
    owner|admin) echo "  securitySettings.integrationCreationRole: ${role}" ;;
    user|guest)  echo "  securitySettings.integrationCreationRole: ${role}"
                 finding "integrationCreationRole is '${role}': members below admin can install and connect new integrations." ;;
    "")          undetermined "securitySettings.integrationCreationRole is not set, so who may install integrations could not be read." ;;
    *)           undetermined "integrationCreationRole has an unrecognised value '${role}'." ;;
  esac

  # TRAP 2
  echo "  third-party application approvals: NOT CHECKED. Not readable through the public API; confirm it in Settings > Administration > Security."
}
# HTH Guide Excerpt: end audit-integrations

audit_integrations
verdict "only approved integrations, HTTPS webhooks, and admin-only installation"
