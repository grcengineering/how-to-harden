#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: shopify-3.1
#   guide:   https://howtoharden.com/guides/shopify/#31-configure-api-access
#   profile: L2
#   mode:    read-only
#   requires: SHOPIFY_STORE(<name>.myshopify.com), SHOPIFY_ADMIN_TOKEN(Admin API access token of the app being audited; no extra scope needed), SHOPIFY_EXPECTED_SCOPES(comma-separated scope handles the app is meant to hold)
# =============================================================================
# HTH Shopify Control 3.1: Configure API Access — granted-scope audit for your own app
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 3.11 | NIST 800-53 SC-12
# Source: https://howtoharden.com/guides/shopify/#31-configure-api-access
# API:    https://shopify.dev/docs/api/admin-graphql/latest/queries/currentAppInstallation
#         https://shopify.dev/docs/api/admin-graphql/latest/objects/AppInstallation (accessScopes)
#         https://shopify.dev/docs/api/usage/access-scopes
# Dependencies: curl, jq
#
# READ-ONLY. One query: currentAppInstallation { accessScopes { handle } }, which
# "Returns the AppInstallation for the currently authenticated app" and "Provides
# access to granted access scopes". It answers one question for the token you
# hold: does it carry any scope beyond the list you meant to grant? That is the
# guide's "use minimum required scopes" step, checked instead of assumed.
#
# ── TRAP 1: this sees ONE app — the one whose token you pass ─────────────────
# currentAppInstallation is scoped to the authenticated app. It does not list
# the other apps installed on the store, so third-party app review stays in the
# console (Settings -> Apps and sales channels). Run this once per in-house app
# or custom-app token you manage.
#
# ── TRAP 2: handles are compared exactly ─────────────────────────────────────
# The access-scopes reference lists read_ and write_ handles separately and does
# not state that one implies the other, so this pack does not infer it. List
# every handle the app is meant to hold, exactly as declared in its app
# configuration ([access_scopes] in shopify.app.toml) or custom-app settings.
#
# ── TRAP 3: a missing installation is a failure, not "no scopes" ─────────────
# A null currentAppInstallation means the token did not resolve to an app, so
# the pack exits 2. An installation with an empty scope list is a real answer.
#
# Reducing scopes is a write: redeploy the app configuration with fewer scopes,
# or have the app call appRevokeAccessScopes on its own optional scopes. This
# pack does neither.
#
# Exit codes: 0 no excess scope | 1 excess scope granted | 2 precondition
# =============================================================================

set -euo pipefail

: "${SHOPIFY_STORE:?set SHOPIFY_STORE to the <name>.myshopify.com domain of the store}"
: "${SHOPIFY_ADMIN_TOKEN:?set SHOPIFY_ADMIN_TOKEN — the Admin API access token of the app to audit}"
: "${SHOPIFY_EXPECTED_SCOPES:?set SHOPIFY_EXPECTED_SCOPES, e.g. read_products,write_products}"
SHOPIFY_API_VERSION="${SHOPIFY_API_VERSION:-2026-07}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

# The token is sent only to a *.myshopify.com Admin API host.
[[ "${SHOPIFY_STORE}" =~ ^[a-z0-9][a-z0-9-]*\.myshopify\.com$ ]] || {
  echo "PRECONDITION: SHOPIFY_STORE must be a <name>.myshopify.com domain" >&2; exit 2; }
[[ "${SHOPIFY_API_VERSION}" =~ ^([0-9]{4}-[0-9]{2}|unstable)$ ]] || {
  echo "PRECONDITION: SHOPIFY_API_VERSION must look like 2026-07" >&2; exit 2; }

ENDPOINT="https://${SHOPIFY_STORE}/admin/api/${SHOPIFY_API_VERSION}/graphql.json"
BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-shopify-301.XXXXXX")" || {
  echo "PRECONDITION: cannot create a temp file" >&2; exit 2; }
trap 'rm -f "${BODY_FILE}"' EXIT

GQL_BODY=""

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
    echo "PRECONDITION: the query returned GraphQL errors:" >&2
    printf '%s' "${GQL_BODY}" | jq -r '
      if (.errors | type) == "array" then .errors[]
        | if type == "object" then "  - \(.extensions.code // "ERROR"): \(.message // tostring)"
          else "  - ERROR: \(tostring)" end
      else "  - ERROR: \(.errors | tostring)" end' >&2 || true
    exit 2
  fi
}

# HTH Guide Excerpt: begin granted-scope-audit
# Compare the scopes this app's token actually holds with the scopes it is
# meant to hold. Any extra handle is a finding.
audit() {
  gql 'query HthAppScopes { currentAppInstallation { accessScopes { handle } } }' '{}'
  printf '%s' "${GQL_BODY}" | jq -e '.data.currentAppInstallation.accessScopes | type == "array"' >/dev/null || {
    echo "PRECONDITION: the token did not resolve to an app installation (TRAP 3)" >&2; exit 2; }

  local granted expected excess missing
  granted=$(printf '%s' "${GQL_BODY}" | jq -c '[.data.currentAppInstallation.accessScopes[].handle] | unique')
  expected=$(jq -nc --arg s "${SHOPIFY_EXPECTED_SCOPES}" \
    '$s | split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0)) | unique')
  [ "$(printf '%s' "${expected}" | jq 'length')" -gt 0 ] || {
    echo "PRECONDITION: SHOPIFY_EXPECTED_SCOPES parsed to an empty list" >&2; exit 2; }
  excess=$(jq -nc --argjson g "${granted}" --argjson e "${expected}" '$g - $e')
  missing=$(jq -nc --argjson g "${granted}" --argjson e "${expected}" '$e - $g')

  echo "Shopify 3.1 — granted scopes for this app's token (store ${SHOPIFY_STORE}, API ${SHOPIFY_API_VERSION})"
  echo "  granted:  $(printf '%s' "${granted}" | jq -r 'length') — $(printf '%s' "${granted}" | jq -r 'join(", ")')"
  echo "  expected: $(printf '%s' "${expected}" | jq -r 'length') — $(printf '%s' "${expected}" | jq -r 'join(", ")')"
  [ "$(printf '%s' "${missing}" | jq 'length')" -eq 0 ] ||
    echo "  note: expected but not granted (not a security finding): $(printf '%s' "${missing}" | jq -r 'join(", ")')"

  if [ "$(printf '%s' "${excess}" | jq 'length')" -gt 0 ]; then
    echo "FINDING: this token holds scopes beyond the expected list: $(printf '%s' "${excess}" | jq -r 'join(", ")')"
    echo "  Remove them from the app configuration and redeploy, or revoke optional scopes with appRevokeAccessScopes."
    return 1
  fi
  echo "NO FINDING: every granted scope is on the expected list."
}
# HTH Guide Excerpt: end granted-scope-audit

case "${1:-}" in
  ""|audit) audit ;;
  *) echo "usage: $(basename "$0") [audit]   # read-only; no other verbs" >&2; exit 2 ;;
esac
