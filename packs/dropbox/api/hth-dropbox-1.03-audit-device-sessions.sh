#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: dropbox-1.3
#   guide:   https://howtoharden.com/guides/dropbox/#13-enforce-device-approvals-and-session-limits
#   profile: L2
#   mode:    read-only
#   requires: DROPBOX_TEAM_TOKEN(team-scoped access token with sessions.list), HTH_DROPBOX_MAX_DESKTOP(optional, default 2), HTH_DROPBOX_MAX_MOBILE(optional, default 2), HTH_DROPBOX_MAX_WEB_SESSION_DAYS(optional, default 30)
# =============================================================================
# HTH Dropbox Control 1.3: Enforce Device Approvals and Session Limits
# Profile Level: L2 (Walk)
# Frameworks: NIST 800-53 AC-11, AC-12, AC-19, IA-3
# Source: https://howtoharden.com/guides/dropbox/#13-enforce-device-approvals-and-session-limits
# Dependencies: curl, jq
# Token: a token generated in the Dropbox App Console carries more than the
#   requires: line above lists. The console would not save team scopes without
#   team_data.member, and ticking team_data.member locks team_data.governance.read
#   and team_data.governance.write on (observed 2026-09-25). This pack calls read
#   routes only, but the token it runs with can write: store and rotate it as a
#   write-capable credential.
#
# WHAT THIS PROVES, AND WHAT IT CANNOT. The device-approval policy, the device
# caps, the over-limit action and the web-session lengths have no API: nothing
# sets them and nothing reads their current value (census of the 103 business
# endpoints, 2026-09-24; changes only surface afterwards as team_log
# device_approvals_change_* and web_sessions_change_* events). What the API
# does expose is the OUTCOME - every linked desktop client, mobile client and
# web session, via team/devices/list_members_devices (sessions.list). This pack
# measures that outcome against the caps you configured in the console:
#   - members with more desktop or mobile clients than the cap
#   - web sessions created longer ago than your fixed-session window
#   - desktop clients that cannot be remote-wiped (is_delete_on_unlink_supported = false)
#
# WHY THERE IS NO WRITE BRANCH. team/devices/revoke_device_session (sessions.modify)
# signs a session out and, for a desktop client with delete_on_unlink, deletes
# that member's files from the device on its next connection. That is Remote
# wipe - an incident action taken per device, not something an audit should do.
#
# TRAP 1: pagination is on the SAME route. list_members_devices returns
#   has_more + cursor, and the next page is another list_members_devices call
#   with that cursor (there is no /continue route for this one).
# TRAP 2: caps are counted per member across both platforms separately,
#   matching the console, where computer and mobile limits are set apart.
# TRAP 3: the list is read to the end or not at all. has_more with no cursor,
#   or 500 pages with has_more still true, exits 2 instead of judging part of it.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition (auth, scope, transport)
# =============================================================================

set -euo pipefail

[ -n "${DROPBOX_TEAM_TOKEN:-}" ] || { echo "PRECONDITION: set DROPBOX_TEAM_TOKEN to a team-scoped access token with sessions.list" >&2; exit 2; }
MAX_DESKTOP="${HTH_DROPBOX_MAX_DESKTOP:-2}"
MAX_MOBILE="${HTH_DROPBOX_MAX_MOBILE:-2}"
MAX_WEB_DAYS="${HTH_DROPBOX_MAX_WEB_SESSION_DAYS:-30}"
DROPBOX_API_BASE="${DROPBOX_API_BASE:-https://api.dropboxapi.com/2}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }
for v in "${MAX_DESKTOP}" "${MAX_MOBILE}" "${MAX_WEB_DAYS}"; do
  case "${v}" in ''|*[!0-9]*) echo "PRECONDITION: device caps and HTH_DROPBOX_MAX_WEB_SESSION_DAYS must be whole numbers" >&2; exit 2 ;; esac
done

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-dropbox.XXXXXX")" || { echo "PRECONDITION: mktemp failed" >&2; exit 2; }
DEV_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-dropbox-devices.XXXXXX")" || { rm -f "${BODY_FILE}"; echo "PRECONDITION: mktemp failed" >&2; exit 2; }
trap 'rm -f "${BODY_FILE}" "${DEV_FILE}"' EXIT
RPC_CODE=""; RPC_BODY=""

