#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: miro-2.3
#   guide:   https://howtoharden.com/guides/miro/#23-classify-boards-and-enforce-guardrails
#   profile: L3
#   mode:    read-only
#   requires: MIRO_ACCESS_TOKEN(OAuth access token issued by a Company Admin; scopes organizations:read and organizations:teams:read only), MIRO_ORG_ID(optional), MIRO_TEAM_ID(optional)
# =============================================================================
# HTH Miro Control 2.3: Classify Boards and Enforce Guardrails
# Profile Level: L3 (Run)
# Frameworks: NIST 800-53 RA-2, AC-16, AC-21
# Source: https://howtoharden.com/guides/miro/#23-classify-boards-and-enforce-guardrails
# Dependencies: curl, jq
#
# WHAT THIS PROVES. That board classification is switched on for the
# organization and for every team, that a default label exists, and that every
# team assigns one to new boards. Endpoints, all GET (Enterprise plan, Company
# Admin):
#   GET /v2/orgs/{org_id}/data-classification-settings
#       enterprise-dataclassification-organization-settings-get  (organizations:read)
#       -> enabled, labels[].{name, default, sharingRecommendation}
#   GET /v2/orgs/{org_id}/teams                                  (organizations:teams:read)
#   GET /v2/orgs/{org_id}/teams/{team_id}/data-classification-settings
#       enterprise-dataclassification-team-settings-get          (organizations:teams:read)
#       -> enabled, defaultLabelId
#
# ── TRAP 1: a label does not enforce anything ────────────────────────────────
# Miro documents that a classification label "has no impact on the board
# sharing settings". Enforcement is Intelligent Guardrails (Enterprise Guard),
# and the REST API reference has no guardrail endpoint. This pack proves the
# labelling half only; guardrails stay a console check.
#
# ── TRAP 2: no default label means new boards are born unclassified ─────────
# Both the organization's labels[].default and each team's defaultLabelId are
# read. Either one missing is a finding.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition
# =============================================================================

set -euo pipefail

: "${MIRO_ACCESS_TOKEN:?set MIRO_ACCESS_TOKEN — a Miro OAuth access token issued by a Company Admin with organizations:read and organizations:teams:read}"
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
    403|404) precondition "GET ${label} returned ${HTTP_CODE} (${code}) — needs an Enterprise org, a Company Admin token, and scopes organizations:read + organizations:teams:read. ${msg}" ;;
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

# HTH Guide Excerpt: begin data-classification-audit
# Organization first (is classification on, is there a default label), then
# every team (is it on for the team, does the team assign a default label).
audit_org() {
  local enabled nlabels def issues=""
  api_get "/v2/orgs/{org_id}/data-classification-settings" "/v2/orgs/${ORG_ID}/data-classification-settings"
  enabled=$(printf '%s' "${BODY}" | jq -r 'if .enabled == true then "true" elif .enabled == false then "false" else "unknown" end')
  nlabels=$(printf '%s' "${BODY}" | jq -r '(.labels // []) | length')
  def=$(printf '%s' "${BODY}" | jq -r '[(.labels // [])[] | select(.default == true) | .name] | first // ""')
  [ "${enabled}" = "true" ] || issues="${issues} classification-not-enabled(${enabled})"
  [ -n "${def}" ] || issues="${issues} no-default-label"
  printf '  organization  enabled=%s labels=%s default=%s  %s\n' "${enabled}" "${nlabels}" "${def:-none}" \
    "$([ -z "${issues}" ] && echo OK || echo "FINDING:${issues}")"
  [ -z "${issues}" ] || FINDINGS=$((FINDINGS + 1))
}

audit_team() {
  local tid="$1" enabled deflabel issues=""
  api_get "/v2/orgs/{org_id}/teams/{team_id}/data-classification-settings" "/v2/orgs/${ORG_ID}/teams/${tid}/data-classification-settings"
  enabled=$(printf '%s' "${BODY}" | jq -r 'if .enabled == true then "true" elif .enabled == false then "false" else "unknown" end')
  deflabel=$(printf '%s' "${BODY}" | jq -r '.defaultLabelId // "" | tostring')
  [ "${enabled}" = "true" ] || issues="${issues} team-classification-not-enabled(${enabled})"
  [ -n "${deflabel}" ] || issues="${issues} no-default-label-for-new-boards"
  printf '  team …%s  enabled=%s defaultLabel=%s  %s\n' "${tid: -6}" "${enabled}" "$([ -n "${deflabel}" ] && echo set || echo none)" \
    "$([ -z "${issues}" ] && echo OK || echo "FINDING:${issues}")"
  [ -z "${issues}" ] || FINDINGS=$((FINDINGS + 1))
}
# HTH Guide Excerpt: end data-classification-audit

FINDINGS=0
resolve_org
echo "Miro 2.3 — board classification (Intelligent Guardrails have no API: check them in the console)"
audit_org
list_teams
while IFS= read -r tid; do
  [ -n "${tid}" ] || continue
  audit_team "${tid}"
done < "${TEAMS_FILE}"

echo "  scopes with findings: ${FINDINGS}"
[ "${FINDINGS}" -eq 0 ] || exit 1
exit 0
