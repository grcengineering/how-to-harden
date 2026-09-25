#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: dropbox-2.1
#   guide:   https://howtoharden.com/guides/dropbox/#21-restrict-external-sharing
#   profile: L1
#   mode:    read-only
#   requires: DROPBOX_TEAM_TOKEN(team-scoped access token with team_info.read), HTH_DROPBOX_MAX_LINK_EXPIRY_DAYS(optional, default 30)
# =============================================================================
# HTH Dropbox Control 2.1: Restrict External Sharing
# Profile Level: L1 (Crawl)
# Frameworks: NIST 800-53 AC-21
# Source: https://howtoharden.com/guides/dropbox/#21-restrict-external-sharing
# Dependencies: curl, jq
# Token: a token generated in the Dropbox App Console carries more than the
#   requires: line above lists. The console would not save team scopes without
#   team_data.member, and ticking team_data.member locks team_data.governance.read
#   and team_data.governance.write on (observed 2026-09-25). This pack calls read
#   routes only, but the token it runs with can write: store and rotate it as a
#   write-capable credential.
#
# WHY THIS IS A READ-ONLY api/ PACK AND THERE IS NO WRITE PACK.
# Every setting in 2.1 is readable through team/get_info (policies.sharing),
# and none of them is writable: the Dropbox Business API has no endpoint that
# sets a team sharing policy (census of the 103 business endpoints in
# https://docs.dropboxapi.com/dropbox-api/llms.txt, 2026-09-24). The only
# sharing write surface is the approved-people list (team/sharing_allowlist/
# add|remove), which this pack reads but never changes. So the console sets
# the policy and this pack proves it.
#
# Mapping, console label -> API field. Labels are the ones the live Admin
# console shows (Products > Dropbox > Settings > External sharing, read
# 2026-09-25); help.dropbox.com/share/manage-team-sharing names several of them
# differently (e.g. "Default access for shared links", "Blanket link
# restrictions"). Fields: docs.dropboxapi.com .../team/get-info.
#   Who can be added to files and folders ...... shared_folder_member_policy
#   Who can access links by default ............ shared_link_create_policy
#   Sharing links to files and folders ......... shared_link_create_policy (TRAP 1)
#   What permissions recipients have
#     by default ............................... shared_link_default_permissions_policy
#   Expiration for links ....................... default_link_expiration_days_policy
#   Passwords for links ........................ enforce_link_password_policy
#   Universal link restriction for folders ..... shared_folder_link_restriction_policy
#   Approved list (Members + approved people) .. team/sharing_allowlist/list
#
# TRAP 1: "Sharing links to files and folders" has no field of its own. The API
#   reference describes shared_link_create_policy=team_only as "Only members of
#   the same team can access all shared links" (no per-link override), which
#   matches the console's Off, and the default_* values as defaults members can
#   override, which matches On. That mapping comes from the documentation and
#   has not been observed on a live team, so the pack prints it as info only.
# TRAP 2: expiration and passwords only apply when default access is not
#   Anyone (the console hides both settings while it is Anyone). A team on default_public passes the password check on paper and
#   gets no protection from it, so this pack reports that combination.
# TRAP 3: every union is open. An unrecognised .tag is not assumed safe; it is
#   reported as a finding so a new, weaker value cannot pass silently.
# TRAP 4: the approved list is read to the end or not at all. has_more with no
#   cursor, or 500 pages with has_more still true, exits 2.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition (auth, scope, transport)
# =============================================================================

set -euo pipefail

[ -n "${DROPBOX_TEAM_TOKEN:-}" ] || { echo "PRECONDITION: set DROPBOX_TEAM_TOKEN to a team-scoped access token with team_info.read" >&2; exit 2; }
MAX_DAYS="${HTH_DROPBOX_MAX_LINK_EXPIRY_DAYS:-30}"
DROPBOX_API_BASE="${DROPBOX_API_BASE:-https://api.dropboxapi.com/2}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }
case "${MAX_DAYS}" in ''|*[!0-9]*) echo "PRECONDITION: HTH_DROPBOX_MAX_LINK_EXPIRY_DAYS must be a whole number of days" >&2; exit 2 ;; esac

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-dropbox.XXXXXX")" || { echo "PRECONDITION: mktemp failed" >&2; exit 2; }
trap 'rm -f "${BODY_FILE}"' EXIT
RPC_CODE=""; RPC_BODY=""

# Every Dropbox RPC route is an HTTP POST with a JSON body, including routes
# that take no argument: the official Python SDK serialises a Void argument as
# JSON `null` with Content-Type application/json (dropbox_client.py,
# stone_serializers.py). curl implies POST when --data is given, so no -X flag
# appears. The bearer token is passed to curl on stdin (-K -), never in argv,
# so it does not show up in the process table.
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

# Anything but 200 is a precondition, never a finding: a policy cannot be
# judged on evidence that was never returned.
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

