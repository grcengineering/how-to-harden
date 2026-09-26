#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: linear-1.1
#   guide:   https://howtoharden.com/guides/linear/#11-configure-saml-single-sign-on
#   profile: L1
#   mode:    read-only
#   requires: LINEAR_API_KEY(personal API key; Read permission is enough)
# =============================================================================
# HTH Linear Control 1.1: Configure SAML Single Sign-On
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 6.3, 12.5 | NIST 800-53 IA-2, IA-8
# Source: https://howtoharden.com/guides/linear/#11-configure-saml-single-sign-on
# Dependencies: bash, curl (7.55+ for -H @-), jq
#
# Read-only audit: is SAML enabled, and is SCIM enabled beside it?
#
# Vendor surface (every field below is in Linear's published GraphQL schema,
# https://raw.githubusercontent.com/linear/linear/master/packages/sdk/src/schema.graphql):
#   Organization.samlEnabled: Boolean!  "Whether SAML-based single sign-on
#                                        authentication is enabled"
#   Organization.scimEnabled: Boolean!  "Whether SCIM provisioning is enabled"
# Endpoint and auth header: https://linear.app/developers/graphql
#   (personal API keys go in `Authorization: <API_KEY>`, no "Bearer").
#
# WHY THERE IS NO WRITE PACK. OrganizationUpdateInput carries no SAML or SCIM
# field (`samlSettings` on Organization is marked [INTERNAL]). Configuring SAML
# is an IdP metadata exchange in the console, Settings > Administration >
# Security > "SAML & SCIM" > Configure. That is the guide's ClickOps section.
#
# PLAN GATE. SAML and SCIM are Enterprise-plan features
# (https://linear.app/docs/saml-and-access-control, https://linear.app/docs/scim).
# On any other plan both fields read false and this pack reports two findings,
# which is accurate: the workspace does not have either control.
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

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-linear-101.XXXXXX")"
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

# HTH Guide Excerpt: begin audit-saml-scim
Q_SAML_SCIM='query HthLinearSamlScim { organization { samlEnabled scimEnabled } }'

audit_saml_scim() {
  gql "${Q_SAML_SCIM}"
  local saml scim
  saml="$(dq -r '.organization.samlEnabled')"
  scim="$(dq -r '.organization.scimEnabled')"
  echo "Linear 1.1: SAML SSO and SCIM provisioning"
  echo "  samlEnabled: ${saml}"
  echo "  scimEnabled: ${scim}"

  case "${saml}" in
    true)  ;;
    false) finding "SAML is not enabled. Members sign in with Google, an emailed login link or code, or a passkey, outside your IdP's MFA and session policy (SAML requires the Enterprise plan)." ;;
    *)     undetermined "samlEnabled came back as '${saml}', not a boolean." ;;
  esac
  case "${scim}" in
    true)  ;;
    false) finding "SCIM is not enabled. SAML just-in-time provisioning creates accounts but never suspends them, so offboarding stays a manual step." ;;
    *)     undetermined "scimEnabled came back as '${scim}', not a boolean." ;;
  esac
}
# HTH Guide Excerpt: end audit-saml-scim

audit_saml_scim
verdict "SAML and SCIM are both enabled"
