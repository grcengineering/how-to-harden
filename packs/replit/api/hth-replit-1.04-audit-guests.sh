#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: replit-1.4
#   guide:   https://howtoharden.com/guides/replit/#14-govern-guests-viewers-and-per-app-access
#   profile: L2
#   mode:    read-only
#   requires: REPLIT_ADMIN_API_KEY(Enterprise Admin API key, read-only access), REPLIT_SSO_DOMAINS(optional, comma-separated SSO email domains), REPLIT_GUEST_STALE_DAYS(optional, default 90)
# =============================================================================
# HTH Replit Control 1.4: Govern Guests, Viewers, and Per-App Access
# Profile Level: L2 (Walk) | Plan: Enterprise (Admin API is beta, account admins only)
# Frameworks: NIST 800-53 AC-2/AC-3/AC-6 | CIS Controls v8 5.4/6.1/6.8
# Sources: https://docs.replit.com/teams/identity-and-access-management/managing-members
#          https://docs.replit.com/teams/admin-api   (endpoint reference: https://api.replit.com/docs)
# Dependencies: curl, jq
#
# WHAT THIS PROVES. GET /v1/members?role=guest (scope read:*) lists every member holding
# the Guest role in at least one workspace, with lastSeen. A guest is an external
# collaborator whose access should be tied to a live engagement, so a guest never seen,
# or not seen within REPLIT_GUEST_STALE_DAYS, is a finding. Under SSO a guest's email must
# be outside your SSO domains; REPLIT_SSO_DOMAINS makes the pack re-check that promise.
# GET /v1/members/access-requests lists pending Viewer -> Member seat requests, reported
# for review (they are requests, not grants).
#
# Only ENABLED guest memberships count (each membership carries a required isDisabled
# flag). A guest whose every guest membership is disabled is listed as a NOTE, not a
# finding; a missing flag counts as enabled.
#
# NOT COVERED: which apps a guest can reach. The Admin API has no per-app access
# endpoint — use the Members page -> Guests table (and Revoke) in the console.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition (nothing was verified)
# =============================================================================

set -Eeuo pipefail
trap 'echo "PRECONDITION: unexpected failure at line ${LINENO} — nothing was verified" >&2; exit 2' ERR

REPLIT_API_BASE="${REPLIT_API_BASE:-https://api.replit.com/v1}"
[ -n "${REPLIT_ADMIN_API_KEY:-}" ] || { echo "PRECONDITION: set REPLIT_ADMIN_API_KEY (an Enterprise Admin API key, rpl_…; read-only access is enough)" >&2; exit 2; }
command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }
BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-replit.XXXXXX")" || { echo "PRECONDITION: mktemp failed" >&2; exit 2; }
ACC_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-replit.XXXXXX")" || { echo "PRECONDITION: mktemp failed" >&2; exit 2; }
trap 'rm -f "${BODY_FILE}" "${ACC_FILE}"' EXIT

# One GET into BODY_FILE. Anything but a 200 carrying {data: [...], pagination: {...}} is a
# precondition (exit 2): a control is never judged on evidence that was not returned.
api_get() {
  local code rc=0
  code=$(curl -sS -o "${BODY_FILE}" -w '%{http_code}' --max-time 60 \
    -H "Authorization: Bearer ${REPLIT_ADMIN_API_KEY}" \
    -H "Accept: application/json" \
    "${REPLIT_API_BASE}$1") || rc=$?
  if [ "${rc}" -ne 0 ]; then
    echo "PRECONDITION: GET $1 — no HTTP response (curl exit ${rc})" >&2; exit 2
  fi
  if [ "${code}" != "200" ]; then
    echo "PRECONDITION: GET $1 returned HTTP ${code} ($(jq -r '.error.code // "unknown"' "${BODY_FILE}" 2>/dev/null || echo unknown))" >&2
    case "${code}" in 401|403) echo "  The key is invalid or revoked, or is not an Enterprise account-admin key." >&2 ;; esac
    exit 2
  fi
  if ! jq -e '(.data | type) == "array" and (.pagination.hasMore | type) == "boolean"' "${BODY_FILE}" >/dev/null 2>&1; then
    echo "PRECONDITION: GET $1 — HTTP 200 without a {data, pagination} body; refusing to read it as an empty list" >&2; exit 2
  fi
}

