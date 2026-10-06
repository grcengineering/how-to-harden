#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: asana-2.1
#   guide:   https://howtoharden.com/guides/asana/#21-configure-admin-roles
#   profile: L1
#   mode:    read-only
#   requires: ASANA_PAT(personal access token of an Admin or Super Admin; GET /roles is admin-only), ASANA_WORKSPACE_GID, ASANA_MAX_ADMINS(optional, default 3), ASANA_SKIP_ROLES(optional)
# =============================================================================
# HTH Asana Control 2.1: Configure Admin Roles
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 5.4 | NIST 800-53 AC-6
# Source: https://howtoharden.com/guides/asana/#21-configure-admin-roles
# Dependencies: bash, curl (7.55+ for -H @file), jq
# API (verified against Asana's OpenAPI spec asana_oas.yaml and the Roles reference, 2026-09-24):
#   GET /workspaces/{workspace_gid}/workspace_memberships   getWorkspaceMembershipsForWorkspace
#   GET /roles?workspace={workspace_gid}                     getRoles ("Required scope: roles:read")
#   https://developers.asana.com/reference/roles
#
# ── TRAP 1: the membership record has ONE admin flag ────────────────────────
# WorkspaceMembership exposes `is_admin` ("Reflects if this user is an admin of
# the workspace") and no separate super-admin flag. The roster count is every
# admin, which is what the guide's 2-3 ceiling should be held against anyway.
# Tune the ceiling with ASANA_MAX_ADMINS.
#
# ── TRAP 2: custom roles are Enterprise+ ────────────────────────────────────
# The Roles reference: GET is available to Admins and Super Admins; creating and
# managing custom roles "requires the Enterprise+ tier". Below Enterprise+ the
# list holds only standard roles and the custom-role checks correctly find
# nothing. If GET /roles itself is refused, the pack exits 2; re-run with
# ASANA_SKIP_ROLES=1 to audit the roster alone, and the output says so.
#
# ── TRAP 3: a role that can grant roles is an admin role ────────────────────
# `permissions.manage_roles` (create, edit, delete roles) or
# `permissions.assign_roles` (assign guest, member and admin roles) on a role
# whose base_role_type is member or guest is a path to admin that never shows up
# on the admin roster. Each one is a finding. A member- or guest-based role that
# leaves either permission unreported, or a role whose base_role_type is missing
# or unknown, was not evaluated, and the pack will not report compliant while
# one exists.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition (auth, tier, network, empty scan, unevaluated role, unexpected error)
# =============================================================================

set -eEuo pipefail
trap 'echo "PRECONDITION: unexpected failure at line ${LINENO}" >&2; exit 2' ERR

# A missing input is a precondition (exit 2), never a finding (exit 1).
need() { if [ -z "${!1:-}" ]; then echo "PRECONDITION: set $1 — $2" >&2; exit 2; fi; }
need ASANA_PAT "personal access token of an Asana Admin or Super Admin"
need ASANA_WORKSPACE_GID "the workspace gid of the organization"
ASANA_API_BASE="${ASANA_API_BASE:-https://app.asana.com/api/1.0}"
MAX_ADMINS="${ASANA_MAX_ADMINS:-3}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }
case "${MAX_ADMINS}" in ''|*[!0-9]*) echo "PRECONDITION: ASANA_MAX_ADMINS must be a whole number" >&2; exit 2 ;; esac

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-asana-201.XXXXXX")"
ITEMS_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-asana-201i.XXXXXX")"
trap 'rm -f "${BODY_FILE}" "${ITEMS_FILE}"' EXIT
FINDINGS=0; UNEVALUATED=0

# One GET. Fails closed: anything but HTTP 200 with a JSON object body exits 2,
# so an auth, tier or network failure can never read as "0 findings". The token
# reaches curl through a process-substitution header file, never argv.
asana_get() {
  local code rc=0
  code=$(curl -sS --max-time 60 -o "${BODY_FILE}" -w '%{http_code}' \
    -H @<(printf 'Authorization: Bearer %s\n' "${ASANA_PAT}") \
    -H 'Accept: application/json' "${ASANA_API_BASE}$1" 2>/dev/null) || rc=$?
  if [ "${rc}" -ne 0 ]; then
    echo "PRECONDITION: GET ${1%%\?*} got no HTTP response (curl exit ${rc})" >&2; exit 2
  fi
  if [ "${code}" != "200" ]; then
    echo "PRECONDITION: GET ${1%%\?*} returned HTTP ${code}: $(jq -r '[.errors[]?.message] | join("; ")' "${BODY_FILE}" 2>/dev/null || true)" >&2
    case "${code}" in
      401) echo "  The token is invalid, expired or revoked." >&2 ;;
      402) echo "  The organization's tier does not include this endpoint." >&2 ;;
      403) echo "  The token's user lacks the permission this endpoint requires (Admin or Super Admin)." >&2 ;;
    esac
    exit 2
  fi
  if ! jq -e 'type == "object"' "${BODY_FILE}" >/dev/null 2>&1; then
    echo "PRECONDITION: GET ${1%%\?*} returned a non-JSON body" >&2; exit 2
  fi
}

