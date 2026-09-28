#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: replit-1.3
#   guide:   https://howtoharden.com/guides/replit/#13-tier-your-admins-account-admin-vs-workspace-admin
#   profile: L2
#   mode:    read-only
#   requires: REPLIT_ADMIN_API_KEY(Enterprise Admin API key, read-only access), REPLIT_ADMIN_ALLOWLIST(optional file of approved account-admin usernames), REPLIT_MAX_ACCOUNT_ADMINS(optional, default 3)
# =============================================================================
# HTH Replit Control 1.3: Tier Your Admins: Account Admin vs Workspace Admin
# Profile Level: L2 (Walk) | Plan: Enterprise (Admin API is beta, account admins only)
# Frameworks: NIST 800-53 AC-6(1)/AC-6(5) | CIS Controls v8 5.4/6.8
# Sources: https://docs.replit.com/teams/identity-and-access-management/account-and-workspace-admins
#          https://docs.replit.com/teams/admin-api   (endpoint reference: https://api.replit.com/docs)
# Dependencies: curl, jq
#
# WHAT THIS PROVES. GET /v1/members (scope read:*) returns, per member, isAccountAdmin
# ("Whether the user administers the Account independently of workspace roles") and each
# workspace role (admin | member | viewer | guest). Account admin is the org-takeover
# role — it owns SAML, SCIM, audit logs and billing — so its roster is compared against a
# governed list and a ceiling. Workspace admins are reported per workspace for review.
#
# Promotion and demotion have no Admin API endpoint: fix findings in Settings -> Seats
# (non-SCIM) or through the membership of the designated Account admin group in your IdP
# (SCIM). The report prints usernames, never emails.
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

# HTH Guide Excerpt: begin admin-roster-audit
# Account admins against a ceiling and (optionally) a governed allowlist; workspace
# admins reported per workspace.
MAX="${REPLIT_MAX_ACCOUNT_ADMINS:-3}"
case "${MAX}" in
  ''|*[!0-9]*) echo "PRECONDITION: REPLIT_MAX_ACCOUNT_ADMINS must be a whole number (got '${MAX}')" >&2; exit 2 ;;
esac
paginate "/members"
MEMBERS="${ITEMS}"
ADMINS=$(printf '%s' "${MEMBERS}" | jq -c '[.[] | select(.isAccountAdmin == true) | .user.username]')
N=$(printf '%s' "${ADMINS}" | jq 'length')
if [ "${N}" -eq 0 ]; then
  echo "PRECONDITION: no account admin in /members — the key itself belongs to one, so this read is wrong" >&2; exit 2
fi
FINDING=0
echo "Replit 1.3 — admin roster"
echo "  account admins: ${N} (ceiling REPLIT_MAX_ACCOUNT_ADMINS=${MAX})"
printf '%s' "${ADMINS}" | jq -r '.[] | "    - \(.)"'
if [ "${N}" -gt "${MAX}" ]; then
  echo "FINDING: ${N} account admins exceeds ${MAX} — demote the surplus (Settings -> Seats, or the Account admin group under SCIM)."
  FINDING=1
fi
if [ -n "${REPLIT_ADMIN_ALLOWLIST:-}" ]; then
  [ -r "${REPLIT_ADMIN_ALLOWLIST}" ] || { echo "PRECONDITION: REPLIT_ADMIN_ALLOWLIST is not readable" >&2; exit 2; }
  ALLOW=$(jq -R 'ascii_downcase | gsub("^\\s+|\\s+$"; "") | select(length > 0 and (startswith("#") | not))' \
            "${REPLIT_ADMIN_ALLOWLIST}" | jq -s 'unique')
  UNAPPROVED=$(printf '%s' "${ADMINS}" | jq -c --argjson a "${ALLOW}" '[.[] | select((ascii_downcase) as $u | any($a[]; . == $u) | not)]')
  if [ "$(printf '%s' "${UNAPPROVED}" | jq 'length')" -gt 0 ]; then
    echo "FINDING: account admins missing from the governed list: $(printf '%s' "${UNAPPROVED}" | jq -r 'join(", ")')"
    FINDING=1
  fi
fi
# Workspace admins who are NOT account admins, grouped by workspace slug. A disabled
# membership grants nothing, so it is shown but not counted.
echo "  workspace admins (not account admins), per workspace:"
printf '%s' "${MEMBERS}" | jq -r '
  [ .[] | select(.isAccountAdmin != true) | .user.username as $u
    | .workspaces[] | select(.role == "admin")
    | {slug, on: (.isDisabled != true), u: ($u + (if .isDisabled == true then " (disabled)" else "" end))} ]
  | group_by(.slug) | .[] | "    - \(.[0].slug): \([.[] | select(.on)] | length) enabled — \([.[].u] | join(", "))"'
if [ "${FINDING}" -eq 0 ]; then
  echo "COMPLIANT: account admins are within the ceiling and on the governed list (when one was supplied)."
fi
exit "${FINDING}"
# HTH Guide Excerpt: end admin-roster-audit
