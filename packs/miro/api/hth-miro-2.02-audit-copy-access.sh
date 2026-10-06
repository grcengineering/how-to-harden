#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: miro-2.2
#   guide:   https://howtoharden.com/guides/miro/#22-board-copying-and-export-controls
#   profile: L2
#   mode:    read-only
#   requires: MIRO_ACCESS_TOKEN(OAuth access token issued by a Company Admin; scope organizations:teams:read only), MIRO_ORG_ID(optional), MIRO_TEAM_ID(optional)
# =============================================================================
# HTH Miro Control 2.2: Board Copying and Export Controls
# Profile Level: L2 (Walk)
# Frameworks: NIST 800-53 AC-21
# Source: https://howtoharden.com/guides/miro/#22-board-copying-and-export-controls
# Dependencies: curl, jq
#
# WHAT THIS PROVES. Reads each team's copy-access settings — the API side of
# the console's Content Security > Copying Content control — and fails when
# anyone with board access can copy on new boards, or when people outside the
# team can be given copy permission at all. Endpoints, all GET (Enterprise
# plan, Company Admin, organizations:teams:read):
#   GET /v2/orgs/{org_id}/teams                      enterprise-get-teams
#   GET /v2/orgs/{org_id}/teams/{team_id}/settings   enterprise-get-team-settings
#     -> teamCopyAccessLevelSettings.{copyAccessLevel, copyAccessLevelLimitation}
#
# ── TRAP 1: the setting exists from Starter, the API only on Enterprise ──────
# The console control is available on Starter and above; the settings endpoint
# is Enterprise-only. On Starter/Business this pack stops with exit 2 and the
# control must be checked in the console.
#
# ── TRAP 2: the reference's own enum has a typo ──────────────────────────────
# The GET schema lists copyAccessLevel value "board_owner            -"; the
# update schema lists "board_owner". Both are matched as board-owner-only.
#
# ── TRAP 3: copyAccessLevel is the DEFAULT for new boards ────────────────────
# "…can copy board content on newly created boards." It says nothing about
# boards that already exist. copyAccessLevelLimitation is the ceiling on what a
# board owner may grant ("Only team members can be given permission to copy
# board content"), so both are read and both must be tight.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition
# =============================================================================

set -euo pipefail

: "${MIRO_ACCESS_TOKEN:?set MIRO_ACCESS_TOKEN — a Miro OAuth access token issued by a Company Admin with organizations:teams:read}"
MIRO_API_BASE="${MIRO_API_BASE:-https://api.miro.com}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-miro.XXXXXX")"
TEAMS_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-miro.XXXXXX")"
trap 'rm -f "${BODY_FILE}" "${TEAMS_FILE}"' EXIT
HTTP_CODE=""; BODY=""; ORG_ID=""

precondition() { echo "PRECONDITION: $*" >&2; exit 2; }

# GET only — no -X flag anywhere, so check 14 sees a read-only file.
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

# HTH Guide Excerpt: begin copy-access-audit
# Per team: the default copy level for new boards must not be "anyone", and the
# ceiling must keep copy permission inside the team.
audit_team() {
  local tid="$1" lvl lim issues=""
  api_get "/v2/orgs/{org_id}/teams/{team_id}/settings" "/v2/orgs/${ORG_ID}/teams/${tid}/settings"
  lvl=$(printf '%s' "${BODY}" | jq -r '.teamCopyAccessLevelSettings.copyAccessLevel // "unknown"')
  lim=$(printf '%s' "${BODY}" | jq -r '.teamCopyAccessLevelSettings.copyAccessLevelLimitation // "unknown"')

  case "${lvl}" in
    team_members|team_editors|board_owner*) ;;
    anyone) issues="${issues} anyone-with-board-access-can-copy-new-boards" ;;
    *)      issues="${issues} copyAccessLevel-unreadable(${lvl})" ;;
  esac
  case "${lim}" in
    team_members) ;;
    anyone) issues="${issues} non-team-users-can-be-granted-copy" ;;
    *)      issues="${issues} copyAccessLevelLimitation-unreadable(${lim})" ;;
  esac

  printf '  team …%s  copyAccessLevel=%s copyAccessLevelLimitation=%s  %s\n' \
    "${tid: -6}" "${lvl}" "${lim}" \
    "$([ -z "${issues}" ] && echo OK || echo "FINDING:${issues}")"
  [ -z "${issues}" ] || FINDINGS=$((FINDINGS + 1))
}
# HTH Guide Excerpt: end copy-access-audit

FINDINGS=0
resolve_org
list_teams
echo "Miro 2.2 — team copy-access settings"
while IFS= read -r tid; do
  [ -n "${tid}" ] || continue
  audit_team "${tid}"
done < "${TEAMS_FILE}"

echo "  teams with findings: ${FINDINGS}"
[ "${FINDINGS}" -eq 0 ] || exit 1
exit 0
