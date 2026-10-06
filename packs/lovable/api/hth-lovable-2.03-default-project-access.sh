#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: lovable-2.3
#   guide:   https://howtoharden.com/guides/lovable/#23-default-projects-to-restricted-govern-external-collaborators
#   profile: L2
#   mode:    read-only
#   requires: LOV_PUBLIC_API_KEY(Lovable API key, "Read only" preset: Workspace Read), LOVABLE_WORKSPACE_ID
# =============================================================================
# HTH Lovable Control 2.3: Default Projects to Restricted; Govern External Collaborators
# Profile Level: L2 (Walk) | Plan: Business or Enterprise (Restricted and the public API)
# Frameworks: NIST 800-53 AC-3/AC-6 | CIS Controls v8 3.3, 6.8
# Interface: Lovable REST API v1 (GA 2026-09-11)
#   Get workspace: https://docs.lovable.dev/api-reference/workspaces/get-workspace
#   List projects: https://docs.lovable.dev/api-reference/projects/list-projects
# Dependencies: curl, jq
#
# `default_project_visibility` is one of restricted | workspace_edit | workspace_view,
# or null when no default is configured. Per the reference, `restricted` requires
# Business or Enterprise, "otherwise new projects fall back to workspace_edit".
# Changing the default never changes existing projects, so the pack also counts the
# existing projects that are still open to the whole workspace (informational).
# The External project collaborators setting is NOT in the API — ClickOps only.
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

# HTH Guide Excerpt: begin audit-default-project-access
WS="$(lov_get "/v1/workspaces/${WS_ID_ENC}")" || exit 2
printf '%s' "${WS}" | jq -e 'has("default_project_visibility")' >/dev/null || {
  echo "ERROR 2.3: workspace response lacks default_project_visibility — state UNKNOWN" >&2; exit 2; }
DEFAULT_VIS="$(printf '%s' "${WS}" | jq -r '.default_project_visibility // "null (no default configured)"')"

# Existing projects the whole workspace can open. Filter server-side AND client-side:
# the API ignores unknown query parameters, so never trust the filter alone.
OPEN_PROJECTS="$(lov_list "/v1/projects?workspace_id=${WS_ID_ENC}&visibility=workspace_edit&visibility=workspace_view&limit=100" \
  | jq -s '[.[] | select(.visibility == "workspace_edit" or .visibility == "workspace_view")]')" || exit 2
echo "INFO 2.3: $(printf '%s' "${OPEN_PROJECTS}" | jq 'length') existing project(s) are open to every workspace member (the default does not change them)"

if [ "${DEFAULT_VIS}" = "restricted" ]; then
  echo "PASS 2.3: new projects default to Restricted"
  exit 0
fi
echo "FAIL 2.3: default project access is '${DEFAULT_VIS}' — set Settings -> Security -> Privacy & security -> Default project access -> Restricted"
exit 1
# HTH Guide Excerpt: end audit-default-project-access
