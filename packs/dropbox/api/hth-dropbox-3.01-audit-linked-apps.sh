#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: dropbox-3.1
#   guide:   https://howtoharden.com/guides/dropbox/#31-manage-connected-apps
#   profile: L1
#   mode:    read-only
#   requires: DROPBOX_TEAM_TOKEN(team-scoped access token with sessions.list), HTH_DROPBOX_APPROVED_APP_IDS(optional, comma-separated app_id allowlist)
# =============================================================================
# HTH Dropbox Control 3.1: Manage Connected Apps
# Profile Level: L1 (Crawl)
# Frameworks: NIST 800-53 CM-7
# Source: https://howtoharden.com/guides/dropbox/#31-manage-connected-apps
# Dependencies: curl, jq
# Token: a token generated in the Dropbox App Console carries more than the
#   requires: line above lists. The console would not save team scopes without
#   team_data.member, and ticking team_data.member locks team_data.governance.read
#   and team_data.governance.write on (observed 2026-09-25). This pack calls read
#   routes only, but the token it runs with can write: store and rotate it as a
#   write-capable credential.
#
# WHAT THIS READS. team/linked_apps/list_members_linked_apps (sessions.list)
# returns, per member, every third-party app linked to that member's account:
# app_id, app_name, publisher, is_app_folder and the time it was linked. The
# pack folds that into one row per app - how many members linked it and when
# the oldest link was made - and judges each app against your approved list.
#
# WHAT IT CANNOT SEE. The block/allow policy under Settings -> Integrations
# ("Connecting registered integrations", per-app Block/Allow, Add exception)
# has no API: nothing sets it and nothing reads it (census of the 103 business
# endpoints, 2026-09-24; changes surface afterwards as team_log
# integration_policy_changed and app_blocked_by_permissions events). Dropbox
# also documents that blocking an app does not disconnect members already
# linked to it - which is exactly the residue this pack finds.
#
# WHY THERE IS NO WRITE BRANCH. team/linked_apps/revoke_linked_app(_batch)
# (sessions.modify) disconnects an app from a member. Revocation belongs to a
# person reviewing this output, one app at a time, not to an audit run.
#
# TRAP 1: "this endpoint does not list any team-linked applications" - apps
#   linked at team level (like the one running this audit) are not in scope.
# TRAP 2: pagination is on the SAME route with the cursor in the body.
# TRAP 3: with no approved list, nothing has been reviewed, so every linked app
#   is reported UNREVIEWED and the run exits 1. Member entries read with zero
#   apps across a fully paginated team is the only clean result without a list.
# TRAP 4: the list is read to the end or not at all. has_more with no cursor,
#   or 500 pages with has_more still true, exits 2.
# TRAP 5: `apps` is "the linked applications of each member of the team", and
#   the docs do not say whether a member with no linked app gets an entry. A
#   fully paginated list with zero member entries therefore exits 2 rather than
#   report a clean team: it looks the same as a read that saw no members.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition (auth, scope, transport)
# =============================================================================

set -euo pipefail

[ -n "${DROPBOX_TEAM_TOKEN:-}" ] || { echo "PRECONDITION: set DROPBOX_TEAM_TOKEN to a team-scoped access token with sessions.list" >&2; exit 2; }
APPROVED="${HTH_DROPBOX_APPROVED_APP_IDS:-}"
DROPBOX_API_BASE="${DROPBOX_API_BASE:-https://api.dropboxapi.com/2}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-dropbox.XXXXXX")" || { echo "PRECONDITION: mktemp failed" >&2; exit 2; }
APPS_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-dropbox-apps.XXXXXX")" || { rm -f "${BODY_FILE}"; echo "PRECONDITION: mktemp failed" >&2; exit 2; }
trap 'rm -f "${BODY_FILE}" "${APPS_FILE}"' EXIT
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

# HTH Guide Excerpt: begin linked-apps-audit
body='{}'; pages=0
while :; do
  rpc_strict "team/linked_apps/list_members_linked_apps" "${body}"
  printf '%s' "${RPC_BODY}" | jq -c '.apps[]?' >> "${APPS_FILE}"
  more=$(printf '%s' "${RPC_BODY}" | jq -r '.has_more // false')
  cursor=$(printf '%s' "${RPC_BODY}" | jq -r '.cursor // ""')
  pages=$((pages + 1))
  [ "${more}" = "true" ] || break
  # TRAP 4: a partly read list would pass on the apps it never saw.
  [ -n "${cursor}" ] || { echo "PRECONDITION: team/linked_apps/list_members_linked_apps answered has_more=true with no cursor after ${pages} page(s) - the list cannot be read to the end, so no result is claimed" >&2; exit 2; }
  [ "${pages}" -lt 500 ] || { echo "PRECONDITION: team/linked_apps/list_members_linked_apps stopped after 500 pages with has_more still true - the list was not read to the end, so no result is claimed" >&2; exit 2; }
  body=$(jq -nc --arg c "${cursor}" '{cursor: $c}')
done

# TRAP 5: zero member entries cannot be told apart from a read that saw nobody.
entries=$(jq -s 'length' "${APPS_FILE}")
if [ "${entries}" -eq 0 ]; then
  echo "PRECONDITION: team/linked_apps/list_members_linked_apps returned no member entries across ${pages} page(s). Dropbox does not document whether a member with no linked app is listed, so this cannot be told apart from a read that saw no members - check Settings -> Integrations in the Admin console; no result is claimed" >&2
  exit 2
fi

# One row per app_id: name, publisher, members linked, oldest link.
REPORT=$(jq -s --arg approved "${APPROVED}" '
  ($approved | split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0))) as $ok
  | [ .[] | .team_member_id as $m | (.linked_api_apps // [])[] | . + {member: $m} ]
  | group_by(.app_id)
  | map({ app_id: .[0].app_id, app_name: .[0].app_name,
          publisher: (.[0].publisher // "(unknown)"),
          members: ([ .[].member ] | unique | length),
          oldest: ([ .[].linked | select(. != null) ] | sort | first // "(unknown)"),
          approved: (.[0].app_id as $id | any($ok[]; . == $id)) })
  | sort_by(-.members)' "${APPS_FILE}")

apps=$(printf '%s' "${REPORT}" | jq 'length')
echo "member entries read: ${entries} | distinct linked apps: ${apps}"
printf '%s' "${REPORT}" | jq -r '.[] |
  "  \(if .approved then "approved  " else "UNREVIEWED" end)  \(.app_id)  \(.app_name)  publisher=\(.publisher)  members=\(.members)  oldest=\(.oldest)"'

unreviewed=$(printf '%s' "${REPORT}" | jq '[ .[] | select(.approved | not) ] | length')
if [ "${unreviewed}" -gt 0 ]; then
  if [ -z "${APPROVED}" ]; then
    echo "FINDING: ${unreviewed} linked app(s) and no approved list (HTH_DROPBOX_APPROVED_APP_IDS) - none of them has been reviewed."
  else
    echo "FINDING: ${unreviewed} linked app(s) are not on the approved list. Revoke each in Dropbox; blocking alone does not disconnect members already linked."
  fi
  exit 1
fi
if [ "${apps}" -eq 0 ]; then
  echo "COMPLIANT: ${entries} member entries read across the fully paginated list, and none has a third-party app linked."
else
  echo "COMPLIANT: all ${apps} linked app(s) are on the approved list."
fi
exit 0
# HTH Guide Excerpt: end linked-apps-audit
