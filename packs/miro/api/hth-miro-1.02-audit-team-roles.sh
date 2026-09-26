#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: miro-1.2
#   guide:   https://howtoharden.com/guides/miro/#12-team-access-controls
#   profile: L1
#   mode:    read-only
#   requires: MIRO_ACCESS_TOKEN(OAuth access token issued by a Company Admin; scope organizations:teams:read only), MIRO_ORG_ID(optional), MIRO_TEAM_ID(optional)
# =============================================================================
# HTH Miro Control 1.2: Team Access Controls
# Profile Level: L1 (Crawl)
# Frameworks: NIST 800-53 AC-3, AC-6
# Source: https://howtoharden.com/guides/miro/#12-team-access-controls
# Dependencies: curl, jq
#
# WHAT THIS PROVES. For every team in the organization (or one team, with
# MIRO_TEAM_ID) it counts team members by role and reads the team's invitation
# policy, then fails when a team has more admins than MIRO_MAX_TEAM_ADMINS or
# lets every member invite people. Endpoints, all GET, all documented in the
# Miro REST API reference (Enterprise plan, Company Admin, scope
# organizations:teams:read):
#   GET /v2/orgs/{org_id}/teams                      enterprise-get-teams
#   GET /v2/orgs/{org_id}/teams/{team_id}/members    enterprise-get-team-members
#   GET /v2/orgs/{org_id}/teams/{team_id}/settings   enterprise-get-team-settings
# The org id comes from GET /v1/oauth-token (get-access-token-context) unless
# MIRO_ORG_ID is set.
#
# WHY api/ AND NOT terraform/ OR cli/. Miro publishes no Terraform provider and
# no first-party CLI (docs/research/cli-inventory.md row "Miro | None"). Team
# roles and invitation policy can only be read through the Enterprise REST API.
#
# ── TRAP 1: Enterprise APIs answer 403/404 to anyone who is not a Company Admin
# The reference states "You can only use this endpoint if you have the role of
# a Company Admin." A Team Admin's token gets "Invalid access". That is a
# precondition (exit 2), never "no findings".
#
# ── TRAP 2: role "non_team" is how guests and external users appear ──────────
# The documented roles are member, admin and non_team ("External user,
# non-team user"). This pack counts them separately; it never prints member
# ids, emails or names.
#
# ── TRAP 3: an empty listing is not a clean result ───────────────────────────
# Zero teams, or zero members across every team, means the audit saw nothing.
# Both exit 2 so a scheduler can never read silence as compliance.
#
# Tunable: MIRO_MAX_TEAM_ADMINS (default 3).
# Exit codes: 0 compliant | 1 finding | 2 precondition
# =============================================================================

set -euo pipefail

: "${MIRO_ACCESS_TOKEN:?set MIRO_ACCESS_TOKEN — a Miro OAuth access token issued by a Company Admin with organizations:teams:read}"
MIRO_API_BASE="${MIRO_API_BASE:-https://api.miro.com}"
MIRO_MAX_TEAM_ADMINS="${MIRO_MAX_TEAM_ADMINS:-3}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }
case "${MIRO_MAX_TEAM_ADMINS}" in ''|*[!0-9]*) echo "PRECONDITION: MIRO_MAX_TEAM_ADMINS must be a whole number" >&2; exit 2 ;; esac

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-miro.XXXXXX")"
TEAMS_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-miro.XXXXXX")"
ROLES_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-miro.XXXXXX")"
trap 'rm -f "${BODY_FILE}" "${TEAMS_FILE}" "${ROLES_FILE}"' EXIT
HTTP_CODE=""; BODY=""; ORG_ID=""

precondition() { echo "PRECONDITION: $*" >&2; exit 2; }