# HTH Guide Excerpt: begin sharing-policy-audit
rpc_strict "team/get_info" 'null'
SHARING=$(printf '%s' "${RPC_BODY}" | jq -c '.policies.sharing // empty')
[ -n "${SHARING}" ] || { echo "PRECONDITION: team/get_info returned no policies.sharing object" >&2; exit 2; }

tag() { printf '%s' "${SHARING}" | jq -r --arg f "$1" '.[$f][".tag"] // "(absent)"'; }
member_policy=$(tag shared_folder_member_policy)
link_create=$(tag shared_link_create_policy)
link_perms=$(tag shared_link_default_permissions_policy)
expiry=$(tag default_link_expiration_days_policy)
password=$(tag enforce_link_password_policy)
blanket=$(tag shared_folder_link_restriction_policy)
join_policy=$(tag shared_folder_join_policy)

rc=0
finding() { echo "FINDING: $*"; rc=1; }

case "${member_policy}" in
  team|team_and_approved) echo "ok  Who can be added to files and folders: ${member_policy}" ;;
  *) finding "Who can be added to files and folders = ${member_policy} (want team or team_and_approved)" ;;
esac
case "${link_create}" in
  team_only|default_team_only|default_no_one) echo "ok  Who can access links by default: ${link_create}" ;;
  *) finding "Who can access links by default = ${link_create} (want team_only, default_team_only or default_no_one)" ;;
esac
# TRAP 1: the documented reading of the same field for the on/off toggle.
case "${link_create}" in
  team_only) echo "info Sharing links to files and folders: reads as Off (team_only: every shared link is team-only, no per-link override)" ;;
  default_*) echo "info Sharing links to files and folders: reads as On (${link_create} is a default that members can override per link)" ;;
  *)         echo "info Sharing links to files and folders: not determinable from shared_link_create_policy = ${link_create}" ;;
esac
case "${link_perms}" in
  view) echo "ok  What permissions recipients have by default: view" ;;
  *) finding "What permissions recipients have by default = ${link_perms} (want view)" ;;
esac
case "${expiry}" in
  day_1) days=1 ;; day_3) days=3 ;; day_7) days=7 ;; day_30) days=30 ;;
  day_90) days=90 ;; day_180) days=180 ;; year_1) days=365 ;; *) days="" ;;
esac
if [ -n "${days}" ] && [ "${days}" -le "${MAX_DAYS}" ]; then
  echo "ok  Expiration for links: ${expiry} (limit ${MAX_DAYS} days)"
else
  finding "Expiration for links = ${expiry} (want ${MAX_DAYS} days or less)"
fi
case "${password}" in
  required) echo "ok  Passwords for links: required" ;;
  *) finding "Passwords for links = ${password} (want required)" ;;
esac
case "${blanket}" in
  members) echo "ok  Universal link restriction for folders: members" ;;
  *) finding "Universal link restriction for folders = ${blanket} (want members)" ;;
esac
# TRAP 2: password and expiry are inert while default access is Anyone.
if [ "${link_create}" = "default_public" ]; then
  echo "NOTE: default access is Anyone, so the expiration and password settings above do not apply to new links."
fi
echo "info Shared folders members may join: ${join_policy} (from_team_only keeps members out of outside folders)"

# Approved list: counted, never printed - entries are other organisations' domains and addresses.
domains=0; emails=0; body='{"limit": 1000}'; route="team/sharing_allowlist/list"; pages=0
while :; do
  rpc_strict "${route}" "${body}"
  domains=$(( domains + $(printf '%s' "${RPC_BODY}" | jq '(.domains // []) | length') ))
  emails=$(( emails + $(printf '%s' "${RPC_BODY}" | jq '(.emails // []) | length') ))
  more=$(printf '%s' "${RPC_BODY}" | jq -r '.has_more // false')
  cursor=$(printf '%s' "${RPC_BODY}" | jq -r '.cursor // ""')
  pages=$((pages + 1))
  [ "${more}" = "true" ] || break
  # TRAP 4: a partly read approved list would under-count who can be added.
  [ -n "${cursor}" ] || { echo "PRECONDITION: ${route} answered has_more=true with no cursor after ${pages} page(s) - the approved list cannot be read to the end, so no result is claimed" >&2; exit 2; }
  [ "${pages}" -lt 500 ] || { echo "PRECONDITION: ${route} stopped after 500 pages with has_more still true - the approved list was not read to the end, so no result is claimed" >&2; exit 2; }
  route="team/sharing_allowlist/list/continue"
  body=$(jq -nc --arg c "${cursor}" '{cursor: $c}')
done
echo "info Approved list: ${domains} domain(s), ${emails} address(es)"
if [ "${member_policy}" = "team_and_approved" ] && [ $((domains + emails)) -eq 0 ]; then
  echo "NOTE: members + approved people is set, but the approved list is empty."
fi

[ "${rc}" -eq 0 ] && echo "COMPLIANT: every readable 2.1 sharing policy meets the guide."
exit "${rc}"
# HTH Guide Excerpt: end sharing-policy-audit
