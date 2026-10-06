#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: dropbox-1.2
#   guide:   https://howtoharden.com/guides/dropbox/#12-configure-access-permissions
#   profile: L1
#   mode:    read-only
#   requires: DROPBOX_TEAM_TOKEN(team-scoped access token with team_info.read, team_data.member, sharing.read), DROPBOX_ADMIN_MEMBER_ID(team_member_id of a team admin), HTH_DROPBOX_SHOW_IDENTITIES(optional, 1 prints external addresses)
# =============================================================================
# HTH Dropbox Control 1.2: Configure Access Permissions
# Profile Level: L1 (Crawl)
# Frameworks: NIST 800-53 AC-3, AC-6
# Source: https://howtoharden.com/guides/dropbox/#12-configure-access-permissions
# Dependencies: curl, jq
# Token: a token generated in the Dropbox App Console carries more than the
#   requires: line above lists. The console would not save team scopes without
#   team_data.member, and ticking team_data.member locks team_data.governance.read
#   and team_data.governance.write on (observed 2026-09-25). This pack calls read
#   routes only, but the token it runs with can write: store and rotate it as a
#   write-capable credential.
#
# WHAT THIS READS.
#   1. team/get_info (team_info.read) -> policies.top_level_content_policy:
#      admin_only | everyone - whether members can edit team folders at the top
#      level of the team space.
#   2. team/namespaces/list + /continue (team_data.member) -> every namespace
#      of type team_folder ("top-level team-owned folder").
#   3. sharing/list_folder_members + /continue for each one, with the
#      Dropbox-API-Select-Admin header (sharing.read; Select-Admin also needs
#      team_data.member). That route supports Select-Admin in "Whole Team" mode,
#      so one admin id reads every team folder without acting as each member.
# Each folder is reported as users / groups / invitees and how many hold
# editor or owner access, then judged on what is objectively wrong for a
# team-owned folder: members from outside the team, and pending invitations.
# Which folders should be "Only specific people" rather than "Everyone at
# [team]" is a business decision this pack prints evidence for but cannot make.
#
# WHY NOT team/team_folder/list. On a team using the team space configuration,
# team_folder/list "will only return information about the team space" - one
# row. namespaces/list returns top-level team folders in both configurations.
#
# WHY THERE IS NO WRITE BRANCH. sharing/add_folder_member, update_folder_member
# and update_folder_policy (sharing.write, Select-Admin) change who reaches team
# content. Those are per-folder decisions for a person, not an audit side effect.
#
# TRAP 1: namespaces/list "may return duplicate namespaces" - de-duplicated here.
# TRAP 2: a folder this admin cannot read is NOT clean. Any unreadable folder
#   makes the run incomplete (exit 2) unless a real finding already applies.
# TRAP 3: identities are other people's data. External addresses are counted;
#   they are printed only when HTH_DROPBOX_SHOW_IDENTITIES=1.
# TRAP 4: every list is read to the end or not at all. has_more with no cursor,
#   or 500 pages with more still to come, exits 2 instead of judging a partial list.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition or incomplete read
# =============================================================================

set -euo pipefail

[ -n "${DROPBOX_TEAM_TOKEN:-}" ] || { echo "PRECONDITION: set DROPBOX_TEAM_TOKEN to a team-scoped access token (team_info.read, team_data.member, sharing.read)" >&2; exit 2; }
[ -n "${DROPBOX_ADMIN_MEMBER_ID:-}" ] || { echo "PRECONDITION: set DROPBOX_ADMIN_MEMBER_ID to the team_member_id of a team admin (used for Dropbox-API-Select-Admin)" >&2; exit 2; }
SHOW_IDS="${HTH_DROPBOX_SHOW_IDENTITIES:-0}"
DROPBOX_API_BASE="${DROPBOX_API_BASE:-https://api.dropboxapi.com/2}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-dropbox.XXXXXX")" || { echo "PRECONDITION: mktemp failed" >&2; exit 2; }
NS_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-dropbox-ns.XXXXXX")" || { rm -f "${BODY_FILE}"; echo "PRECONDITION: mktemp failed" >&2; exit 2; }
MEM_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-dropbox-mem.XXXXXX")" || { rm -f "${BODY_FILE}" "${NS_FILE}"; echo "PRECONDITION: mktemp failed" >&2; exit 2; }
IDS_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-dropbox-ids.XXXXXX")" || { rm -f "${BODY_FILE}" "${NS_FILE}" "${MEM_FILE}"; echo "PRECONDITION: mktemp failed" >&2; exit 2; }
trap 'rm -f "${BODY_FILE}" "${NS_FILE}" "${MEM_FILE}" "${IDS_FILE}"' EXIT
RPC_CODE=""; RPC_BODY=""

