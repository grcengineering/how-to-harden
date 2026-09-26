#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: shopify-1.1
#   guide:   https://howtoharden.com/guides/shopify/#11-configure-saml-single-sign-on
#   profile: L1
#   mode:    read-only
#   requires: SHOPIFY_STORE(<name>.myshopify.com), SHOPIFY_ADMIN_TOKEN(Admin API access token with read_users; Plus or Advanced store; Shopify Support must enable read_users for the app), SHOPIFY_SAML_EXCEPTION_IDS(optional, comma-separated StaffMember GIDs of documented break-glass accounts)
# =============================================================================
# HTH Shopify Control 1.1: Configure SAML Single Sign-On — staff sign-in audit
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 6.3, 12.5 | NIST 800-53 IA-2, IA-8
# Source: https://howtoharden.com/guides/shopify/#11-configure-saml-single-sign-on
# API:    https://shopify.dev/docs/api/admin-graphql/latest/queries/staffMembers
#         https://shopify.dev/docs/api/admin-graphql/latest/enums/AccountType
# Dependencies: curl, jq
#
# READ-ONLY VERIFICATION. SAML itself is configured and enforced only in the
# console (Settings -> Users -> Security); the Admin API has no mutation for it.
# What the API does expose is each staff account's type, and AccountType SAML is
# documented as "The account can be signed into via a SAML provider" while
# REGULAR is "The account can access the Shopify admin". This pack reads every
# staff account and reports which active accounts still sign in with Shopify
# credentials — the password-login path the guide's Required level exists to close.
#
# ── TRAP 1: read_users is gated three ways ──────────────────────────────────
# "Requires read_users access scope. Also: The app must be a finance embedded
# app or installed on a Shopify Plus or Advanced store. Contact Shopify Support
# to enable this scope for your app." A refused query exits 2, never "clean".
#
# ── TRAP 2: account type is the documented signal, not the enforcement level ─
# The API does not expose the enforcement level (Required / Specific users /
# Off). Shopify documents what each AccountType means but not the moment an
# existing REGULAR account becomes SAML after enforcement changes, so treat a
# REGULAR finding as "confirm in the console", not as proof enforcement is off.
#
# ── TRAP 3: the documented fallback account is expected ─────────────────────
# The guide says to configure an admin fallback before choosing Required. List
# that account's GID in SHOPIFY_SAML_EXCEPTION_IDS so it is reported as an
# exception rather than as a finding. Keep the list short and written down.
#
# ── TRAP 4: an empty staff list is a failure, not a clean result ────────────
# Every store has an owner, so zero staff members means the query saw nothing.
#
# Exit codes: 0 no finding | 1 finding | 2 precondition (auth, scope, plan, network)
# =============================================================================

set -euo pipefail

: "${SHOPIFY_STORE:?set SHOPIFY_STORE to the <name>.myshopify.com domain of the store}"
: "${SHOPIFY_ADMIN_TOKEN:?set SHOPIFY_ADMIN_TOKEN — an Admin API access token carrying read_users}"
SHOPIFY_API_VERSION="${SHOPIFY_API_VERSION:-2026-07}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

# The token is sent only to a *.myshopify.com Admin API host.
[[ "${SHOPIFY_STORE}" =~ ^[a-z0-9][a-z0-9-]*\.myshopify\.com$ ]] || {
  echo "PRECONDITION: SHOPIFY_STORE must be a <name>.myshopify.com domain" >&2; exit 2; }
[[ "${SHOPIFY_API_VERSION}" =~ ^([0-9]{4}-[0-9]{2}|unstable)$ ]] || {
  echo "PRECONDITION: SHOPIFY_API_VERSION must look like 2026-07" >&2; exit 2; }

ENDPOINT="https://${SHOPIFY_STORE}/admin/api/${SHOPIFY_API_VERSION}/graphql.json"
BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-shopify-101.XXXXXX")" || {
  echo "PRECONDITION: cannot create a temp file" >&2; exit 2; }
PAGE_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-shopify-101p.XXXXXX")" || {
  echo "PRECONDITION: cannot create a temp file" >&2; exit 2; }
trap 'rm -f "${BODY_FILE}" "${PAGE_FILE}"' EXIT

GQL_BODY=""; STAFF="[]"