# GET only. There is no -X flag anywhere in this file: curl's default verb is
# GET, which keeps the pack honestly read-only under validate-packs.sh check 14.
# $1 is a label for messages (never the real path, which carries tenant ids).
api_get() {
  local label="$1" path="$2" rc code msg
  set +e
  HTTP_CODE=$(curl -sS -o "${BODY_FILE}" -w '%{http_code}' \
    -H "Authorization: Bearer ${MIRO_ACCESS_TOKEN}" \
    -H "Accept: application/json" \
    "${MIRO_API_BASE}${path}" 2>/dev/null)
  rc=$?
  set -e
  [ "${rc}" -eq 0 ] || HTTP_CODE="000"
  BODY=$(cat "${BODY_FILE}" 2>/dev/null || true)
  if [ "${HTTP_CODE}" = "200" ]; then
    printf '%s' "${BODY}" | jq -e . >/dev/null 2>&1 || precondition "GET ${label} returned 200 with a body that is not JSON"
    return 0
  fi
  code=$(printf '%s' "${BODY}" | jq -r '.code // "unknown"' 2>/dev/null || echo unknown)
  msg=$(printf '%s' "${BODY}" | jq -r '.message // "no message"' 2>/dev/null || echo "no message")
  case "${HTTP_CODE}" in
    000)     precondition "GET ${label} — no HTTP response (network, DNS, or TLS failure)" ;;
    401)     precondition "GET ${label} returned 401 (${code}) — the token is invalid or expired" ;;
    403|404) precondition "GET ${label} returned ${HTTP_CODE} (${code}) — needs an Enterprise org, a Company Admin token, and scope organizations:teams:read. ${msg}" ;;
    429)     precondition "GET ${label} returned 429 — rate limited; re-run later" ;;
    *)       precondition "GET ${label} returned HTTP ${HTTP_CODE} (${code}) — ${msg}" ;;
  esac
}

resolve_org() {
  if [ -n "${MIRO_ORG_ID:-}" ]; then ORG_ID="${MIRO_ORG_ID}"; return 0; fi
  api_get "/v1/oauth-token" "/v1/oauth-token"
  ORG_ID=$(printf '%s' "${BODY}" | jq -r '.organization.id // "" | tostring')
  [ -n "${ORG_ID}" ] || precondition "the token context carries no organization id — set MIRO_ORG_ID"
}

# One team id per line into TEAMS_FILE. Follows the documented cursor to the end
# and refuses a partial listing rather than auditing half an organization.
list_teams() {
  local cursor="" prev="" pages=0 q
  : > "${TEAMS_FILE}"
  if [ -n "${MIRO_TEAM_ID:-}" ]; then printf '%s\n' "${MIRO_TEAM_ID}" > "${TEAMS_FILE}"; return 0; fi
  while :; do
    q="limit=100"
    [ -z "${cursor}" ] || q="${q}&cursor=$(jq -rn --arg c "${cursor}" '$c|@uri')"
    api_get "/v2/orgs/{org_id}/teams" "/v2/orgs/${ORG_ID}/teams?${q}"
    printf '%s' "${BODY}" | jq -e '.data | type == "array"' >/dev/null 2>&1 || precondition "team listing has no data array"
    printf '%s' "${BODY}" | jq -r '.data[] | (.id // empty) | tostring' >> "${TEAMS_FILE}"
    prev="${cursor}"
    cursor=$(printf '%s' "${BODY}" | jq -r '.cursor // ""')
    pages=$((pages + 1))
    [ -n "${cursor}" ] || break
    [ "${cursor}" != "${prev}" ] || precondition "team listing repeated its cursor — refusing a partial result"
    [ "${pages}" -lt 500 ] || precondition "team listing exceeded 500 pages — refusing a partial result"
  done
  [ -s "${TEAMS_FILE}" ] || precondition "the organization returned zero teams — nothing was audited"
}