# Every Dropbox RPC route is an HTTP POST with a JSON body (a no-argument route
# takes JSON `null`, as the official SDK sends it). curl implies POST when
# --data is given. The bearer token reaches curl on stdin (-K -), never argv.
rpc() { # rpc <route> <json-body> [extra curl header args...]
  local route="$1" body="$2" rc
  shift 2
  set +e
  RPC_CODE=$(printf 'header = "Authorization: Bearer %s"\n' "${DROPBOX_TEAM_TOKEN}" |
    curl -sS --max-time 60 -K - -o "${BODY_FILE}" -w '%{http_code}' \
      -H "Content-Type: application/json" "$@" \
      --data "${body}" "${DROPBOX_API_BASE}/${route}" 2>/dev/null)
  rc=$?
  set -e
  [ "${rc}" -eq 0 ] || RPC_CODE="000"
  RPC_BODY="$(cat "${BODY_FILE}" 2>/dev/null || true)"
}

rpc_strict() {
  rpc "$@"
  [ "${RPC_CODE}" = "200" ] && return 0
  local summary
  summary=$(printf '%s' "${RPC_BODY}" | jq -r '.error_summary // empty' 2>/dev/null || true)
  case "${RPC_CODE}" in
    000) echo "PRECONDITION: $1 - no HTTP response (network, DNS or TLS failure)" >&2 ;;
    401) echo "PRECONDITION: $1 returned HTTP 401 (${summary:-no summary}) - token invalid or expired, missing a scope, or the Select-Admin id is not a team admin" >&2 ;;
    403) echo "PRECONDITION: $1 returned HTTP 403 (${summary:-no summary}) - the team or plan cannot use this route" >&2 ;;
    409) echo "PRECONDITION: $1 returned HTTP 409 (${summary:-no summary})" >&2 ;;
    429) echo "PRECONDITION: $1 returned HTTP 429 - rate limited; retry after the Retry-After interval" >&2 ;;
    *)   echo "PRECONDITION: $1 returned HTTP ${RPC_CODE}: ${summary:-$(printf '%s' "${RPC_BODY}" | head -c 200)}" >&2 ;;
  esac
  exit 2
}

# HTH Guide Excerpt: begin team-folder-access-audit
rc=0
rpc_strict "team/get_info" 'null'
top_level=$(printf '%s' "${RPC_BODY}" | jq -r '.policies.top_level_content_policy[".tag"] // "(absent)"')
if [ "${top_level}" = "admin_only" ]; then
  echo "ok  top-level team folders: admin_only"
else
  echo "FINDING: top_level_content_policy = ${top_level} - members, not just admins, can edit team folders at the top level (want admin_only)"
  rc=1
fi

# Enumerate top-level team folders (namespaces/list, then /continue).
route="team/namespaces/list"; body='{}'; pages=0
while :; do
  rpc_strict "${route}" "${body}"
  printf '%s' "${RPC_BODY}" | jq -c '.namespaces[]? | select(.namespace_type[".tag"] == "team_folder")' >> "${NS_FILE}"
  more=$(printf '%s' "${RPC_BODY}" | jq -r '.has_more // false')
  cursor=$(printf '%s' "${RPC_BODY}" | jq -r '.cursor // ""')
  pages=$((pages + 1))
  [ "${more}" = "true" ] || break
  # TRAP 4: a folder list that stops early would skip folders and still pass.
  [ -n "${cursor}" ] || { echo "PRECONDITION: ${route} answered has_more=true with no cursor after ${pages} page(s) - the team folder list cannot be read to the end, so no result is claimed" >&2; exit 2; }
  [ "${pages}" -lt 500 ] || { echo "PRECONDITION: ${route} stopped after 500 pages with has_more still true - the team folder list was not read to the end, so no result is claimed" >&2; exit 2; }
  route="team/namespaces/list/continue"; body=$(jq -nc --arg c "${cursor}" '{cursor: $c}')
