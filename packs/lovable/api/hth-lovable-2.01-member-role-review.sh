#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: lovable-2.1
#   guide:   https://howtoharden.com/guides/lovable/#21-right-size-roles-and-member-lifecycle
#   profile: L1
#   mode:    read-only
#   requires: LOV_PUBLIC_API_KEY(Lovable API key, "Read only" preset: Workspace Read), LOVABLE_WORKSPACE_ID, HTH_MAX_OWNERS(optional, default 2), HTH_MAX_ADMINS(optional, default 5)
# =============================================================================
# HTH Lovable Control 2.1: Right-size Roles and Member Lifecycle
# Profile Level: L1 (Crawl) | Plan: Business or Enterprise (the public API is Business+)
# Frameworks: NIST 800-53 AC-6/AC-2 | CIS Controls v8 5.4, 6.1
# Interface: Lovable REST API v1 (GA 2026-09-11)
#   List workspace members: https://docs.lovable.dev/api-reference/members-access/list-workspace-members
#   Get workspace:          https://docs.lovable.dev/api-reference/workspaces/get-workspace
# Dependencies: curl, jq
#
# Privileged-member review. The member object carries only user_id, type and name,
# with NO role field, so the pack asks once per role using the documented repeatable
# `role` filter (owner | admin | member | viewer | collaborator) and follows cursor
# pagination to the end. HTH_MAX_OWNERS / HTH_MAX_ADMINS are your policy ceilings;
# the defaults are a starting point, not a Lovable limit.
#
# Not covered by this pack: pending invitations (the endpoint returns ACCEPTED members
# only) and group-based project grants — review both at Settings -> People and
# Settings -> Access -> Groups.
#
# Exit codes: 0 within policy | 1 finding | 2 precondition or unreadable response
# =============================================================================
set -euo pipefail

# Explicit guards (exit 2): a bare ${VAR:?} exits 1, which would read as a finding.
[ -n "${LOV_PUBLIC_API_KEY:-}" ]   || { echo "PRECONDITION: set LOV_PUBLIC_API_KEY — a Lovable API key (Settings -> Access tokens, Read only preset)" >&2; exit 2; }
[ -n "${LOVABLE_WORKSPACE_ID:-}" ] || { echo "PRECONDITION: set LOVABLE_WORKSPACE_ID — the workspace the key belongs to" >&2; exit 2; }
LOV_API_BASE="${LOV_API_BASE:-https://api.lovable.dev}"
LOV_VERSION="2026-09-11"
HTH_MAX_OWNERS="${HTH_MAX_OWNERS:-2}"
HTH_MAX_ADMINS="${HTH_MAX_ADMINS:-5}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }
case "${HTH_MAX_OWNERS}${HTH_MAX_ADMINS}" in *[!0-9]*) echo "PRECONDITION: HTH_MAX_OWNERS/HTH_MAX_ADMINS must be integers" >&2; exit 2 ;; esac

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

# Follow cursor pagination to the end. Prints every item as one compact JSON line.
# A page without a `data` array or a boolean `pagination.has_more`, or has_more=true
# without a next_cursor, is an error — never a short list.
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

# HTH Guide Excerpt: begin audit-privileged-members
# Owners and admins, one role at a time (the member object has no role field).
OWNERS="$(lov_list "/v1/workspaces/${WS_ID_ENC}/members?role=owner&limit=100" | jq -s '.')" || exit 2
ADMINS="$(lov_list "/v1/workspaces/${WS_ID_ENC}/members?role=admin&limit=100" | jq -s '.')" || exit 2
N_OWNERS="$(printf '%s' "${OWNERS}" | jq 'length')"
N_ADMINS="$(printf '%s' "${ADMINS}" | jq 'length')"

echo "Owners (${N_OWNERS}, policy max ${HTH_MAX_OWNERS}):"
printf '%s' "${OWNERS}" | jq -r '.[] | "  \(.name // "(no display name)")  \(.user_id)"'
echo "Admins (${N_ADMINS}, policy max ${HTH_MAX_ADMINS}):"
printf '%s' "${ADMINS}" | jq -r '.[] | "  \(.name // "(no display name)")  \(.user_id)"'

RC=0
if [ "${N_OWNERS}" -lt 1 ]; then
  echo "ERROR 2.1: the owner query returned zero owners; a workspace always has one — result UNKNOWN" >&2
  exit 2
fi
if [ "${N_OWNERS}" -gt "${HTH_MAX_OWNERS}" ]; then
  echo "FAIL 2.1: ${N_OWNERS} owners exceed the policy maximum of ${HTH_MAX_OWNERS}"; RC=1
fi
if [ "${N_ADMINS}" -gt "${HTH_MAX_ADMINS}" ]; then
  echo "FAIL 2.1: ${N_ADMINS} admins exceed the policy maximum of ${HTH_MAX_ADMINS}"; RC=1
fi
# HTH Guide Excerpt: end audit-privileged-members

# HTH Guide Excerpt: begin audit-credit-limit
# Resource-abuse cap: the default monthly build-credit limit for members without their
# own limit. The API returns null both when it is unset and when the key cannot view
# workspace usage, so null is reported for review rather than failed.
WS="$(lov_get "/v1/workspaces/${WS_ID_ENC}")" || exit 2
printf '%s' "${WS}" | jq -e 'has("default_monthly_member_credit_limit")' >/dev/null || {
  echo "ERROR 2.1: workspace response lacks default_monthly_member_credit_limit" >&2; exit 2; }
LIMIT="$(printf '%s' "${WS}" | jq -r '.default_monthly_member_credit_limit // "null"')"
if [ "${LIMIT}" = "null" ]; then
  echo "REVIEW 2.1: no default member credit limit visible (unset, or the key cannot view usage) — review it in the workspace settings"
else
  echo "INFO 2.1: default monthly member credit limit = ${LIMIT} credits"
fi

[ "${RC}" -eq 0 ] && echo "PASS 2.1: privileged membership within policy (pending invites not covered — review Settings -> People)"
exit "${RC}"
# HTH Guide Excerpt: end audit-credit-limit