# count_roles <var> <grep options>: the number of collected roles that match,
# stored in <var>. grep -c exits 0 (some match), 1 (none) or 2 (error); only 0
# and 1 are counts. An error is a precondition, never a count of zero.
count_roles() {
  local var="$1" n rc=0
  shift
  n=$(grep -c "$@" "${ROLES_FILE}") || rc=$?
  [ "${rc}" -le 1 ] || precondition "could not count the member roles collected for a team (grep exit ${rc}) — nothing was audited"
  printf -v "${var}" '%s' "${n}"
}

# HTH Guide Excerpt: begin team-roles-audit
# Per team: role counts from the members listing (paginated), plus who may
# invite and whether non-team collaborators are allowed, from team settings.
audit_team() {
  local tid="$1" cursor="" prev="" pages=0 q admins members guests unknown who ext issues=""
  : > "${ROLES_FILE}"
  while :; do
    q="limit=100"
    [ -z "${cursor}" ] || q="${q}&cursor=$(jq -rn --arg c "${cursor}" '$c|@uri')"
    api_get "/v2/orgs/{org_id}/teams/{team_id}/members" "/v2/orgs/${ORG_ID}/teams/${tid}/members?${q}"
    printf '%s' "${BODY}" | jq -e '.data | type == "array"' >/dev/null 2>&1 || precondition "member listing has no data array"
    printf '%s' "${BODY}" | jq -r '.data[] | (.role // "unknown")' >> "${ROLES_FILE}"
    prev="${cursor}"
    cursor=$(printf '%s' "${BODY}" | jq -r '.cursor // ""')
    pages=$((pages + 1))
    [ -n "${cursor}" ] || break
    [ "${cursor}" != "${prev}" ] || precondition "member listing repeated its cursor — refusing a partial result"
    [ "${pages}" -lt 1000 ] || precondition "member listing exceeded 1000 pages — refusing a partial result"
  done
  count_roles admins  -x 'admin'
  count_roles members -x 'member'
  count_roles guests  -x 'non_team'
  count_roles unknown -vxE 'admin|member|non_team'
  TOTAL_SEEN=$((TOTAL_SEEN + admins + members + guests + unknown))

  api_get "/v2/orgs/{org_id}/teams/{team_id}/settings" "/v2/orgs/${ORG_ID}/teams/${tid}/settings"
  who=$(printf '%s' "${BODY}" | jq -r '.teamInvitationSettings.whoCanInvite // "unknown"')
  ext=$(printf '%s' "${BODY}" | jq -r '.teamInvitationSettings.inviteExternalUsers // "unknown"')

  [ "${admins}" -le "${MIRO_MAX_TEAM_ADMINS}" ] || issues="${issues} admins>${MIRO_MAX_TEAM_ADMINS}"
  case "${who}" in
    only_org_admins|admins) ;;
    all_members) issues="${issues} every-member-can-invite" ;;
    *)           issues="${issues} whoCanInvite-unreadable(${who})" ;;
  esac
  [ "${unknown}" -eq 0 ] || issues="${issues} ${unknown}-unrecognised-roles"

  printf '  team …%s  admins=%s members=%s non_team=%s whoCanInvite=%s inviteExternalUsers=%s  %s\n' \
    "${tid: -6}" "${admins}" "${members}" "${guests}" "${who}" "${ext}" \
    "$([ -z "${issues}" ] && echo OK || echo "FINDING:${issues}")"
  [ -z "${issues}" ] || FINDINGS=$((FINDINGS + 1))
}
# HTH Guide Excerpt: end team-roles-audit

FINDINGS=0; TOTAL_SEEN=0
resolve_org
list_teams
echo "Miro 1.2 — team roles and invitation policy (max admins per team: ${MIRO_MAX_TEAM_ADMINS})"
while IFS= read -r tid; do
  [ -n "${tid}" ] || continue
  audit_team "${tid}"
done < "${TEAMS_FILE}"

[ "${TOTAL_SEEN}" -gt 0 ] || precondition "every team returned zero members — the token cannot see membership, so nothing was audited"
echo "  teams with findings: ${FINDINGS}"
[ "${FINDINGS}" -eq 0 ] || exit 1
exit 0