done
jq -rs 'unique_by(.namespace_id | tostring) | .[] | .namespace_id | tostring' "${NS_FILE}" > "${IDS_FILE}"   # TRAP 1
folders=$(wc -l < "${IDS_FILE}" | tr -d ' ')
if [ "${folders}" -eq 0 ]; then
  echo "PRECONDITION: no team_folder namespaces returned - there are no team folders to audit, so no folder result is claimed" >&2
  exit 2
fi
echo "team folders: ${folders}"

unreadable=0
while IFS= read -r ns; do
  name=$(jq -rs --arg id "${ns}" '[.[] | select((.namespace_id | tostring) == $id)][0].name' "${NS_FILE}")
  : > "${MEM_FILE}"
  route="sharing/list_folder_members"
  body=$(jq -nc --arg id "${ns}" '{shared_folder_id: $id, limit: 1000}')
  ok=1; pages=0
  while :; do
    rpc "${route}" "${body}" -H "Dropbox-API-Select-Admin: ${DROPBOX_ADMIN_MEMBER_ID}"
    if [ "${RPC_CODE}" != "200" ]; then
      echo "  UNREADABLE  ${name}  HTTP ${RPC_CODE} $(printf '%s' "${RPC_BODY}" | jq -r '.error_summary // ""' 2>/dev/null || true)"
      ok=0; break
    fi
    printf '%s' "${RPC_BODY}" | jq -c '{users: (.users // []), groups: (.groups // []), invitees: (.invitees // [])}' >> "${MEM_FILE}"
    cursor=$(printf '%s' "${RPC_BODY}" | jq -r '.cursor // ""')
    pages=$((pages + 1))
    # This route has no has_more: a cursor is present only while members remain.
    [ -n "${cursor}" ] || break
    [ "${pages}" -lt 500 ] || { echo "PRECONDITION: ${route} stopped after 500 pages with members still listed on team folder '${name}' - its membership was not read to the end, so no result is claimed" >&2; exit 2; }
    route="sharing/list_folder_members/continue"; body=$(jq -nc --arg c "${cursor}" '{cursor: $c}')
  done
  if [ "${ok}" -eq 0 ]; then unreadable=$((unreadable + 1)); continue; fi

  summary=$(jq -s '
    { users: [ .[].users[] ], groups: [ .[].groups[] ], invitees: [ .[].invitees[] ] }
    | { u: (.users | length), g: (.groups | length), i: (.invitees | length),
        ext: [ .users[] | select(.user.same_team == false) | .user.email ],
        sys: ([ .groups[] | select(.group.group_management_type[".tag"] == "system_managed") ] | length),
        edit: ([ (.users + .groups + .invitees)[] | select(.access_type[".tag"] == "editor" or .access_type[".tag"] == "owner") ] | length) }' "${MEM_FILE}")
  line=$(printf '%s' "${summary}" | jq -r '"users=\(.u) groups=\(.g) (system-managed \(.sys)) invitees=\(.i) editors/owners=\(.edit) external=\(.ext | length)"')
  echo "  ${name}  ${line}"
  ext=$(printf '%s' "${summary}" | jq '.ext | length')
  inv=$(printf '%s' "${summary}" | jq '.i')
  if [ "${ext}" -gt 0 ]; then
    echo "  FINDING: ${ext} member(s) from outside the team on team folder '${name}'"
    [ "${SHOW_IDS}" = "1" ] && printf '%s' "${summary}" | jq -r '.ext[] | "    - \(.)"'
    rc=1
  fi
  if [ "${inv}" -gt 0 ]; then
    echo "  FINDING: ${inv} pending invitation(s) on team folder '${name}' - confirm or revoke them"
    rc=1
  fi
done < "${IDS_FILE}"

if [ "${unreadable}" -gt 0 ]; then
  echo "INCOMPLETE: ${unreadable} of ${folders} team folder(s) could not be read with this admin id (TRAP 2)"
  [ "${rc}" -eq 1 ] && exit 1
  exit 2
fi
[ "${rc}" -eq 0 ] && echo "COMPLIANT: top-level folders are admin-only and no team folder has outside members or pending invitations."
exit "${rc}"
# HTH Guide Excerpt: end team-folder-access-audit
