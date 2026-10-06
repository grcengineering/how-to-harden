#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: dropbox-1.4
#   guide:   https://howtoharden.com/guides/dropbox/#14-assign-granular-admin-roles
#   profile: L2
#   mode:    read-only
#   requires: DROPBOX_TEAM_TOKEN(team-scoped access token with members.read), HTH_DROPBOX_MAX_TEAM_ADMINS(optional, default 3), HTH_DROPBOX_TEAM_ADMIN_ROLE_ID(optional)
# =============================================================================
# HTH Dropbox Control 1.4: Assign Granular Admin Roles
# Profile Level: L2 (Walk)
# Frameworks: NIST 800-53 AC-6, AC-6(7)
# Source: https://howtoharden.com/guides/dropbox/#14-assign-granular-admin-roles
# Dependencies: curl, jq
# Token: a token generated in the Dropbox App Console carries more than the
#   requires: line above lists. The console would not save team scopes without
#   team_data.member, and ticking team_data.member locks team_data.governance.read
#   and team_data.governance.write on (observed 2026-09-25). This pack calls read
#   routes only, but the token it runs with can write: store and rotate it as a
#   write-capable credential.
#
# WHAT THIS READS. team/members/get_available_team_member_roles lists the roles
# this team can assign (role_id, name, description); team/members/list_v2 and
# team/members/list/continue_v2 return every member with a `roles` list. Both
# need members.read. The pack counts holders per role and flags a Team admin
# population above HTH_DROPBOX_MAX_TEAM_ADMINS.
#
# WHY THERE IS NO WRITE BRANCH. team/members/set_admin_permissions_v2
# (members.write) replaces a member's role set, and "only up to one role is
# allowed". A script that demotes admins can remove the last Team admin or the
# admin whose token it is running on, so role changes stay a deliberate,
# per-member console or API action - never a side effect of an audit.
#
# TRAP 1: dbxcli `team list-members` prints the legacy v1 AdminTier (team,
#   user_management or support admin), not the eight granular roles, so it
#   cannot answer this control. The v2 routes above can.
# TRAP 2: the Team admin role is found by name, because Dropbox documents that
#   role_id is stable for Dropbox-defined roles but does not publish the value.
#   If no available role is named like "Team admin", the pack stops rather than
#   report zero admins. Pin the id with HTH_DROPBOX_TEAM_ADMIN_ROLE_ID once seen.
# TRAP 3: on Standard and Business every admin is a full admin, so there are no
#   granular roles to assign; the admin count is still the compensating check.
# TRAP 4: `roles` on each member is documented as "optional, nullable". A team
#   always has at least one Team admin, so a run where no member carries a role,
#   or none holds the Team admin role, did not see the roles; it exits 2 rather
#   than report "0 Team admins, within the limit".
# TRAP 5: the member list is read to the end or not at all. has_more with no
#   cursor, or 500 pages with has_more still true, exits 2.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition (auth, scope, transport)
# =============================================================================

set -euo pipefail

[ -n "${DROPBOX_TEAM_TOKEN:-}" ] || { echo "PRECONDITION: set DROPBOX_TEAM_TOKEN to a team-scoped access token with members.read" >&2; exit 2; }
MAX_ADMINS="${HTH_DROPBOX_MAX_TEAM_ADMINS:-3}"
DROPBOX_API_BASE="${DROPBOX_API_BASE:-https://api.dropboxapi.com/2}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }
case "${MAX_ADMINS}" in ''|*[!0-9]*) echo "PRECONDITION: HTH_DROPBOX_MAX_TEAM_ADMINS must be a whole number" >&2; exit 2 ;; esac

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-dropbox.XXXXXX")" || { echo "PRECONDITION: mktemp failed" >&2; exit 2; }
MEMBERS_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-dropbox-members.XXXXXX")" || { rm -f "${BODY_FILE}"; echo "PRECONDITION: mktemp failed" >&2; exit 2; }
trap 'rm -f "${BODY_FILE}" "${MEMBERS_FILE}"' EXIT
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
    401) echo "PRECONDITION: $1 returned HTTP 401 (${summary:-no summary}) - token invalid or expired, or missing the scope this route needs" >&2 ;;
    403) echo "PRECONDITION: $1 returned HTTP 403 (${summary:-no summary}) - the team or plan cannot use this route" >&2 ;;
    409) echo "PRECONDITION: $1 returned HTTP 409 (${summary:-no summary})" >&2 ;;
    429) echo "PRECONDITION: $1 returned HTTP 429 - rate limited; retry after the Retry-After interval" >&2 ;;
    *)   echo "PRECONDITION: $1 returned HTTP ${RPC_CODE}: ${summary:-$(printf '%s' "${RPC_BODY}" | head -c 200)}" >&2 ;;
  esac
  exit 2
}

