#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cursor-1.4
#   guide:   https://howtoharden.com/guides/cursor/#14-enable-scim-provisioning-enterprise
#   profile: L2
#   mode:    read-only
#   requires: CURSOR_ADMIN_API_KEY(team Admin API key from Dashboard > API Keys, read:* or admin:*), HTH_EXPECT_REMOVED(optional, comma-separated emails), curl, jq
# =============================================================================
# HTH Cursor Control 1.4: Enable SCIM Provisioning (Enterprise)
# Profile Level: L2 (Walk) | NIST 800-53: AC-2
# Source: https://howtoharden.com/guides/cursor/#14-enable-scim-provisioning-enterprise
#
# SCIM itself is configured in the dashboard and the IdP — the Admin API has no
# SCIM-configuration route (https://cursor.com/docs/account/teams/admin-api).
# What the API can do is PROVE the outcome SCIM exists for:
#   GET /teams/members          -> each member's role and `isRemoved`
#   GET /teams/directory-groups -> the directory groups synced from the IdP
# The deprovisioning test in the guide ("remove a test user in the IdP, confirm
# Cursor deactivates them") becomes a command: set HTH_EXPECT_REMOVED to the
# emails you unassigned and this pack fails if any of them is still active.
#
# Exit codes: 0 pass | 1 finding | 2 precondition (incl. an HTTP 200 whose body
# lacks the documented teamMembers/groups shape, or that lists zero active members)
# =============================================================================

set -euo pipefail

[ -n "${CURSOR_ADMIN_API_KEY:-}" ] || { echo "PRECONDITION: set CURSOR_ADMIN_API_KEY — a team Admin API key (cursor.com/dashboard > API Keys)" >&2; exit 2; }
CURSOR_API_BASE="${CURSOR_API_BASE:-https://api.cursor.com}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-cursor-104.XXXXXX")"
MEMBERS="$(mktemp "${TMPDIR:-/tmp}/hth-cursor-104-members.XXXXXX")"
trap 'rm -f "${BODY_FILE}" "${MEMBERS}"' EXIT

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
    401) echo "PRECONDITION: GET $1 returned HTTP 401 — invalid key or missing read:* scope" >&2; exit 2 ;;
    403) echo "PRECONDITION: GET $1 returned HTTP 403 — not available for this team's plan" >&2; exit 2 ;;
    *)   echo "PRECONDITION: GET $1 returned HTTP ${code}" >&2; exit 2 ;;
  esac
}

# HTH Guide Excerpt: begin api-audit-scim-deprovisioning
FINDINGS=0

# 1. Member inventory: active vs removed, active members by role.
# A 200 is not proof of data. Without the documented teamMembers array (string
# email and role, boolean isRemoved on every entry) the deprovisioning check
# below would report "removed or absent" for everyone, so refuse to go on.
api_get "/teams/members"
jq -e '(.teamMembers | type == "array")
       and all(.teamMembers[]; (.email | type == "string") and (.role | type == "string")
                               and (.isRemoved | type == "boolean"))' \
  "${BODY_FILE}" >/dev/null 2>&1 || {
  echo "PRECONDITION: GET /teams/members returned HTTP 200 without the documented teamMembers shape — nothing was audited" >&2
  exit 2
}
cp "${BODY_FILE}" "${MEMBERS}"
ACTIVE=$(jq '[.teamMembers[] | select(.isRemoved == false)] | length' "${MEMBERS}")
REMOVED=$(jq '[.teamMembers[] | select(.isRemoved == true)] | length' "${MEMBERS}")
# Every team has at least one active member (the admin who issued this key).
[ "${ACTIVE}" -gt 0 ] || { echo "PRECONDITION: GET /teams/members listed zero active members — nothing was audited" >&2; exit 2; }
echo "=== Team members: ${ACTIVE} active, ${REMOVED} removed ==="
jq -r '[.teamMembers[] | select(.isRemoved == false) | .role] | group_by(.) | map("  \(.[0]): \(length)") | .[]' "${MEMBERS}"

# 2. Directory groups synced from the IdP (SCIM group push)
api_get "/teams/directory-groups?page=1&pageSize=200"
jq -e '.groups | type == "array"' "${BODY_FILE}" >/dev/null 2>&1 || {
  echo "PRECONDITION: GET /teams/directory-groups returned HTTP 200 without the documented groups array — nothing was audited" >&2
  exit 2
}
DIR_GROUPS=$(jq 'if (.pagination.totalCount | type) == "number" then .pagination.totalCount else (.groups | length) end' "${BODY_FILE}")
echo "=== Directory groups: ${DIR_GROUPS} ==="
jq -r '.groups[] | "  \(.name)  members=\(.memberCount)"' "${BODY_FILE}"
if [ "${DIR_GROUPS}" -eq 0 ]; then
  echo "  FINDING: no directory groups — SCIM group push is not configured (or SCIM is not set up)"
  FINDINGS=$((FINDINGS + 1))
fi

# 3. Deprovisioning proof: every email you unassigned in the IdP must be removed
if [ -n "${HTH_EXPECT_REMOVED:-}" ]; then
  echo "=== Deprovisioning check ==="
  OLDIFS="${IFS}"; IFS=','
  for EMAIL in ${HTH_EXPECT_REMOVED}; do
    IFS="${OLDIFS}"
    EMAIL="$(printf '%s' "${EMAIL}" | tr -d '[:space:]')"
    [ -n "${EMAIL}" ] || continue
    STILL=$(jq --arg e "${EMAIL}" '[.teamMembers[] | select((.email | ascii_downcase) == ($e | ascii_downcase) and .isRemoved == false)] | length' "${MEMBERS}")
    if [ "${STILL}" -gt 0 ]; then
      echo "  FINDING: ${EMAIL} is still an ACTIVE member — deprovisioning did not reach Cursor"
      FINDINGS=$((FINDINGS + 1))
    else
      echo "  PASS: ${EMAIL} is removed or absent"
    fi
  done
  IFS="${OLDIFS}"
fi

[ "${FINDINGS}" -eq 0 ] && { echo "PASS"; exit 0; }
echo "${FINDINGS} finding(s)"
exit 1
# HTH Guide Excerpt: end api-audit-scim-deprovisioning
