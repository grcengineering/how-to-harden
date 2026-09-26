#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: shopify-2.3
#   guide:   https://howtoharden.com/guides/shopify/#23-limit-admin-access
#   profile: L1
#   mode:    read-only
#   requires: shopify CLI 3.93+ (store auth / store execute), SHOPIFY_STORE(<name>.myshopify.com), stored store auth carrying read_users (one-time: shopify store auth --store <store> --scopes read_users)
# =============================================================================
# HTH Shopify Control 2.3: Limit Admin Access — owner and staff-access inventory (Shopify CLI)
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 5.4 | NIST 800-53 AC-6(1)
# Source: https://howtoharden.com/guides/shopify/#23-limit-admin-access
# CLI:    https://shopify.dev/docs/api/shopify-cli/store/store-execute
#         https://shopify.dev/docs/api/shopify-cli/store/store-auth
# API:    https://shopify.dev/docs/api/admin-graphql/latest/queries/staffMembers
# Dependencies: shopify (@shopify/cli 3.93 or later), jq
#
# WHY cli/: Shopify's first-party CLI is GA and its `store` topic runs Admin API
# GraphQL against a store with stored per-user auth. It is the same read the
# api/ pack for this control makes, for operators who authenticate as
# themselves through the CLI instead of holding an app's access token.
#
# READ-ONLY BY CONSTRUCTION. `shopify store execute` refuses mutations unless
# --allow-mutations is passed ("Mutations are disabled by default"). This pack
# never passes it, and both operations below are queries.
#
# ── TRAP 1: store auth is a one-time interactive step, run separately ────────
# "Run shopify store auth first to create stored auth for the store." It opens a
# browser (PKCE) and stores an online token for the signed-in staff member, so it
# is not scripted here. Request read_users when you run it. That scope carries
# the same gate as the API pack: Plus or Advanced store, enabled by Shopify
# Support, and an online token can never exceed the staff member's own access.
#
# ── TRAP 2: --json prints the query's data object, and errors exit non-zero ─
# In JSON mode the command writes only the result to stdout (the query's
# top-level fields — here `shop` and `staffMembers`); progress goes to stderr.
# GraphQL errors surface as "GraphQL operation failed." with a non-zero exit.
# Anything that is not a JSON object carrying the expected field exits 2.
#
# ── TRAP 3: same coverage limits as the API ──────────────────────────────────
# Organization owners, per-staff permissions, and owner 2FA are not readable
# through the Admin API, so they are not readable through the CLI either.
#
# Exit codes: 0 no finding | 1 finding | 2 precondition (CLI, auth, scope, plan)
# =============================================================================

set -euo pipefail

: "${SHOPIFY_STORE:?set SHOPIFY_STORE to the <name>.myshopify.com domain of the store}"
SHOPIFY_API_VERSION="${SHOPIFY_API_VERSION:-2026-07}"

command -v shopify >/dev/null 2>&1 || { echo "PRECONDITION: shopify CLI not found (npm i -g @shopify/cli)" >&2; exit 2; }
command -v jq      >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }
[[ "${SHOPIFY_STORE}" =~ ^[a-z0-9][a-z0-9-]*\.myshopify\.com$ ]] || {
  echo "PRECONDITION: SHOPIFY_STORE must be a <name>.myshopify.com domain" >&2; exit 2; }
[[ "${SHOPIFY_API_VERSION}" =~ ^([0-9]{4}-[0-9]{2}|unstable)$ ]] || {
  echo "PRECONDITION: SHOPIFY_API_VERSION must look like 2026-07" >&2; exit 2; }

OUT_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-shopify-203c.XXXXXX")" || {
  echo "PRECONDITION: cannot create a temp file" >&2; exit 2; }
ERR_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-shopify-203e.XXXXXX")" || {
  echo "PRECONDITION: cannot create a temp file" >&2; exit 2; }
PAGE_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-shopify-203p.XXXXXX")" || {
  echo "PRECONDITION: cannot create a temp file" >&2; exit 2; }
trap 'rm -f "${OUT_FILE}" "${ERR_FILE}" "${PAGE_FILE}"' EXIT

RESULT=""; STAFF="[]"

# One read through the CLI. A non-zero exit (missing stored auth, missing scope,
# GraphQL error) or output that is not a JSON object exits 2.
run_query() { # run_query <query> <variables-json>
  local rc
  set +e
  shopify store execute --store "${SHOPIFY_STORE}" --version "${SHOPIFY_API_VERSION}" \
    --query "$1" --variables "$2" --json >"${OUT_FILE}" 2>"${ERR_FILE}"
  rc=$?
  set -e
  if [ "${rc}" -ne 0 ]; then
    echo "PRECONDITION: shopify store execute exited ${rc}. Last lines of its error output:" >&2
    tail -n 8 "${ERR_FILE}" >&2
    echo "  If stored auth is missing or lacks read_users: shopify store auth --store ${SHOPIFY_STORE} --scopes read_users" >&2
    exit 2
  fi
  RESULT=$(cat "${OUT_FILE}")
  printf '%s' "${RESULT}" | jq -e 'type == "object"' >/dev/null 2>&1 || {
    echo "PRECONDITION: shopify store execute did not print a JSON object (TRAP 2)" >&2; exit 2; }
}