# HTH Guide Excerpt: begin admin-role-audit
rpc_strict "team/members/get_available_team_member_roles" 'null'
ROLES=$(printf '%s' "${RPC_BODY}" | jq -c '.roles // []')
[ "$(printf '%s' "${ROLES}" | jq 'length')" -gt 0 ] || { echo "PRECONDITION: no assignable roles returned" >&2; exit 2; }

# TRAP 2: identify the Team admin role by name unless its id is pinned.
TEAM_ROLE_ID="${HTH_DROPBOX_TEAM_ADMIN_ROLE_ID:-}"
if [ -z "${TEAM_ROLE_ID}" ]; then
  TEAM_ROLE_ID=$(printf '%s' "${ROLES}" | jq -r \
    '[.[] | select(.name | ascii_downcase | test("^team( admin)?$"))][0].role_id // ""')
fi
if [ -z "${TEAM_ROLE_ID}" ]; then
  echo "PRECONDITION: no available role is named like 'Team admin'. Roles returned:" >&2
  printf '%s' "${ROLES}" | jq -r '.[] | "  \(.role_id)  \(.name)"' >&2
  echo "  Set HTH_DROPBOX_TEAM_ADMIN_ROLE_ID to the Team admin role_id and re-run." >&2
  exit 2
fi

# Page through every member (list_v2, then list/continue_v2 while has_more).
route="team/members/list_v2"; body='{"limit": 1000, "include_removed": false}'; pages=0
while :; do
  rpc_strict "${route}" "${body}"
  printf '%s' "${RPC_BODY}" | jq -c '.members[]?' >> "${MEMBERS_FILE}"
  more=$(printf '%s' "${RPC_BODY}" | jq -r '.has_more // false')
  cursor=$(printf '%s' "${RPC_BODY}" | jq -r '.cursor // ""')
  pages=$((pages + 1))
  [ "${more}" = "true" ] || break
  # TRAP 5: a member list that stops early counts admins over part of the team.
  [ -n "${cursor}" ] || { echo "PRECONDITION: ${route} answered has_more=true with no cursor after ${pages} page(s) - the member list cannot be read to the end, so no result is claimed" >&2; exit 2; }
  [ "${pages}" -lt 500 ] || { echo "PRECONDITION: ${route} stopped after 500 pages with has_more still true - the member list was not read to the end, so no result is claimed" >&2; exit 2; }
  route="team/members/list/continue_v2"
  body=$(jq -nc --arg c "${cursor}" '{cursor: $c}')
done

total=$(jq -s 'length' "${MEMBERS_FILE}")
[ "${total}" -gt 0 ] || { echo "PRECONDITION: team/members/list_v2 returned no members - nothing was audited" >&2; exit 2; }
echo "members read: ${total}"
echo "holders per role:"
jq -rs --argjson roles "${ROLES}" '
  . as $m | $roles[]
  | . as $r
  | "  \($r.name): \([ $m[] | select(any((.roles // [])[]; .role_id == $r.role_id)) ] | length)"
' "${MEMBERS_FILE}"

admins=$(jq -s --arg id "${TEAM_ROLE_ID}" \
  '[ .[] | select(any((.roles // [])[]; .role_id == $id)) ] | length' "${MEMBERS_FILE}")
with_role=$(jq -s '[ .[] | select((.roles // []) | length > 0) ] | length' "${MEMBERS_FILE}")
echo "members with a non-empty roles list: ${with_role}"

# TRAP 4: every team has at least one Team admin. Zero role holders, or zero
# Team admins, means the roles were not returned or the pinned id is wrong.
if [ "${with_role}" -eq 0 ]; then
  echo "PRECONDITION: no member carries a roles list (the field is optional in team/members/list_v2) - admin roles were not returned, so no admin count is claimed" >&2
  exit 2
fi
if [ "${admins}" -eq 0 ]; then
  echo "PRECONDITION: no member holds the Team admin role ${TEAM_ROLE_ID}, and every team has at least one - check HTH_DROPBOX_TEAM_ADMIN_ROLE_ID against the roles listed above; no admin count is claimed" >&2
  exit 2
fi

rc=0
if [ "${admins}" -gt "${MAX_ADMINS}" ]; then
  echo "FINDING: ${admins} members hold the Team admin role (limit ${MAX_ADMINS}). Move each to the narrowest role that covers their duties:"
  jq -rs --arg id "${TEAM_ROLE_ID}" \
    '.[] | select(any((.roles // [])[]; .role_id == $id)) | "  \(.profile.team_member_id)  status=\(.profile.status[".tag"] // "?")"' "${MEMBERS_FILE}"
  rc=1
elif [ "${admins}" -le 1 ]; then
  echo "NOTE: ${admins} Team admin(s). One admin is a continuity risk; keep a second, protected Team admin."
fi
[ "${rc}" -eq 0 ] && echo "COMPLIANT: ${admins} Team admin(s), within the limit of ${MAX_ADMINS}."
exit "${rc}"
# HTH Guide Excerpt: end admin-role-audit
