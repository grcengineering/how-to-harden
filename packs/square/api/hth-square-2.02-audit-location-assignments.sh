#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: square-2.2
#   guide:   https://howtoharden.com/guides/square/#22-configure-location-access
#   profile: L2
#   mode:    read-only
#   requires: SQUARE_ACCESS_TOKEN(OAuth access token with EMPLOYEES_READ + MERCHANT_PROFILE_READ; a Sandbox access token for testing), SQUARE_BASE(optional; Sandbox = https://connect.squareupsandbox.com/v2), HTH_SQUARE_HTTP_TIMEOUT(optional, seconds per request, default 60)
# =============================================================================
# HTH Square Control 2.2: Configure Location Access
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 5.4; NIST 800-53 AC-6
# Source: https://howtoharden.com/guides/square/#22-configure-location-access
# Dependencies: curl, jq
#
# VERIFICATION STATUS (validate-hth-guide, 2026-09-24): every endpoint, scope and
# field below was transcribed from the Square API reference (version 2026-09-16)
# and exercised offline — fixtures replaying Square's documented responses, plus a
# fail-closed run against the Sandbox host. It has NOT yet been executed against a
# live Square account.
#
# API surface (developer.squareup.com/reference/square, version 2026-09-16):
#   POST /v2/team-members/search   EMPLOYEES_READ         TeamMember.assigned_locations
#   GET  /v2/locations             MERCHANT_PROFILE_READ  active location count
# Remediation is PUT /v2/team-members/{id} (EMPLOYEES_WRITE) with
# assigned_locations.assignment_type = EXPLICIT_LOCATIONS. This pack never calls it.
#
# TRAP 1: ALL_CURRENT_AND_FUTURE_LOCATIONS reaches every location that will EVER
#   exist, and its location_ids list is EMPTY. Counting location_ids scores the
#   broadest grant as "zero locations". Read assignment_type, not the list.
# TRAP 2: the account owner (is_owner, read-only) cannot be changed through the
#   API and reaches every location by definition — reported, never a finding.
# TRAP 3: a single-location account has nothing to separate yet. That is reported
#   as NOT APPLICABLE, not as compliant — for exactly ONE active location only —
#   and every non-owner not on EXPLICIT_LOCATIONS is still listed as a REVIEW line
#   (exit 0), because ALL_CURRENT_AND_FUTURE_LOCATIONS reaches any location added
#   later without anyone touching the member again.
#   ZERO active locations is a precondition failure (exit 2): Square creates a
#   main location when every seller signs up (Locations API guide), so an empty
#   list means the locations call returned nothing usable, not that no scoping
#   is needed — and it must never mask a member on ALL_CURRENT_AND_FUTURE_LOCATIONS.
# TRAP 4: an empty team-member result means nothing was scanned (every account
#   has at least its owner), so it is a precondition failure, never "0 findings".
# TRAP 5: every Square response type carries an errors[] field, and an HTTP 200
#   can still hold one. Any errors[] entry (or a body that is not a JSON object)
#   on ANY page is a precondition failure: a later page that failed must never
#   turn the pages already read into a verdict about the whole team.
set -euo pipefail

[ -n "${SQUARE_ACCESS_TOKEN:-}" ] || { echo "PRECONDITION: SQUARE_ACCESS_TOKEN is not set (see requires: above)" >&2; exit 2; }
SQUARE_BASE="${SQUARE_BASE:-https://connect.squareup.com/v2}"
SQUARE_VERSION="${SQUARE_VERSION:-2026-09-16}"
HTTP_TIMEOUT="${HTH_SQUARE_HTTP_TIMEOUT:-60}"
command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }
BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-square.XXXXXX")"   || { echo "PRECONDITION: mktemp failed" >&2; exit 2; }
ITEMS_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-square-i.XXXXXX")" || { echo "PRECONDITION: mktemp failed" >&2; exit 2; }
trap 'rm -f "${BODY_FILE}" "${ITEMS_FILE}"' EXIT

# j <json> <jq-args...> — pipe, not a here-string: a here-string needs a temp file
# and fails when none can be created, which must never read as a clean result.
j() { local in="$1"; shift; printf "%s" "${in}" | jq "$@"; }

