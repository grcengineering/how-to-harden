#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: lovable-2.4
#   guide:   https://howtoharden.com/guides/lovable/#24-control-who-can-publish-and-who-can-view-published-apps
#   profile: L2
#   mode:    read-only
#   requires: LOV_PUBLIC_API_KEY(Lovable API key, "Read only" preset: Workspace Read), LOVABLE_WORKSPACE_ID, HTH_PUBLIC_ALLOWLIST(optional, comma-separated project IDs approved to be public)
# =============================================================================
# HTH Lovable Control 2.4: Control Who Can Publish and Who Can View Published Apps
# Profile Level: L2 (Walk) | Plan: Business or Enterprise (non-public audiences and the public API)
# Frameworks: NIST 800-53 CM-5/AC-3 | CIS Controls v8 3.3, 4.2
# Interface: Lovable REST API v1 (GA 2026-09-11)
#   Get workspace: https://docs.lovable.dev/api-reference/workspaces/get-workspace
#   List projects: https://docs.lovable.dev/api-reference/projects/list-projects
# Dependencies: curl, jq
#
# Two reads. (1) The workspace `publishing_policy` (org_only | workspace_only |
# disabled, or null when no audience restriction is configured). (2) Every published
# project whose `publish_audience` is `public`, i.e. reachable by anyone with the URL.
# The list filter `publish_audience` is "resolved the same way the response resolves
# it, including the workspace default". Each public app must be either unpublished,
# narrowed, or listed in HTH_PUBLIC_ALLOWLIST as a deliberate exception.
#
# The write side exists but is deliberately NOT in this pack: PATCH
# /v1/projects/{project_id}/publish {"audience": "workspace"} (scope projects:write).
# "Who can publish externally" is not exposed by the API — ClickOps only.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition or unreadable response
# =============================================================================
set -euo pipefail

# Explicit guards (exit 2): a bare ${VAR:?} exits 1, which would read as a finding.
[ -n "${LOV_PUBLIC_API_KEY:-}" ]   || { echo "PRECONDITION: set LOV_PUBLIC_API_KEY — a Lovable API key (Settings -> Access tokens, Read only preset)" >&2; exit 2; }
[ -n "${LOVABLE_WORKSPACE_ID:-}" ] || { echo "PRECONDITION: set LOVABLE_WORKSPACE_ID — the workspace the key belongs to" >&2; exit 2; }
LOV_API_BASE="${LOV_API_BASE:-https://api.lovable.dev}"
LOV_VERSION="2026-09-11"
HTH_PUBLIC_ALLOWLIST="${HTH_PUBLIC_ALLOWLIST:-}"

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

# HTH Guide Excerpt: begin audit-publishing-policy
WS="$(lov_get "/v1/workspaces/${WS_ID_ENC}")" || exit 2
printf '%s' "${WS}" | jq -e 'has("publishing_policy")' >/dev/null || {
  echo "ERROR 2.4: workspace response lacks publishing_policy — state UNKNOWN" >&2; exit 2; }
POLICY="$(printf '%s' "${WS}" | jq -r '.publishing_policy // "null"')"
if [ "${POLICY}" = "null" ]; then
  echo "REVIEW 2.4: no workspace publishing audience restriction is configured"
else
  echo "INFO 2.4: workspace publishing_policy = ${POLICY}"
fi
# HTH Guide Excerpt: end audit-publishing-policy

# HTH Guide Excerpt: begin audit-public-apps
# Published apps reachable by anyone with the URL. Server-side filter plus a
# client-side re-check (unknown query parameters are ignored, never rejected).
PUBLIC_APPS="$(lov_list "/v1/projects?workspace_id=${WS_ID_ENC}&is_published=true&publish_audience=public&limit=100" \
  | jq -s '[.[] | select(.is_published == true and .publish_audience == "public")]')" || exit 2

RC=0
while IFS=$'\t' read -r PID PNAME; do
  [ -n "${PID}" ] || continue
  case ",${HTH_PUBLIC_ALLOWLIST}," in
    *",${PID},"*) echo "ACCEPTED 2.4: ${PNAME} (${PID}) is public by documented exception" ;;
    *)            echo "FAIL 2.4: ${PNAME} (${PID}) is published to the public internet"; RC=1 ;;
  esac
done < <(printf '%s' "${PUBLIC_APPS}" | jq -r '.[] | [.id, (.name // "(unnamed)")] | @tsv')

[ "${RC}" -eq 0 ] && echo "PASS 2.4: no un-excepted public apps ($(printf '%s' "${PUBLIC_APPS}" | jq 'length') public in total)"
exit "${RC}"
# HTH Guide Excerpt: end audit-public-apps