# Follows next_page.offset to exhaustion, writing every .data[] item to
# ITEMS_FILE one JSON object per line. The API caps limit at 100.
asana_paginate() {  # asana_paginate <path> <query>
  local path="$1" query="$2" offset="" pages=0
  : > "${ITEMS_FILE}"
  while :; do
    if [ -n "${offset}" ]; then asana_get "${path}?${query}&offset=${offset}"; else asana_get "${path}?${query}"; fi
    if ! jq -e '.data | type == "array"' "${BODY_FILE}" >/dev/null 2>&1; then
      echo "PRECONDITION: ${path} response carries no data array" >&2; exit 2
    fi
    jq -c '.data[]' "${BODY_FILE}" >> "${ITEMS_FILE}"
    offset=$(jq -r '.next_page.offset // "" | @uri' "${BODY_FILE}")
    pages=$((pages + 1))
    [ -n "${offset}" ] || break
    if [ "${pages}" -ge 1000 ]; then echo "PRECONDITION: ${path} pagination exceeded 1000 pages" >&2; exit 2; fi
  done
}

# HTH Guide Excerpt: begin admin-roster-audit
audit_admins() {
  asana_paginate "/workspaces/${ASANA_WORKSPACE_GID}/workspace_memberships" \
                 "opt_fields=user.name,is_active,is_admin,is_guest&limit=100"
  local scanned count
  scanned=$(jq -s 'length' "${ITEMS_FILE}")
  if [ "${scanned}" -eq 0 ]; then
    echo "PRECONDITION: the workspace returned zero memberships; nothing was audited" >&2; exit 2
  fi
  count=$(jq -s '[.[] | select(.is_active == true and .is_admin == true)] | length' "${ITEMS_FILE}")
  echo "Asana 2.1 — admin roster"
  echo "  memberships scanned: ${scanned}"
  echo "  active admins (is_admin, TRAP 1): ${count} (ceiling ${MAX_ADMINS})"
  jq -r 'select(.is_active == true and .is_admin == true)
         | "    - \(.user.name // "(no name)") …\((.user.gid // "") | .[-6:])"' "${ITEMS_FILE}"
  if [ "${count}" -gt "${MAX_ADMINS}" ]; then
    echo "FINDING: ${count} active admins exceeds the ceiling of ${MAX_ADMINS}."
    FINDINGS=$((FINDINGS + 1))
  fi
}
# HTH Guide Excerpt: end admin-roster-audit

# HTH Guide Excerpt: begin role-escalation-audit
audit_roles() {
  asana_paginate "/roles" \
    "workspace=${ASANA_WORKSPACE_GID}&opt_fields=name,is_standard_role,base_role_type,permissions.manage_roles,permissions.assign_roles&limit=100"
  local scanned escalating
  scanned=$(jq -s 'length' "${ITEMS_FILE}")
  if [ "${scanned}" -eq 0 ]; then
    echo "PRECONDITION: GET /roles returned zero roles; RBAC was not evaluated." >&2
    echo "  Re-run with ASANA_SKIP_ROLES=1 to audit the admin roster alone." >&2
    exit 2
  fi
  echo "  roles scanned: ${scanned} (custom: $(jq -s '[.[] | select(.is_standard_role == false)] | length' "${ITEMS_FILE}"))"
  jq -r 'select(.is_standard_role == false and ((.base_role_type // "") | test("admin")))
         | "    review: custom role \"\(.name)\" is built on base_role_type=\(.base_role_type)"' "${ITEMS_FILE}"
  # TRAP 3. A member- or guest-based role that can create or assign roles.
  escalating=$(jq -s '[.[] | select(((.base_role_type // "") == "member" or (.base_role_type // "") == "guest")
                                    and ((.permissions.manage_roles // false) or (.permissions.assign_roles // false)))] | length' "${ITEMS_FILE}")
  if [ "${escalating}" -gt 0 ]; then
    jq -r 'select(((.base_role_type // "") == "member" or (.base_role_type // "") == "guest")
                  and ((.permissions.manage_roles // false) or (.permissions.assign_roles // false)))
           | "FINDING: role \"\(.name)\" (base \(.base_role_type)) has manage_roles=\(.permissions.manage_roles | if . == null then "unreported" else tostring end) assign_roles=\(.permissions.assign_roles | if . == null then "unreported" else tostring end), a path to admin outside the roster."' "${ITEMS_FILE}"
    FINDINGS=$((FINDINGS + escalating))
  fi
  # Roles that could not be judged: unknown base type, or either value unreported.
  local unjudged='def known: (.base_role_type // "") as $b | ["guest", "member", "admin", "super_admin"] | any(. == $b);
                  def judged: .base_role_type == "member" or .base_role_type == "guest";
                  select((known | not) or (judged and (.permissions.manage_roles == null or .permissions.assign_roles == null)))'
  jq -r "${unjudged}"' | "INCONCLUSIVE: role \"\(.name)\" (base \(.base_role_type // "unreported")) was not evaluated: manage_roles or assign_roles is unreported, or the base type is unknown."' "${ITEMS_FILE}"
  UNEVALUATED=$(jq -s "[.[] | ${unjudged}] | length" "${ITEMS_FILE}")
}
# HTH Guide Excerpt: end role-escalation-audit

audit_admins
if [ "${ASANA_SKIP_ROLES:-}" = "1" ]; then
  echo "  roles: SKIPPED (ASANA_SKIP_ROLES=1) — RBAC escalation paths were NOT evaluated"
else
  audit_roles
fi
if [ "${FINDINGS}" -gt 0 ]; then
  exit 1
fi
if [ "${UNEVALUATED}" -gt 0 ]; then
  echo "PRECONDITION: ${UNEVALUATED} role(s) could not be evaluated, so the pack does not report compliant (TRAP 3)" >&2
  exit 2
fi
if [ "${ASANA_SKIP_ROLES:-}" = "1" ]; then
  echo "COMPLIANT (roster only): active admins within the ceiling."
else
  echo "COMPLIANT: active admins within the ceiling; no member- or guest-based role can create or assign roles."
fi
exit 0