# sq <url> [json-body] — GET, or POST when a body is given (curl implies POST
# from --data; no -X flag, so the pack stays honestly read-only). Transport
# failure (including a request that outlives HTTP_TIMEOUT), any non-200, or a
# 200 carrying errors[] exits 2: evidence never returned cannot be a finding.
sq() {
  local url="$1" code rc
  set +e
  if [ $# -ge 2 ]; then
    code=$(curl -sS --max-time "${HTTP_TIMEOUT}" -o "${BODY_FILE}" -w '%{http_code}' "${url}" \
      -H "Authorization: Bearer ${SQUARE_ACCESS_TOKEN}" -H "Square-Version: ${SQUARE_VERSION}" \
      -H "Content-Type: application/json" --data "$2")
  else
    code=$(curl -sS --max-time "${HTTP_TIMEOUT}" -o "${BODY_FILE}" -w '%{http_code}' "${url}" \
      -H "Authorization: Bearer ${SQUARE_ACCESS_TOKEN}" -H "Square-Version: ${SQUARE_VERSION}")
  fi
  rc=$?
  set -e
  if [ "${rc}" -ne 0 ]; then
    echo "PRECONDITION: ${url%%\?*} — no HTTP response (curl exit ${rc})" >&2; exit 2
  fi
  if [ "${code}" != "200" ]; then
    echo "PRECONDITION: ${url%%\?*} returned HTTP ${code} ($(jq -r '([.errors[]? | "\(.category)/\(.code)"] | join(", ")) as $e | if $e != "" then $e else (.type // .message // "no error body") end' "${BODY_FILE}" 2>/dev/null || echo "unparseable body"))" >&2
    if [ "${code}" = "401" ] || [ "${code}" = "403" ]; then
      echo "  Token invalid or revoked, issued for the other environment (Sandbox vs production), or missing a scope in requires:." >&2
    fi
    exit 2
  fi
  # TRAP 5: a 200 is only evidence when it is a JSON object with no errors[] entry.
  if ! jq -e '(type == "object") and (((.errors // []) | length) == 0)' "${BODY_FILE}" >/dev/null 2>&1; then
    echo "PRECONDITION: ${url%%\?*} returned HTTP 200 with an errors[] array or a non-JSON body ($(jq -r '([.errors[]? | "\(.category)/\(.code)"] | join(", ")) as $e | if $e != "" then $e else "no error detail" end' "${BODY_FILE}" 2>/dev/null || echo "unparseable body")) — the scan is incomplete, so no verdict is given" >&2
    exit 2
  fi
}

# HTH Guide Excerpt: begin api-audit-location-assignments
audit() {
  local cursor="" pages=0 body members total owners locs broad
  : > "${ITEMS_FILE}"
  while :; do
    body=$(jq -nc --arg c "${cursor}" \
      '{query: {filter: {status: "ACTIVE"}}, limit: 200} + (if $c == "" then {} else {cursor: $c} end)')
    sq "${SQUARE_BASE}/team-members/search" "${body}"
    jq -c '.team_members[]?' "${BODY_FILE}" >> "${ITEMS_FILE}"
    cursor=$(jq -r '.cursor // ""' "${BODY_FILE}")
    pages=$((pages + 1))
    [ -n "${cursor}" ] || break
    if [ "${pages}" -ge 500 ]; then
      echo "PRECONDITION: SearchTeamMembers still returned a cursor after 500 pages — the scan is incomplete, so no verdict is given." >&2
      exit 2
    fi
  done
  members=$(jq -s '.' "${ITEMS_FILE}")
  total=$(j "${members}" 'length')
  if [ "${total}" -eq 0 ]; then
    echo "PRECONDITION: SearchTeamMembers returned 0 ACTIVE team members — every account has at least its owner, so nothing was scanned." >&2
    exit 2
  fi

  sq "${SQUARE_BASE}/locations"
  locs=$(jq '[.locations[]? | select(.status == "ACTIVE")] | length' "${BODY_FILE}")
  if [ "${locs}" -eq 0 ]; then
    echo "PRECONDITION: ListLocations returned 0 ACTIVE locations — every seller has a main location, so nothing was scanned (TRAP 3)." >&2
    exit 2
  fi
  owners=$(j "${members}" '[.[] | select(.is_owner == true)] | length')

  echo "Square 2.2 — team member location assignments"
  echo "  active team members scanned: ${total} (account owner: ${owners}) · active locations: ${locs}"

  broad=$(j "${members}" -c '[.[] | select((.is_owner // false) | not)
                     | select((.assigned_locations.assignment_type // "UNSET") != "EXPLICIT_LOCATIONS")]')
  j "${broad}" -r '.[] | "    - team_member=…\((.id // "unknown")[-6:]) assignment_type=\(.assigned_locations.assignment_type // "UNSET")"'

  if [ "${locs}" -eq 1 ]; then
    echo "NOT APPLICABLE: 1 active location — location scoping has nothing to separate yet (TRAP 3)."
    if [ "$(j "${broad}" 'length')" -gt 0 ]; then
      echo "REVIEW: $(j "${broad}" 'length') non-owner team member(s) listed above are not on EXPLICIT_LOCATIONS, so any location added later will reach them automatically — re-check them before a second location opens."
    fi
    return 0
  fi

  if [ "$(j "${broad}" 'length')" -gt 0 ]; then
    echo "FINDING: $(j "${broad}" 'length') non-owner team member(s) are not limited to explicit locations (TRAP 1)."
    echo "  Assign each one EXPLICIT_LOCATIONS in Staff > Team, or PUT /v2/team-members/{id}."
    return 1
  fi
  echo "COMPLIANT: every non-owner ACTIVE team member is assigned EXPLICIT_LOCATIONS."
  return 0
}
# HTH Guide Excerpt: end api-audit-location-assignments

audit