# One GraphQL request. The access token travels in a curl config read from
# stdin, so it never appears in the process list. Transport failure, a non-200
# status, a non-JSON body, or a non-empty `errors` member of any shape exits 2.
gql() { # gql <query> <variables-json>
  local payload code rc
  payload=$(jq -nc --arg q "$1" --argjson v "$2" '{query: $q, variables: $v}')
  set +e
  code=$(printf 'header = "X-Shopify-Access-Token: %s"\n' "${SHOPIFY_ADMIN_TOKEN}" |
    curl -sS -K - -o "${BODY_FILE}" -w '%{http_code}' "${ENDPOINT}" \
      -H "Content-Type: application/json" --data "${payload}")
  rc=$?
  set -e
  if [ "${rc}" -ne 0 ]; then
    echo "PRECONDITION: no HTTP response from the Admin API (curl exit ${rc})" >&2; exit 2
  fi
  GQL_BODY=$(cat "${BODY_FILE}")
  if [ "${code}" != "200" ]; then
    echo "PRECONDITION: Admin API returned HTTP ${code}" >&2
    case "${code}" in
      401) echo "  The token is invalid, revoked, or for a different store." >&2 ;;
      402|423) echo "  The store is frozen, paused, or locked." >&2 ;;
      403) echo "  The token lacks a required scope (this pack needs read_users)." >&2 ;;
      404) echo "  Wrong store domain or API version." >&2 ;;
      429) echo "  Rate limited — wait and re-run." >&2 ;;
    esac
    exit 2
  fi
  if ! printf '%s' "${GQL_BODY}" | jq -e 'type == "object"' >/dev/null 2>&1; then
    echo "PRECONDITION: the Admin API response was not a JSON object" >&2; exit 2
  fi
  # `errors` is tested by value, not by `length`: Shopify returns it as an array
  # of objects on GraphQL failures but as a bare string on some failures, and a
  # `length` on an unexpected type makes jq error out — which an `if jq -e`
  # would read as "no errors". Anything other than an exact `false` fails closed.
  local has_errors
  has_errors=$(printf '%s' "${GQL_BODY}" |
    jq -r '.errors | . != null and . != false and . != [] and . != "" and . != {}') || {
    echo "PRECONDITION: could not read the Admin API response" >&2; exit 2; }
  if [ "${has_errors}" != "false" ]; then
    echo "PRECONDITION: the query returned GraphQL errors (TRAP 1 if ACCESS_DENIED):" >&2
    printf '%s' "${GQL_BODY}" | jq -r '
      if (.errors | type) == "array" then .errors[]
        | if type == "object" then "  - \(.extensions.code // "ERROR"): \(.message // tostring)"
          else "  - ERROR: \(tostring)" end
      else "  - ERROR: \(.errors | tostring)" end' >&2 || true
    exit 2
  fi
}

# shellcheck disable=SC2016  # GraphQL $variables must stay literal, not shell-expanded
STAFF_QUERY='query HthStaffSignIn($cursor: String) {
  staffMembers(first: 250, after: $cursor) {
    nodes { id accountType active isShopOwner }
    pageInfo { hasNextPage endCursor }
  }
}'

# Follows pageInfo.endCursor to exhaustion; a capped or malformed page exits 2
# rather than returning a partial list.
fetch_staff() {
  local cursor="null" pages=0
  : > "${PAGE_FILE}"
  while :; do
    gql "${STAFF_QUERY}" "$(jq -nc --argjson c "${cursor}" '{cursor: $c}')"
    printf '%s' "${GQL_BODY}" | jq -e '.data.staffMembers.nodes | type == "array"' >/dev/null || {
      echo "PRECONDITION: the response carried no staffMembers list" >&2; exit 2; }
    printf '%s' "${GQL_BODY}" | jq -c '.data.staffMembers.nodes[]' >> "${PAGE_FILE}"
    pages=$((pages + 1))
    [ "$(printf '%s' "${GQL_BODY}" | jq -r '.data.staffMembers.pageInfo.hasNextPage')" = "true" ] || break
    [ "${pages}" -lt 200 ] || { echo "PRECONDITION: stopped at 200 pages; the list would be partial" >&2; exit 2; }
    cursor=$(printf '%s' "${GQL_BODY}" | jq -c '.data.staffMembers.pageInfo.endCursor')
  done
  STAFF=$(jq -s '.' "${PAGE_FILE}")
  [ "$(printf '%s' "${STAFF}" | jq 'length')" -gt 0 ] || {
    echo "PRECONDITION: zero staff members returned — every store has an owner (TRAP 4)" >&2; exit 2; }
}

# HTH Guide Excerpt: begin saml-account-type-audit
# Which active staff accounts sign in through SAML, and which still use
# Shopify credentials outside the documented break-glass exceptions.
audit() {
  fetch_staff
  local exceptions saml_active outside rc=0
  exceptions=$(jq -nc --arg s "${SHOPIFY_SAML_EXCEPTION_IDS:-}" \
    '$s | split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0))')

  echo "Shopify 1.1 — staff sign-in type (store ${SHOPIFY_STORE}, API ${SHOPIFY_API_VERSION})"
  printf '%s' "${STAFF}" | jq -r 'group_by(.accountType // "UNSET")[]
    | "    \(.[0].accountType // "UNSET"): \(length) total, \([.[] | select(.active)] | length) active"'

  saml_active=$(printf '%s' "${STAFF}" | jq '[.[] | select(.active and .accountType == "SAML")] | length')
  outside=$(printf '%s' "${STAFF}" | jq -c --argjson ex "${exceptions}" '[.[]
    | select(.active and .accountType == "REGULAR")
    | select(.id as $i | ($ex | index($i)) == null)
    | .id + (if .isShopOwner then " (store owner)" else "" end)]')

  if [ "${saml_active}" -eq 0 ]; then
    echo "FINDING: no active staff account is SAML-typed — staff are not signing in through your IdP."
    rc=1
  fi
  if [ "$(printf '%s' "${outside}" | jq 'length')" -gt 0 ]; then
    echo "FINDING: active accounts still signing in with Shopify credentials (not in SHOPIFY_SAML_EXCEPTION_IDS):"
    printf '%s' "${outside}" | jq -r '.[] | "    - \(.)"'
    echo "  Under the Required level these should be SAML; confirm each in Settings -> Users (TRAP 2)."
    rc=1
  fi
  [ "$(printf '%s' "${exceptions}" | jq 'length')" -eq 0 ] ||
    echo "  documented exceptions: $(printf '%s' "${exceptions}" | jq 'length')"
  [ "${rc}" -ne 0 ] || echo "NO FINDING: ${saml_active} active SAML account(s); no unexcepted Shopify-credential account."
  return "${rc}"
}
# HTH Guide Excerpt: end saml-account-type-audit

case "${1:-}" in
  ""|audit) audit ;;
  *) echo "usage: $(basename "$0") [audit]   # read-only; no other verbs" >&2; exit 2 ;;
esac