# Follows pagination.cursor until hasMore is false; result lands in ITEMS (a JSON array).
paginate() { # paginate <path> [query]
  local query="${2:+$2&}" cursor="" pages=0
  : > "${ACC_FILE}"
  while :; do
    if [ -n "${cursor}" ]; then
      api_get "$1?${query}limit=100&cursor=$(jq -rn --arg c "${cursor}" '$c | @uri')"
    else
      api_get "$1?${query}limit=100"
    fi
    jq -c '.data[]' "${BODY_FILE}" >> "${ACC_FILE}"
    pages=$((pages + 1))
    if [ "$(jq -r '.pagination.hasMore' "${BODY_FILE}")" != "true" ]; then break; fi
    cursor=$(jq -r '.pagination.cursor' "${BODY_FILE}")
    if [ "${pages}" -ge 1000 ]; then echo "PRECONDITION: $1 did not finish paginating after 1000 pages" >&2; exit 2; fi
  done
  ITEMS=$(jq -s '.' "${ACC_FILE}")
}

# HTH Guide Excerpt: begin guest-review-audit
# Stale guests (never seen, or idle past REPLIT_GUEST_STALE_DAYS) and guests inside your
# SSO domains are findings; pending seat requests are listed for review.
STALE_DAYS="${REPLIT_GUEST_STALE_DAYS:-90}"
DOMAINS=$(jq -cn --arg d "${REPLIT_SSO_DOMAINS:-}" '$d | ascii_downcase | split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0))')
paginate "/members" "role=guest"
GUESTS="${ITEMS}"
# lastSeen is RFC 3339; drop fractional seconds before fromdateiso8601. An unparseable
# or null timestamp counts as stale — absence of evidence is not activity.
REVIEWED=$(printf '%s' "${GUESTS}" | jq -c --argjson days "${STALE_DAYS}" --argjson doms "${DOMAINS}" '
  (now - ($days * 86400)) as $cutoff
  | [ .[]
      | (.user.email | split("@") | last | ascii_downcase) as $dom
      | (try (.lastSeen | sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601) catch null) as $seen
      | [.workspaces[] | select(.role == "guest")] as $g
      | [$g[] | select(.isDisabled != true)] as $on
      | { username: .user.username, domain: $dom,
          workspaces: ([$on[].slug] | join(",")),
          disabledIn: ([$g[] | select(.isDisabled == true) | .slug] | join(",")),
          dormant: (($g | length) > 0 and ($on | length) == 0),
          lastSeen: (.lastSeen // "never"),
          stale: ($seen == null or $seen < $cutoff),
          internal: any($doms[]; . == $dom) } ]')
FLAGGED=$(printf '%s' "${REVIEWED}" | jq -c '[.[] | select((.dormant | not) and (.stale or .internal))]')
DORMANT=$(printf '%s' "${REVIEWED}" | jq -c '[.[] | select(.dormant)]')
N_GUESTS=$(printf '%s' "${GUESTS}" | jq 'length')
N_FLAGGED=$(printf '%s' "${FLAGGED}" | jq 'length')

paginate "/members/access-requests" "status=pending"
PENDING=$(printf '%s' "${ITEMS}" | jq 'length')

echo "Replit 1.4 — guest review"
echo "  guests: ${N_GUESTS}; stale threshold: ${STALE_DAYS} days; SSO domains checked: $(printf '%s' "${DOMAINS}" | jq -r 'if length == 0 then "none supplied" else join(",") end')"
echo "  pending Viewer -> Member seat requests: ${PENDING}"
if [ "$(printf '%s' "${DORMANT}" | jq 'length')" -gt 0 ]; then
  echo "NOTE: every guest membership disabled (no guest access, so not a finding; review on the Members page -> Guests table):"
  printf '%s' "${DORMANT}" | jq -r '.[] | "    - \(.username) (@\(.domain)) disabled-in=\(.disabledIn) lastSeen=\(.lastSeen)"'
fi
if [ "${N_FLAGGED}" -gt 0 ]; then
  echo "FINDING: ${N_FLAGGED} guest(s) to revoke or justify (Members page -> Guests table -> Revoke):"
  printf '%s' "${FLAGGED}" | jq -r '.[] | "    - \(.username) (@\(.domain)) workspaces=\(.workspaces) lastSeen=\(.lastSeen)\(if .internal then " INTERNAL-DOMAIN" else "" end)\(if .stale then " STALE" else "" end)"'
  exit 1
fi
echo "COMPLIANT: every guest with an enabled guest membership was seen within ${STALE_DAYS} days and none uses an SSO domain."
exit 0
# HTH Guide Excerpt: end guest-review-audit
