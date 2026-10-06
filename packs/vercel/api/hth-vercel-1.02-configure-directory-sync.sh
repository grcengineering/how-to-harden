#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 1.2: Configure Directory Sync (SCIM)
# Profile Level: L2 (Walk)
# Frameworks: NIST AC-2, IA-5(1)
# Source: https://howtoharden.com/guides/vercel/#12-configure-directory-sync-scim
# API: GET /v2/teams/{teamId} (getTeam), GET /v3/teams/{teamId}/members
#      (getTeamMembers), GET /v1/access-groups. Read-only.
# Paging: getTeamMembers pages by time -- pagination.hasNext says whether a
#      further page exists and pagination.next is the `until` timestamp that
#      requests it. listAccessGroups pages with the `next` cursor. Every page is
#      read; a member walk that cannot finish exits 2, because a partial list
#      under-reports owners.
# =============================================================================

set -euo pipefail

: "${VERCEL_TOKEN:?Set VERCEL_TOKEN}"
: "${VERCEL_TEAM_ID:?Set VERCEL_TEAM_ID}"

# HTH Guide Excerpt: begin api

# curl -f: an HTTP 4xx/5xx aborts before any output is printed as a finding.
vercel_get() {
  curl -fsS -H "Authorization: Bearer ${VERCEL_TOKEN}" "https://api.vercel.com$1"
}

# --- Verify team SAML/SCIM configuration ---
echo "=== Directory Sync Configuration ==="
vercel_get "/v2/teams/${VERCEL_TEAM_ID}" | \
  jq '{name, saml, remoteCaching, membership}'

# --- Every team member, all pages ---
MEMBERS_NDJSON=""
UNTIL=""
COMPLETE=0
for _page in $(seq 1 100); do
  PAGE="$(vercel_get "/v3/teams/${VERCEL_TEAM_ID}/members?limit=100${UNTIL:+&until=${UNTIL}}")"
  MEMBERS_NDJSON+="$(printf '%s' "${PAGE}" | jq -c '.members[]')"$'\n'
  HAS_NEXT="$(printf '%s' "${PAGE}" | jq -r 'if (.pagination | has("hasNext"))
      then (.pagination.hasNext | tostring)
      else ((.pagination.next != null) and ((.members | length) >= 100) | tostring) end')"
  if [ "${HAS_NEXT}" != "true" ]; then
    COMPLETE=1
    break
  fi
  NEXT="$(printf '%s' "${PAGE}" | jq -r '.pagination.next // empty')"
  if [ -z "${NEXT}" ] || [ "${NEXT}" = "${UNTIL}" ]; then
    break
  fi
  UNTIL="${NEXT}"
done
if [ "${COMPLETE}" -ne 1 ]; then
  echo "ERROR: team member pagination did not complete -- the member and owner lists would be partial (exit 2)." >&2
  exit 2
fi
MEMBERS_JSON="$(printf '%s' "${MEMBERS_NDJSON}" | jq -s 'unique_by(.uid)')"

echo ""
echo "=== Current Team Members ($(printf '%s' "${MEMBERS_JSON}" | jq 'length')) ==="
printf '%s' "${MEMBERS_JSON}" | jq '.[] | {uid, email, role, joinedFrom}'

# --- Audit members for role compliance ---
echo ""
echo "=== Members with Owner Role (should be minimal) ==="
printf '%s' "${MEMBERS_JSON}" | jq '.[] | select(.role == "OWNER") | {uid, email}'

# --- Verify Access Groups exist (Enterprise), all pages ---
echo ""
echo "=== Access Groups ==="
CURSOR=""
for _page in $(seq 1 100); do
  GROUPS_JSON="$(vercel_get "/v1/access-groups?teamId=${VERCEL_TEAM_ID}&limit=100${CURSOR:+&next=${CURSOR}}")"
  if [ "$(printf '%s' "${GROUPS_JSON}" | jq 'has("accessGroups")')" != "true" ]; then
    echo "(the response carries no accessGroups list -- Access Groups are not enabled for this team)"
    break
  fi
  printf '%s' "${GROUPS_JSON}" | jq '.accessGroups[] | {name, membersCount, projectsCount}'
  CURSOR="$(printf '%s' "${GROUPS_JSON}" | jq -r '.pagination.next // empty | @uri')"
  [ -n "${CURSOR}" ] || break
done
if [ -n "${CURSOR}" ]; then
  echo "ERROR: more than 100 pages of access groups -- the list above is partial (exit 2)." >&2
  exit 2
fi

# HTH Guide Excerpt: end api