# shellcheck disable=SC2016  # GraphQL $variables must stay literal, not shell-expanded
STAFF_QUERY='query HthStaffAccess($cursor: String) {
  staffMembers(first: 250, after: $cursor) {
    nodes { id accountType active isShopOwner }
    pageInfo { hasNextPage endCursor }
  }
}'

fetch_staff() {
  local cursor="null" pages=0
  : > "${PAGE_FILE}"
  while :; do
    run_query "${STAFF_QUERY}" "$(jq -nc --argjson c "${cursor}" '{cursor: $c}')"
    printf '%s' "${RESULT}" | jq -e '.staffMembers.nodes | type == "array"' >/dev/null || {
      echo "PRECONDITION: the output carried no staffMembers list" >&2; exit 2; }
    printf '%s' "${RESULT}" | jq -c '.staffMembers.nodes[]' >> "${PAGE_FILE}"
    pages=$((pages + 1))
    [ "$(printf '%s' "${RESULT}" | jq -r '.staffMembers.pageInfo.hasNextPage')" = "true" ] || break
    [ "${pages}" -lt 200 ] || { echo "PRECONDITION: stopped at 200 pages; the inventory would be partial" >&2; exit 2; }
    cursor=$(printf '%s' "${RESULT}" | jq -c '.staffMembers.pageInfo.endCursor')
  done
  STAFF=$(jq -s '.' "${PAGE_FILE}")
  [ "$(printf '%s' "${STAFF}" | jq 'length')" -gt 0 ] || {
    echo "PRECONDITION: zero staff members returned — every store has an owner" >&2; exit 2; }
}

# HTH Guide Excerpt: begin cli-owner-and-staff-inventory
# The same inventory as the api/ pack, read through `shopify store execute`
# (queries only; --allow-mutations is never passed).
audit() {
  run_query 'query HthShopOwner { shop { accountOwner { id } } }' '{}'
  local owner_id
  owner_id=$(printf '%s' "${RESULT}" | jq -r '.shop.accountOwner.id // ""')
  [ -n "${owner_id}" ] || { echo "PRECONDITION: shop.accountOwner came back empty" >&2; exit 2; }

  fetch_staff

  echo "Shopify 2.3 (CLI) — owner and staff-access inventory (store ${SHOPIFY_STORE}, API ${SHOPIFY_API_VERSION})"
  printf '%s' "${STAFF}" | jq -r 'group_by(.accountType // "UNSET")[]
    | "    \(.[0].accountType // "UNSET"): \(length) total, \([.[] | select(.active)] | length) active"'

  local rc=0 flagged owners
  owners=$(printf '%s' "${STAFF}" | jq -c '[.[] | select(.isShopOwner) | .id]')
  if [ "$(printf '%s' "${owners}" | jq --arg o "${owner_id}" '. == [$o]')" != "true" ]; then
    echo "FINDING: store ownership is inconsistent — shop.accountOwner ${owner_id} vs isShopOwner ${owners}."
    rc=1
  fi
  flagged=$(printf '%s' "${STAFF}" | jq -c '[.[] | select(.accountType == "INVITED_STORE_OWNER") | .id]')
  if [ "$(printf '%s' "${flagged}" | jq 'length')" -gt 0 ]; then
    echo "FINDING: pending store-owner invitation(s): ${flagged}"
    rc=1
  fi
  flagged=$(printf '%s' "${STAFF}" | jq -c '[.[] | select(.active)
    | select(.accountType == "COLLABORATOR" or .accountType == "COLLABORATOR_TEAM_MEMBER") | .id]')
  [ "$(printf '%s' "${flagged}" | jq 'length')" -eq 0 ] ||
    echo "REVIEW: active partner collaborator accounts — confirm each is still needed: ${flagged}"
  flagged=$(printf '%s' "${STAFF}" | jq -c '[.[] | select(.accountType == "REQUESTED") | .id]')
  [ "$(printf '%s' "${flagged}" | jq 'length')" -eq 0 ] ||
    echo "REVIEW: collaborator access requests awaiting a decision: ${flagged}"

  echo "  NOT COVERED (console only): organization owners, per-staff permissions, owner 2FA (TRAP 3)."
  [ "${rc}" -ne 0 ] || echo "NO FINDING: one consistent store owner and no pending ownership transfer."
  return "${rc}"
}
# HTH Guide Excerpt: end cli-owner-and-staff-inventory

case "${1:-}" in
  ""|audit) audit ;;
  *) echo "usage: $(basename "$0") [audit]   # read-only; no other verbs" >&2; exit 2 ;;
esac
