#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: miro-2.1
#   guide:   https://howtoharden.com/guides/miro/#21-configure-sharing-defaults
#   profile: L1
#   mode:    read-only
#   requires: MIRO_ACCESS_TOKEN(OAuth access token issued by a Company Admin; scope organizations:teams:read only), MIRO_ORG_ID(optional), MIRO_TEAM_ID(optional)
# =============================================================================
# HTH Miro Control 2.1: Configure Sharing Defaults
# Profile Level: L1 (Crawl)
# Frameworks: NIST 800-53 AC-21
# Source: https://howtoharden.com/guides/miro/#21-configure-sharing-defaults
# Dependencies: curl, jq
#
# WHAT THIS PROVES. Reads every team's sharing policy and fails when a team
# allows sharing via public link or has no allowed-domain restriction.
# Endpoints, all GET (Enterprise plan, Company Admin, organizations:teams:read):
#   GET /v2/orgs/{org_id}/teams                      enterprise-get-teams
#   GET /v2/orgs/{org_id}/teams/{team_id}/settings   enterprise-get-team-settings
#     -> teamSharingPolicySettings.{sharingViaPublicLink, restrictAllowedDomains,
#        allowListedDomains, sharingOnOrganization, defaultBoardAccess}
# The org id comes from GET /v1/oauth-token unless MIRO_ORG_ID is set.
# Changing these values is PATCH .../settings (enterprise-update-team-settings);
# that call is deliberately not in this pack.
#
# ── TRAP 1: the Company-level toggle is not in the API ───────────────────────
# "Company settings > Security > Sharing > Boards can be shared publicly" has no
# documented endpoint. Miro documents that when it is off, "teams can't share
# boards publicly even if it's allowed on Team level". A team reading
# sharingViaPublicLink=allowed is therefore still reported: it is the value
# that takes effect the moment someone turns the Company toggle back on, and
# the API cannot see whether that toggle is off. Confirm it in the console.
#
# ── TRAP 2: new teams default to public-link sharing ─────────────────────────
# "Sharing via a public link is turned on by default on Team level and set to
# 'Anyone can view and comment' for newly created teams." Every team is read,
# not a sample, because the newest team is the likeliest to be open.
#
# ── TRAP 3: "enabled_with_external_user_access" is a deliberate bypass ───────
# It restricts to the allowlist "but allows external users to access". It is
# reported as REVIEW (a documented business choice), not as compliant silence.
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

# HTH Guide Excerpt: begin sharing-policy-audit
# Per team: public-link sharing must be not_allowed, and sharing must be held to
# an allowlist of domains. A missing field is unreadable, never compliant.
audit_team() {
  local tid="$1" pol pub dom ndom org issues="" review=""
  api_get "/v2/orgs/{org_id}/teams/{team_id}/settings" "/v2/orgs/${ORG_ID}/teams/${tid}/settings"
  pol=$(printf '%s' "${BODY}" | jq -c '.teamSharingPolicySettings // empty')
  [ -n "${pol}" ] || precondition "team settings carry no teamSharingPolicySettings object"
  pub=$(printf '%s' "${pol}" | jq -r '.sharingViaPublicLink // "unknown"')
  dom=$(printf '%s' "${pol}" | jq -r '.restrictAllowedDomains // "unknown"')
  ndom=$(printf '%s' "${pol}" | jq -r '(.allowListedDomains // []) | length')
  org=$(printf '%s' "${pol}" | jq -r '.sharingOnOrganization // "unknown"')

  case "${pub}" in
    not_allowed) ;;
    allowed)              issues="${issues} public-link-sharing-allowed" ;;
    allowed_with_editing) issues="${issues} public-link-EDITING-allowed" ;;
    *)                    issues="${issues} sharingViaPublicLink-unreadable(${pub})" ;;
  esac
  case "${dom}" in
    enabled)                           [ "${ndom}" -gt 0 ] || issues="${issues} domain-restriction-with-empty-allowlist" ;;
    enabled_with_external_user_access) [ "${ndom}" -gt 0 ] || issues="${issues} domain-restriction-with-empty-allowlist"
                                       review="${review} external-users-bypass-allowlist" ;;
    disabled)                          issues="${issues} no-domain-restriction" ;;
    *)                                 issues="${issues} restrictAllowedDomains-unreadable(${dom})" ;;
  esac

  printf '  team …%s  sharingViaPublicLink=%s restrictAllowedDomains=%s allowListedDomains=%s sharingOnOrganization=%s  %s%s\n' \
    "${tid: -6}" "${pub}" "${dom}" "${ndom}" "${org}" \
    "$([ -z "${issues}" ] && echo OK || echo "FINDING:${issues}")" \
    "$([ -z "${review}" ] || echo "  REVIEW:${review}")"
  [ -z "${issues}" ] || FINDINGS=$((FINDINGS + 1))
}
# HTH Guide Excerpt: end sharing-policy-audit

FINDINGS=0
resolve_org
list_teams
echo "Miro 2.1 — team sharing policy (Company-level public-sharing toggle is console-only: confirm it separately)"
while IFS= read -r tid; do
  [ -n "${tid}" ] || continue
  audit_team "${tid}"
done < "${TEAMS_FILE}"

echo "  teams with findings: ${FINDINGS}"
[ "${FINDINGS}" -eq 0 ] || exit 1
exit 0
