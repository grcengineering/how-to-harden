#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: lovable-4.3
#   guide:   https://howtoharden.com/guides/lovable/#43-turn-on-sensitive-data-scanning-and-chat-send-protection
#   profile: L3
#   mode:    read-only
#   requires: LOV_PUBLIC_API_KEY(Lovable API key, "Read only" preset: Workspace Read + Projects Read), LOVABLE_WORKSPACE_ID
# =============================================================================
# HTH Lovable Control 4.3: Turn On Sensitive-Data Scanning and Chat Send Protection
# Profile Level: L3 (Run) | Plan: Enterprise (sensitive data scanning and PII labels)
# Frameworks: NIST 800-53 SI-4/SC-7(10) | CIS Controls v8 3.1, 3.13
# Interface: Lovable REST API v1 (GA 2026-09-11)
#   Get workspace:               https://docs.lovable.dev/api-reference/workspaces/get-workspace
#   List projects:               https://docs.lovable.dev/api-reference/projects/list-projects
#   List personal data findings: https://docs.lovable.dev/api-reference/security-governance/list-personal-data-findings
# Dependencies: curl, jq
#
# (1) Asserts the workspace boolean `enable_pii` (PII scanning on). (2) When it is on,
# counts OPEN personal-data findings on every PUBLISHED project via
# GET /v1/projects/{project_id}/pii-labels (Enterprise; returns 404 unless detection
# is enabled). Counts only: the `quote` field "may contain unmasked personal data",
# so this pack never prints it. Chat send protection and Block publishing with PII
# are not exposed by the API — ClickOps only.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition or unreadable response
# =============================================================================
set -euo pipefail

# Explicit guards (exit 2): a bare ${VAR:?} exits 1, which would read as a finding.
[ -n "${LOV_PUBLIC_API_KEY:-}" ]   || { echo "PRECONDITION: set LOV_PUBLIC_API_KEY — a Lovable API key (Settings -> Access tokens, Read only preset)" >&2; exit 2; }
[ -n "${LOVABLE_WORKSPACE_ID:-}" ] || { echo "PRECONDITION: set LOVABLE_WORKSPACE_ID — the workspace the key belongs to" >&2; exit 2; }
LOV_API_BASE="${LOV_API_BASE:-https://api.lovable.dev}"
LOV_VERSION="2026-09-11"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

lov_get() {
  local resp code
  resp="$(curl -sS "${LOV_API_BASE}$1" \
    -H "Lovable-API-Key: ${LOV_PUBLIC_API_KEY}" \
    -H "Lovable-Version: ${LOV_VERSION}" \
    -H "Accept: application/json" \
    -w $'\n%{http_code}')" || { echo "ERROR: GET $1 failed before an HTTP status (network/TLS)" >&2; return 2; }
  code="${resp##*$'\n'}"
  resp="${resp%$'\n'*}"
  if [ "${code}" != "200" ]; then
    echo "ERROR: GET $1 -> HTTP ${code} ($(printf '%s' "${resp}" | jq -r '.type? // "no error type"' 2>/dev/null || echo "non-JSON body"))" >&2
    return 2
  fi
  printf '%s' "${resp}"
}

lov_list() {
  local path="$1" sep="?" cursor="" page pages=0 more next
  case "${path}" in *\?*) sep="&" ;; esac
  while :; do
    if [ -n "${cursor}" ]; then
      page="$(lov_get "${path}${sep}cursor=$(printf '%s' "${cursor}" | jq -sRr @uri)")" || return 2
    else
      page="$(lov_get "${path}")" || return 2
    fi
    printf '%s' "${page}" | jq -e '(.data | type) == "array" and (.pagination.has_more | type) == "boolean"' >/dev/null \
      || { echo "ERROR: GET ${path} returned no data array / pagination object" >&2; return 2; }
    printf '%s' "${page}" | jq -c '.data[]'
    more="$(printf '%s' "${page}" | jq -r '.pagination.has_more')"
    [ "${more}" = "true" ] || return 0
    next="$(printf '%s' "${page}" | jq -r '.pagination.next_cursor // empty')"
    [ -n "${next}" ] || { echo "ERROR: GET ${path} reported has_more=true without next_cursor" >&2; return 2; }
    cursor="${next}"
    pages=$((pages + 1))
    [ "${pages}" -lt 1000 ] || { echo "ERROR: GET ${path} exceeded 1000 pages" >&2; return 2; }
  done
}

WS_ID_ENC="$(printf '%s' "${LOVABLE_WORKSPACE_ID}" | jq -sRr @uri)"

# HTH Guide Excerpt: begin audit-pii-scanning
WS="$(lov_get "/v1/workspaces/${WS_ID_ENC}")" || exit 2
ENABLE_PII="$(printf '%s' "${WS}" | jq -r 'if (.enable_pii | type) == "boolean" then .enable_pii else error("enable_pii missing") end')" || {
  echo "ERROR 4.3: workspace response carries no boolean enable_pii — state UNKNOWN" >&2; exit 2; }
if [ "${ENABLE_PII}" != "true" ]; then
  echo "FAIL 4.3: sensitive data (PII) scanning is off — enable it at Settings -> Security -> Privacy & security -> Sensitive data scanning"
  exit 1
fi
echo "INFO 4.3: sensitive data (PII) scanning is on"
# HTH Guide Excerpt: end audit-pii-scanning

# HTH Guide Excerpt: begin audit-open-pii-on-published-apps
# Open PII findings on published projects. Counts only — never the `quote` field.
PUBLISHED="$(lov_list "/v1/projects?workspace_id=${WS_ID_ENC}&is_published=true&limit=100" \
  | jq -s '[.[] | select(.is_published == true)]')" || exit 2
RC=0
while IFS=$'\t' read -r PID PNAME; do
  [ -n "${PID}" ] || continue
  PID_ENC="$(printf '%s' "${PID}" | jq -sRr @uri)"
  OPEN="$(lov_list "/v1/projects/${PID_ENC}/pii-labels?limit=100" | jq -s '[.[] | select(.status == "open")] | length')" || exit 2
  if [ "${OPEN}" -gt 0 ]; then
    echo "FAIL 4.3: ${PNAME} (${PID}) is published with ${OPEN} open personal-data finding(s)"; RC=1
  fi
done < <(printf '%s' "${PUBLISHED}" | jq -r '.[] | [.id, (.name // "(unnamed)")] | @tsv')
[ "${RC}" -eq 0 ] && echo "PASS 4.3: no open personal-data findings on $(printf '%s' "${PUBLISHED}" | jq 'length') published project(s)"
exit "${RC}"
# HTH Guide Excerpt: end audit-open-pii-on-published-apps
