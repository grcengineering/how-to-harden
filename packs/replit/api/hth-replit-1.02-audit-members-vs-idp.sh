#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: replit-1.2
#   guide:   https://howtoharden.com/guides/replit/#12-automate-provisioning-with-scim-and-audit-the-legacy-member-gap
#   profile: L2
#   mode:    read-only
#   requires: REPLIT_ADMIN_API_KEY(Enterprise Admin API key, read-only access), REPLIT_IDP_EXPORT(path to a file of IdP-assigned emails, one per line)
# =============================================================================
# HTH Replit Control 1.2: Automate Provisioning with SCIM (and Audit the Legacy-Member Gap)
# Profile Level: L2 (Walk) | Plan: Enterprise (Admin API is beta, account admins only)
# Frameworks: NIST 800-53 AC-2/AC-2(3) | CIS Controls v8 5.1/5.3/6.1
# Sources: https://docs.replit.com/teams/identity-and-access-management/scim
#          https://docs.replit.com/teams/admin-api   (endpoint reference: https://api.replit.com/docs)
# Dependencies: curl, jq
#
# WHAT THIS PROVES. SCIM never removes members who joined before it was enabled
# ("legacy" members), so the deprovisioning hole is "a Replit member your IdP no longer
# assigns". GET /v1/members (scope read:*) returns every Account member with their email,
# workspace roles and isAccountAdmin — but no field saying whether SCIM provisioned them,
# so the only reliable test is a diff against what the IdP assigns. Export the emails
# assigned to the Replit application from your IdP and point REPLIT_IDP_EXPORT at it.
#
# Guests are excluded from the diff on purpose: under SSO a Guest's email must be OUTSIDE
# your SSO domains, so guests are never in the IdP export. Review them with the 1.4 pack.
#
# Access means an ENABLED workspace membership (each membership carries a required
# isDisabled flag) or the account-admin flag, which does not depend on workspaces. A member
# whose every membership is disabled is listed as a NOTE, not a finding; a member with no
# visible membership at all still counts as holding access, so an unknown never passes.
#
# Removing a member has no Admin API endpoint — act on the findings in the console
# (Members page -> row menu -> remove). Member emails are compared, never printed: the
# report shows usernames and the email domain only.
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

# HTH Guide Excerpt: begin members-vs-idp-audit
# Diff every non-guest Replit member against the emails your IdP assigns to Replit.
[ -r "${REPLIT_IDP_EXPORT:-}" ] || { echo "PRECONDITION: set REPLIT_IDP_EXPORT to a readable file of IdP-assigned emails" >&2; exit 2; }
IDP=$(jq -R 'ascii_downcase | gsub("^\\s+|\\s+$"; "") | select(length > 0 and (startswith("#") | not))' \
        "${REPLIT_IDP_EXPORT}" | jq -s 'unique')
if [ "$(printf '%s' "${IDP}" | jq 'length')" -eq 0 ]; then
  echo "PRECONDITION: ${REPLIT_IDP_EXPORT} holds no emails — nothing to compare against" >&2; exit 2
fi

paginate "/members"
MEMBERS="${ITEMS}"
TOTAL=$(printf '%s' "${MEMBERS}" | jq 'length')
if [ "${TOTAL}" -eq 0 ]; then
  echo "PRECONDITION: /members returned no members — an Enterprise account always has its account admin" >&2; exit 2
fi

# Classify each member: "disabled" = has memberships, every one disabled, not an account
# admin; "guest" = every ENABLED membership is a guest role, not an account admin;
# anything else holds access. A missing isDisabled counts as enabled.
CLASSED=$(printf '%s' "${MEMBERS}" | jq -c --argjson idp "${IDP}" '
  [ .[]
    | [.workspaces[] | select(.isDisabled != true)] as $on
    | . + { assigned: ((.user.email | ascii_downcase) as $e | any($idp[]; . == $e)),
            class: (if .isAccountAdmin == true then "access"
                    elif (.workspaces | length) > 0 and ($on | length) == 0 then "disabled"
                    elif ($on | length) > 0 and ($on | all(.role == "guest")) then "guest"
                    else "access" end) } ]')
ORPHANS=$(printf '%s' "${CLASSED}" | jq -c '[.[] | select(.class == "access" and (.assigned | not))]')
DORMANT=$(printf '%s' "${CLASSED}" | jq -c '[.[] | select(.class == "disabled" and (.assigned | not))]')
GUESTS=$(printf '%s' "${CLASSED}" | jq '[.[] | select(.class == "guest")] | length')
DISABLED=$(printf '%s' "${CLASSED}" | jq '[.[] | select(.class == "disabled")] | length')
COUNT=$(printf '%s' "${ORPHANS}" | jq 'length')
LINE='"    - \(.user.username) (@\(.user.email | split("@") | last)) roles=\([.workspaces[] | "\(.slug):\(.role)\(if .isDisabled == true then "(disabled)" else "" end)"] | join(",")) accountAdmin=\(.isAccountAdmin) lastSeen=\(.lastSeen // "never")"'

echo "Replit 1.2 — Account members vs IdP assignment"
echo "  members: ${TOTAL} (guest-only, excluded: ${GUESTS}; every membership disabled: ${DISABLED}); IdP-assigned emails: $(printf '%s' "${IDP}" | jq 'length')"
if [ "$(printf '%s' "${DORMANT}" | jq 'length')" -gt 0 ]; then
  echo "NOTE: outside the IdP but every workspace membership is disabled (no workspace access, so not a finding; review on the Members page):"
  printf '%s' "${DORMANT}" | jq -r ".[] | ${LINE}"
fi
if [ "${COUNT}" -gt 0 ]; then
  echo "FINDING: ${COUNT} member(s) hold Replit access your IdP does not assign — SCIM will never remove them:"
  printf '%s' "${ORPHANS}" | jq -r ".[] | ${LINE}"
  exit 1
fi
echo "COMPLIANT: every non-guest member with an enabled membership (or account admin) is assigned to Replit in the IdP."
exit 0
# HTH Guide Excerpt: end members-vs-idp-audit
