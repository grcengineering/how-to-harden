#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: shopify-2.3
#   guide:   https://howtoharden.com/guides/shopify/#23-limit-admin-access
#   profile: L1
#   mode:    read-only
#   requires: SHOPIFY_STORE(<name>.myshopify.com), SHOPIFY_ADMIN_TOKEN(Admin API access token with read_users; Plus or Advanced store; Shopify Support must enable read_users for the app)
# =============================================================================
# HTH Shopify Control 2.3: Limit Admin Access — owner and staff-access inventory
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 5.4 | NIST 800-53 AC-6(1)
# Source: https://howtoharden.com/guides/shopify/#23-limit-admin-access
# API:    https://shopify.dev/docs/api/admin-graphql/latest/queries/staffMembers
#         https://shopify.dev/docs/api/admin-graphql/latest/objects/Shop (accountOwner)
#         https://shopify.dev/docs/api/admin-graphql/latest/enums/AccountType
# Dependencies: curl, jq
#
# READ-ONLY. Two Admin GraphQL queries, both reads. No mutation is sent; the
# GraphQL POST carries no -X flag because curl implies POST when a body is
# supplied. Nothing here can change who holds access.
#
# ── TRAP 1: read_users is gated three ways ──────────────────────────────────
# StaffMember "Requires read_users access scope. Also: The app must be a finance
# embedded app or installed on a Shopify Plus or Advanced store. Contact Shopify
# Support to enable this scope for your app." On any other store, or before
# Support enables the scope, both queries return a GraphQL access error. This
# pack exits 2 on that error — it never reads a refused query as "no staff".
#
# ── TRAP 2: this is the STORE's owner, not the ORGANIZATION's owners ─────────
# The guide's "limit owners to 2-3 users" is an organization-level setting in
# Settings -> Users. The store-scoped Admin API has no organization object, so
# organization owners are invisible here. What the API does expose is the one
# store owner (Shop.accountOwner, StaffMember.isShopOwner) and every staff
# account's type — enough to catch a pending ownership transfer and standing
# partner access, not enough to count organization owners.
#
# ── TRAP 3: permissions and 2FA are not readable ─────────────────────────────
# StaffMemberPrivateData.permissions is Deprecated and StaffMember carries no
# two-step field, so this pack cannot tell a full-permission staff account from
# a scoped one, or confirm owner 2FA. Those remain console checks.
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
BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-shopify-203.XXXXXX")" || {
  echo "PRECONDITION: cannot create a temp file" >&2; exit 2; }
PAGE_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-shopify-203p.XXXXXX")" || {
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
STAFF_QUERY='query HthStaffAccess($cursor: String) {
  staffMembers(first: 250, after: $cursor) {
    nodes { id accountType active isShopOwner }
    pageInfo { hasNextPage endCursor }
  }
}'

# Follows pageInfo.endCursor to exhaustion; a capped or malformed page exits 2
# rather than returning a partial inventory.
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
    [ "${pages}" -lt 200 ] || { echo "PRECONDITION: stopped at 200 pages; the inventory would be partial" >&2; exit 2; }
    cursor=$(printf '%s' "${GQL_BODY}" | jq -c '.data.staffMembers.pageInfo.endCursor')
  done
  STAFF=$(jq -s '.' "${PAGE_FILE}")
  [ "$(printf '%s' "${STAFF}" | jq 'length')" -gt 0 ] || {
    echo "PRECONDITION: zero staff members returned — every store has an owner (TRAP 4)" >&2; exit 2; }
}

# HTH Guide Excerpt: begin owner-and-staff-inventory
# Owner consistency, pending ownership transfer, and standing partner access.
audit() {
  gql 'query HthShopOwner { shop { accountOwner { id } } }' '{}'
  local owner_id
  owner_id=$(printf '%s' "${GQL_BODY}" | jq -r '.data.shop.accountOwner.id // ""')
  [ -n "${owner_id}" ] || { echo "PRECONDITION: shop.accountOwner came back empty" >&2; exit 2; }

  fetch_staff

  echo "Shopify 2.3 — owner and staff-access inventory (store ${SHOPIFY_STORE}, API ${SHOPIFY_API_VERSION})"
  echo "  staff accounts: $(printf '%s' "${STAFF}" | jq 'length') (active $(printf '%s' "${STAFF}" | jq '[.[] | select(.active)] | length'))"
  printf '%s' "${STAFF}" | jq -r 'group_by(.accountType // "UNSET")[]
    | "    \(.[0].accountType // "UNSET"): \(length) total, \([.[] | select(.active)] | length) active"'

  local rc=0 flagged owners
  owners=$(printf '%s' "${STAFF}" | jq -c '[.[] | select(.isShopOwner) | .id]')
  if [ "$(printf '%s' "${owners}" | jq --arg o "${owner_id}" '. == [$o]')" != "true" ]; then
    echo "FINDING: store ownership is inconsistent — shop.accountOwner ${owner_id} vs isShopOwner ${owners}."
    rc=1
  fi

  # INVITED_STORE_OWNER: "The user has not yet accepted the invitation to become
  # the store owner." Whoever accepts takes the store's highest privilege.
  flagged=$(printf '%s' "${STAFF}" | jq -c '[.[] | select(.accountType == "INVITED_STORE_OWNER") | .id]')
  if [ "$(printf '%s' "${flagged}" | jq 'length')" -gt 0 ]; then
    echo "FINDING: pending store-owner invitation(s): ${flagged}"
    echo "  Confirm the transfer was intended, or revoke it in Settings -> Users."
    rc=1
  fi

  # Partner collaborators and their team members hold admin access from outside
  # the organization; REQUESTED is a collaborator request awaiting a decision.
  flagged=$(printf '%s' "${STAFF}" | jq -c '[.[] | select(.active)
    | select(.accountType == "COLLABORATOR" or .accountType == "COLLABORATOR_TEAM_MEMBER") | .id]')
  [ "$(printf '%s' "${flagged}" | jq 'length')" -eq 0 ] ||
    echo "REVIEW: active partner collaborator accounts — confirm each is still needed: ${flagged}"
  flagged=$(printf '%s' "${STAFF}" | jq -c '[.[] | select(.accountType == "REQUESTED") | .id]')
  [ "$(printf '%s' "${flagged}" | jq 'length')" -eq 0 ] ||
    echo "REVIEW: collaborator access requests awaiting a decision: ${flagged}"

  echo "  NOT COVERED (console only): organization owners, per-staff permissions, owner 2FA (TRAPS 2-3)."
  [ "${rc}" -ne 0 ] || echo "NO FINDING: one consistent store owner and no pending ownership transfer."
  return "${rc}"
}
# HTH Guide Excerpt: end owner-and-staff-inventory

case "${1:-}" in
  ""|audit) audit ;;
  *) echo "usage: $(basename "$0") [audit]   # read-only; no other verbs" >&2; exit 2 ;;
esac