# Every Dropbox RPC route is an HTTP POST with a JSON body. curl implies POST
# when --data is given. The bearer token reaches curl on stdin (-K -), never argv.
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

# HTH Guide Excerpt: begin device-session-audit
# TRAP 1: same route, cursor in the body, until has_more is false.
body='{"include_desktop_clients": true, "include_mobile_clients": true, "include_web_sessions": true}'
pages=0
while :; do
  rpc_strict "team/devices/list_members_devices" "${body}"
  printf '%s' "${RPC_BODY}" | jq -c '.devices[]?' >> "${DEV_FILE}"
  more=$(printf '%s' "${RPC_BODY}" | jq -r '.has_more // false')
  cursor=$(printf '%s' "${RPC_BODY}" | jq -r '.cursor // ""')
  pages=$((pages + 1))
  [ "${more}" = "true" ] || break
  # TRAP 3: a device list that stops early would judge part of the team.
  [ -n "${cursor}" ] || { echo "PRECONDITION: team/devices/list_members_devices answered has_more=true with no cursor after ${pages} page(s) - the device list cannot be read to the end, so no result is claimed" >&2; exit 2; }
  [ "${pages}" -lt 500 ] || { echo "PRECONDITION: team/devices/list_members_devices stopped after 500 pages with has_more still true - the device list was not read to the end, so no result is claimed" >&2; exit 2; }
  body=$(jq -nc --arg c "${cursor}" \
    '{cursor: $c, include_desktop_clients: true, include_mobile_clients: true, include_web_sessions: true}')
done

members=$(jq -s 'length' "${DEV_FILE}")
[ "${members}" -gt 0 ] || { echo "PRECONDITION: list_members_devices returned no members - nothing was audited" >&2; exit 2; }
jq -rs '"members read: \(length) | desktop clients: \([.[] | (.desktop_clients // [])[]] | length) | mobile clients: \([.[] | (.mobile_clients // [])[]] | length) | web sessions: \([.[] | (.web_sessions // [])[]] | length)"' "${DEV_FILE}"

rc=0
over=$(jq -rs --argjson d "${MAX_DESKTOP}" --argjson m "${MAX_MOBILE}" '
  .[] | select(((.desktop_clients // []) | length) > $d or ((.mobile_clients // []) | length) > $m)
  | "  \(.team_member_id)  desktop=\((.desktop_clients // []) | length) mobile=\((.mobile_clients // []) | length)"' "${DEV_FILE}")
if [ -n "${over}" ]; then
  echo "FINDING: members above the device cap (desktop ${MAX_DESKTOP}, mobile ${MAX_MOBILE}):"
  printf '%s\n' "${over}"
  rc=1
fi

# Dropbox datetimes are ISO 8601 UTC (YYYY-MM-DDTHH:MM:SSZ), which fromdateiso8601 parses.
old_web=$(jq -s --argjson days "${MAX_WEB_DAYS}" '
  [ .[] | (.web_sessions // [])[] | select(.created != null)
    | select((now - (.created | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601)) / 86400 > $days) ] | length' "${DEV_FILE}")
if [ "${old_web}" -gt 0 ]; then
  echo "FINDING: ${old_web} web session(s) were created more than ${MAX_WEB_DAYS} days ago - longer than the fixed-session window you intend"
  rc=1
fi

no_wipe=$(jq -s '[ .[] | (.desktop_clients // [])[] | select(.is_delete_on_unlink_supported == false) ] | length' "${DEV_FILE}")
[ "${no_wipe}" -eq 0 ] || echo "NOTE: ${no_wipe} desktop client(s) cannot be remote-wiped (is_delete_on_unlink_supported = false)"

[ "${rc}" -eq 0 ] && echo "COMPLIANT: every member is within the device caps and no web session outlives ${MAX_WEB_DAYS} days."
exit "${rc}"
# HTH Guide Excerpt: end device-session-audit
