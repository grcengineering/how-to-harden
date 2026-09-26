#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: lovable-5.3
#   guide:   https://howtoharden.com/guides/lovable/#53-make-security-scans-a-publish-gate
#   profile: L1
#   mode:    read-only
#   requires: LOV_PUBLIC_API_KEY(Lovable API key, "Read only" preset: Workspace Read + Projects Read), LOVABLE_WORKSPACE_ID
# =============================================================================
# HTH Lovable Control 5.3: Make Security Scans a Publish Gate
# Profile Level: L1 (Crawl) | Plan: Business or Enterprise (the public API is Business+)
# Frameworks: NIST 800-53 RA-5/SA-11 | CIS Controls v8 16.12, 7.5
# Interface: Lovable REST API v1 (GA 2026-09-11)
#   List projects:               https://docs.lovable.dev/api-reference/projects/list-projects
#   List security scans:         https://docs.lovable.dev/api-reference/security-governance/list-security-scans
#   List security scan findings: https://docs.lovable.dev/api-reference/security-governance/list-security-scan-findings
# Dependencies: curl, jq
#
# The fleet-level proof that the publish gate held: for every PUBLISHED project, take
# the newest scan with status `completed` (scans are listed newest first) and page
# through ALL of its findings. A finding at `level` "error" (the API's highest
# severity) whose `status` is "open" or "suppressed" is a finding — "suppressed means
# every deep-scan check the finding cites is turned off for the project: hidden, not
# resolved". A published project with no completed scan cannot be shown clean and is
# reported UNKNOWN. The workspace toggle "Block publishing with critical issues" is
# not exposed by the API — set it in the console.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition, unknown, or unreadable response
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

# HTH Guide Excerpt: begin audit-published-app-scans
PUBLISHED="$(lov_list "/v1/projects?workspace_id=${WS_ID_ENC}&is_published=true&limit=100" \
  | jq -s '[.[] | select(.is_published == true)]')" || exit 2

FINDINGS=0; UNKNOWN=0
while IFS=$'\t' read -r PID PNAME; do
  [ -n "${PID}" ] || continue
  PID_ENC="$(printf '%s' "${PID}" | jq -sRr @uri)"
  # Newest completed scan (the list is newest first; a running/failed scan is skipped).
  SCAN="$(lov_list "/v1/projects/${PID_ENC}/security-scans?limit=100" \
    | jq -s -c '[.[] | select(.status == "completed")][0] // empty')" || exit 2
  if [ -z "${SCAN}" ]; then
    echo "UNKNOWN 5.3: ${PNAME} (${PID}) is published with no completed security scan"; UNKNOWN=$((UNKNOWN + 1))
    continue
  fi
  SID="$(printf '%s' "${SCAN}" | jq -r '.id')"
  SID_ENC="$(printf '%s' "${SID}" | jq -sRr @uri)"
  ERRORS="$(lov_list "/v1/projects/${PID_ENC}/security-scans/${SID_ENC}/findings?limit=100" \
    | jq -s '[.[] | select(.level == "error" and (.status == "open" or .status == "suppressed"))] | length')" || exit 2
  if [ "${ERRORS}" -gt 0 ]; then
    echo "FAIL 5.3: ${PNAME} (${PID}) is published with ${ERRORS} unresolved error-level finding(s) (scan ${SID}, finished $(printf '%s' "${SCAN}" | jq -r '.finished_at // "?"'))"
    FINDINGS=$((FINDINGS + 1))
  fi
done < <(printf '%s' "${PUBLISHED}" | jq -r '.[] | [.id, (.name // "(unnamed)")] | @tsv')

TOTAL="$(printf '%s' "${PUBLISHED}" | jq 'length')"
if [ "${FINDINGS}" -gt 0 ]; then exit 1; fi
if [ "${UNKNOWN}" -gt 0 ]; then echo "ERROR 5.3: ${UNKNOWN} of ${TOTAL} published project(s) could not be shown clean" >&2; exit 2; fi
echo "PASS 5.3: all ${TOTAL} published project(s) have a completed scan with no unresolved error-level findings"
exit 0
# HTH Guide Excerpt: end audit-published-app-scans
