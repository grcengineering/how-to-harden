#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cursor-11.1
#   guide:   https://howtoharden.com/guides/cursor/#111-deploy-cursor-teams-or-enterprise-for-centralized-management
#   profile: L2
#   mode:    read-only
#   requires: CURSOR_ADMIN_API_KEY(team Admin API key from Dashboard > API Keys), HTH_MAX_ADMINS(optional, default 3), curl, jq
# =============================================================================
# HTH Cursor Control 11.1: Deploy Cursor Teams or Enterprise for Centralized Management
# Profile Level: L2 (Walk)
# Source: https://howtoharden.com/guides/cursor/#111-deploy-cursor-teams-or-enterprise-for-centralized-management
#
# Centralized management is only as strong as the set of people who can change
# it. GET /teams/members returns every member's role
# (https://cursor.com/docs/account/teams/admin-api#get-team-members); this pack
# prints the seat inventory and every non-member role, and fails when the count
# of privileged members exceeds HTH_MAX_ADMINS — a review threshold you set,
# not a vendor limit.
#
# Exit codes: 0 pass | 1 finding | 2 precondition (incl. an HTTP 200 whose body
# lacks the documented teamMembers shape, or that lists zero active members)
# =============================================================================

set -euo pipefail

[ -n "${CURSOR_ADMIN_API_KEY:-}" ] || { echo "PRECONDITION: set CURSOR_ADMIN_API_KEY — a team Admin API key (cursor.com/dashboard > API Keys)" >&2; exit 2; }
CURSOR_API_BASE="${CURSOR_API_BASE:-https://api.cursor.com}"
HTH_MAX_ADMINS="${HTH_MAX_ADMINS:-3}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }
case "${HTH_MAX_ADMINS}" in ''|*[!0-9]*) echo "PRECONDITION: HTH_MAX_ADMINS must be a whole number" >&2; exit 2 ;; esac

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-cursor-1101.XXXXXX")"
trap 'rm -f "${BODY_FILE}"' EXIT

# GET <path>. The key reaches curl on stdin as a config line (-K -), never in argv.
api_get() {
  local code rc
  set +e
  code=$(printf 'user = "%s:"\n' "${CURSOR_ADMIN_API_KEY}" \
    | curl -sS -K - -o "${BODY_FILE}" -w '%{http_code}' "${CURSOR_API_BASE}$1" 2>/dev/null)
  rc=$?
  set -e
  if [ "${rc}" -ne 0 ]; then echo "PRECONDITION: GET $1 — no HTTP response (curl exit ${rc})" >&2; exit 2; fi
  case "${code}" in
    200) return 0 ;;
    401) echo "PRECONDITION: GET $1 returned HTTP 401 — invalid key or missing scope" >&2; exit 2 ;;
    403) echo "PRECONDITION: GET $1 returned HTTP 403 — not available for this team's plan" >&2; exit 2 ;;
    *)   echo "PRECONDITION: GET $1 returned HTTP ${code}" >&2; exit 2 ;;
  esac
}

# HTH Guide Excerpt: begin api-audit-team-roles
api_get "/teams/members"
# A 200 is not proof of data. Refuse to report unless the body is the documented
# teamMembers array with a boolean isRemoved and a string role on every entry —
# a member missing either would otherwise drop out of the count unseen.
jq -e '(.teamMembers | type == "array")
       and all(.teamMembers[]; (.isRemoved | type == "boolean") and (.role | type == "string"))' \
  "${BODY_FILE}" >/dev/null 2>&1 || {
  echo "PRECONDITION: GET /teams/members returned HTTP 200 without the documented teamMembers shape — nothing was audited" >&2
  exit 2
}
ACTIVE=$(jq '[.teamMembers[] | select(.isRemoved == false)] | length' "${BODY_FILE}")
# Every team has at least one active member (the admin who issued this key).
[ "${ACTIVE}" -gt 0 ] || { echo "PRECONDITION: GET /teams/members listed zero active members — nothing was audited" >&2; exit 2; }

echo "=== Active seats by role (${ACTIVE} active) ==="
jq -r '[.teamMembers[] | select(.isRemoved == false) | .role] | group_by(.) | map("  \(.[0]): \(length)") | .[]' "${BODY_FILE}"

echo "=== Privileged members (every role other than member) ==="
jq -r '.teamMembers[] | select(.isRemoved == false and (.role | ascii_downcase) != "member") | "  \(.role)  \(.email)"' "${BODY_FILE}"
PRIV=$(jq '[.teamMembers[] | select(.isRemoved == false and (.role | ascii_downcase) != "member")] | length' "${BODY_FILE}")

if [ "${PRIV}" -gt "${HTH_MAX_ADMINS}" ]; then
  echo "FINDING: ${PRIV} privileged members exceed the review threshold of ${HTH_MAX_ADMINS}"
  exit 1
fi
echo "PASS: ${PRIV} privileged member(s), within the threshold of ${HTH_MAX_ADMINS}"
exit 0
# HTH Guide Excerpt: end api-audit-team-roles
