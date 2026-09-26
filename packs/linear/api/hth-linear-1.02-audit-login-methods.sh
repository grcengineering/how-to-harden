#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: linear-1.2
#   guide:   https://howtoharden.com/guides/linear/#12-restrict-login-methods-to-saml-or-passkeys
#   profile: L1
#   mode:    read-only
#   requires: LINEAR_API_KEY(personal API key; Read permission is enough), LINEAR_APPROVED_AUTH_SERVICES(optional; default "saml")
# =============================================================================
# HTH Linear Control 1.2: Restrict Login Methods to SAML or Passkeys
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 6.5 | NIST 800-53 IA-2(1)
# Source: https://howtoharden.com/guides/linear/#12-restrict-login-methods-to-saml-or-passkeys
# Dependencies: bash, curl (7.55+ for -H @-), jq
#
# Read-only audit of "Restrict login methods" (Settings > Administration >
# Security, https://linear.app/docs/login-methods). Linear has no two-factor
# setting of its own; the lever is which sign-in methods are allowed.
#
# Vendor surface (Linear's published GraphQL schema,
# https://raw.githubusercontent.com/linear/linear/master/packages/sdk/src/schema.graphql):
#   Organization.authSettings: JSONObject!  "Authentication settings ... including
#       allowed auth providers, bypass rules". Its keys are typed by
#       OrganizationAuthSettingsInput: allowedAuthServices [String!]
#       ("empty array means all are allowed") and disableAuthServiceBypass.
#   Organization.allowedAuthServices: [String!]!  deprecated mirror
#       ("Use authSettings.allowedAuthServices instead"); read only as a fallback.
#
# TRAP 1: EMPTY MEANS OPEN. An empty allowedAuthServices list is not "nothing
# allowed"; the schema defines it as "all are allowed". This pack treats an
# empty list as the finding it is.
#
# TRAP 2: THE SERVICE NAMES ARE NOT A PUBLISHED ENUM. The schema types them as
# plain strings; its own examples are "google", "email", "saml". Every allowed
# value outside LINEAR_APPROVED_AUTH_SERVICES is reported. Run once, read the
# values this workspace uses (a passkey entry included), then set the list.
#
# TRAP 3: OWNERS AND ADMINS BYPASS THE RESTRICTION. By design they can sign in
# with any method so they can't lock themselves out
# (https://linear.app/docs/login-methods). disableAuthServiceBypass is printed
# for information only. Turning the bypass off is a lockout risk, and this pack
# never recommends it.
#
# WHY THERE IS NO WRITE PACK. organizationUpdate(input: { authSettings }) can
# set the list, and a mistaken value locks members out of the workspace.
# Change it in the console, where you can test the method before you save.
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

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-linear-102.XXXXXX")"
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

# HTH Guide Excerpt: begin audit-login-methods
Q_LOGIN_METHODS='query HthLinearLoginMethods { organization { authSettings allowedAuthServices } }'
APPROVED_AUTH_SERVICES="${LINEAR_APPROVED_AUTH_SERVICES:-saml}"

audit_login_methods() {
  gql "${Q_LOGIN_METHODS}"
  local source allowed outside bypass
  # authSettings.allowedAuthServices is current; the top-level field is its deprecated mirror.
  if dq -e '.organization.authSettings | type == "object" and has("allowedAuthServices")' >/dev/null; then
    allowed="$(dq -c '.organization.authSettings.allowedAuthServices')"
    source="authSettings.allowedAuthServices"
  else
    allowed="$(dq -c '.organization.allowedAuthServices')"
    source="allowedAuthServices (deprecated mirror)"
  fi
  echo "Linear 1.2: login-method restriction"

  if ! printf '%s' "${allowed}" | jq -e 'type == "array" and all(.[]; type == "string")' >/dev/null; then
    undetermined "${source} is not a list of strings: ${allowed}"
    return 0
  fi
  echo "  allowed login methods (${source}): $(printf '%s' "${allowed}" | jq -r 'if length == 0 then "ALL (no restriction)" else join(", ") end')"
  echo "  approved set (LINEAR_APPROVED_AUTH_SERVICES): ${APPROVED_AUTH_SERVICES}"

  if [ "$(printf '%s' "${allowed}" | jq 'length')" -eq 0 ]; then
    finding "no login-method restriction. Every sign-in method (Google, emailed login link or code, passkey, SAML) is open to every member (Business/Enterprise plans can restrict it)."
  else
    # TRAP 2: compare case-insensitively against the operator's approved set.
    outside="$(printf '%s' "${allowed}" | jq -r --arg ok "${APPROVED_AUTH_SERVICES}" '
      ($ok | split(",") | map(ascii_downcase | gsub("^\\s+|\\s+$"; "")) | map(select(. != ""))) as $approved
      | [ .[] | select((ascii_downcase) as $s | ($approved | index($s)) == null) ] | join(", ")')"
    if [ -n "${outside}" ]; then
      finding "login methods outside the approved set are allowed: ${outside}"
    fi
  fi

  # TRAP 3: informational only.
  # `//` would turn a real `false` into the fallback, so test for the key instead.
  bypass="$(dq -r '(.organization.authSettings // {}) | if has("disableAuthServiceBypass") then (.disableAuthServiceBypass | tostring) else "unset" end')"
  echo "  owner/admin any-method bypass disabled: ${bypass} (informational; the bypass is Linear's lockout safeguard)"
}
# HTH Guide Excerpt: end audit-login-methods

audit_login_methods
verdict "only approved login methods (${APPROVED_AUTH_SERVICES}) are allowed"
