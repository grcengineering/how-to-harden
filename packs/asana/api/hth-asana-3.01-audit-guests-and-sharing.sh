#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: asana-3.1
#   guide:   https://howtoharden.com/guides/asana/#31-configure-sharing-controls
#   profile: L1
#   mode:    read-only
#   requires: ASANA_PAT(personal access token of an Admin or Super Admin; GET /roles is admin-only), ASANA_WORKSPACE_GID
# =============================================================================
# HTH Asana Control 3.1: Configure Sharing Controls
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 3.3 | NIST 800-53 AC-3
# Source: https://howtoharden.com/guides/asana/#31-configure-sharing-controls
# Dependencies: bash, curl (7.55+ for -H @file), jq
# API (verified against Asana's OpenAPI spec asana_oas.yaml and the Roles reference, 2026-09-24):
#   GET /workspaces/{workspace_gid}/workspace_memberships   is_guest, is_active
#   GET /roles?workspace={workspace_gid}                     permissions.allowed_guest_invites (all | none),
#                                                            permissions.create_read_only_link
#   GET /workspaces/{workspace_gid}/teams                    getTeamsForWorkspace ("Required scope: teams:read"),
#                                                            guest_invite_management_access_level
#   https://developers.asana.com/reference/roles
#
# ── TRAP 1: guest invites are a role permission ─────────────────────────────
# `allowed_guest_invites` "Controls what type of email users with this role are
# allowed to invite": `all` lets a holder invite any outside address as a guest.
# On a member- or guest-based role that is the org's external-sharing boundary
# set by whoever holds the role, which is what the guide's Step 2 restricts.
#
# ── TRAP 2: read-only links leave the org ───────────────────────────────────
# `create_read_only_link` lets a role holder mint a read-only link. On a member-
# or guest-based role it is reported as a finding for the same reason.
#
# ── TRAP 3: writing these is Enterprise+ ────────────────────────────────────
# The Roles reference: custom-role management "requires the Enterprise+ tier";
# "Editing guest invites in standard roles is available to both Enterprise and
# Enterprise+ tiers." This pack only reads. If no role reports either
# permission, the permission surface was not evaluated and the pack exits 2
# rather than calling that clean. The same holds role by role: a member- or
# guest-based role that leaves either permission unreported, or a role whose
# base_role_type is missing or unknown, was not evaluated, and the pack will
# not report compliant while one exists.
#
# ── TRAP 4: teams carry their own guest gate ────────────────────────────────
# Team.guest_invite_management_access_level (all_team_members |
# only_team_admins) "Controls who can accept or deny guest invites for a given
# team", read from GET /workspaces/{workspace_gid}/teams and writable per team
# with PUT /teams/{team_gid}. The list covers teams "visible to the authorized
# user", so run it as a Super Admin; a secret team the token cannot see is not
# counted. A team that does not report the level, or a list with no teams at
# all, was not evaluated either.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition (auth, tier, network, empty scan, unevaluated role or team, unexpected error)
# =============================================================================

set -eEuo pipefail
trap 'echo "PRECONDITION: unexpected failure at line ${LINENO}" >&2; exit 2' ERR

# A missing input is a precondition (exit 2), never a finding (exit 1).
need() { if [ -z "${!1:-}" ]; then echo "PRECONDITION: set $1 — $2" >&2; exit 2; fi; }
need ASANA_PAT "personal access token of an Asana Admin or Super Admin"
need ASANA_WORKSPACE_GID "the workspace gid of the organization"
ASANA_API_BASE="${ASANA_API_BASE:-https://app.asana.com/api/1.0}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-asana-301.XXXXXX")"
ITEMS_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-asana-301i.XXXXXX")"
trap 'rm -f "${BODY_FILE}" "${ITEMS_FILE}"' EXIT
FINDINGS=0; UNEVALUATED=0

# One GET. Fails closed: anything but HTTP 200 with a JSON object body exits 2.
# The token reaches curl through a process-substitution header file, never argv.
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
    exit 2
  fi
  if ! jq -e 'type == "object"' "${BODY_FILE}" >/dev/null 2>&1; then
    echo "PRECONDITION: GET ${1%%\?*} returned a non-JSON body" >&2; exit 2
  fi
}

# Follows next_page.offset to exhaustion into ITEMS_FILE, one object per line.
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

echo "Asana 3.1 — guest population and sharing permissions"

# HTH Guide Excerpt: begin guest-population
asana_paginate "/workspaces/${ASANA_WORKSPACE_GID}/workspace_memberships" \
               "opt_fields=user.name,is_active,is_guest&limit=100"
scanned=$(jq -s 'length' "${ITEMS_FILE}")
if [ "${scanned}" -eq 0 ]; then
  echo "PRECONDITION: the workspace returned zero memberships; nothing was audited" >&2; exit 2
fi
echo "  memberships scanned: ${scanned}; active guests: $(jq -s '[.[] | select(.is_active == true and .is_guest == true)] | length' "${ITEMS_FILE}")"
jq -r 'select(.is_active == true and .is_guest == true) | "    - guest \(.user.name // "(no name)") …\((.user.gid // "") | .[-6:])"' "${ITEMS_FILE}"
# HTH Guide Excerpt: end guest-population

# HTH Guide Excerpt: begin sharing-permission-audit
asana_paginate "/roles" \
  "workspace=${ASANA_WORKSPACE_GID}&opt_fields=name,is_standard_role,base_role_type,permissions.allowed_guest_invites,permissions.create_read_only_link&limit=100"
roles=$(jq -s 'length' "${ITEMS_FILE}")
reported=$(jq -s '[.[] | select(.permissions.allowed_guest_invites != null or .permissions.create_read_only_link != null)] | length' "${ITEMS_FILE}")
if [ "${roles}" -eq 0 ] || [ "${reported}" -eq 0 ]; then
  echo "PRECONDITION: GET /roles returned ${roles} role(s), none reporting guest-invite or read-only-link permissions; not evaluated (TRAP 3)" >&2
  exit 2
fi
echo "  roles scanned: ${roles}"
# TRAP 1 and TRAP 2: member- or guest-based roles that widen external sharing.
jq -r 'select(((.base_role_type // "") == "member" or (.base_role_type // "") == "guest")
              and ((.permissions.allowed_guest_invites // "") == "all" or (.permissions.create_read_only_link // false) == true))
       | "FINDING: role \"\(.name)\" (base \(.base_role_type)) allowed_guest_invites=\(.permissions.allowed_guest_invites // "unreported") create_read_only_link=\(.permissions.create_read_only_link | if . == null then "unreported" else tostring end)"' "${ITEMS_FILE}"
wide=$(jq -s '[.[] | select(((.base_role_type // "") == "member" or (.base_role_type // "") == "guest")
                             and ((.permissions.allowed_guest_invites // "") == "all" or (.permissions.create_read_only_link // false) == true))] | length' "${ITEMS_FILE}")
FINDINGS=$((FINDINGS + wide))
# TRAP 3. Roles that could not be judged: unknown base type, or either value unreported.
UNJUDGED='def known: (.base_role_type // "") as $b | ["guest", "member", "admin", "super_admin"] | any(. == $b);
          def judged: .base_role_type == "member" or .base_role_type == "guest";
          select((known | not) or (judged and (.permissions.allowed_guest_invites == null or .permissions.create_read_only_link == null)))'
jq -r "${UNJUDGED}"' | "INCONCLUSIVE: role \"\(.name)\" (base \(.base_role_type // "unreported")) was not evaluated: a sharing permission is unreported, or the base type is unknown."' "${ITEMS_FILE}"
UNEVALUATED=$((UNEVALUATED + $(jq -s "[.[] | ${UNJUDGED}] | length" "${ITEMS_FILE}")))
# HTH Guide Excerpt: end sharing-permission-audit

# HTH Guide Excerpt: begin team-guest-invite-audit
# TRAP 4. Per team, who may accept or deny guest invites.
asana_paginate "/workspaces/${ASANA_WORKSPACE_GID}/teams" \
               "opt_fields=name,visibility,guest_invite_management_access_level&limit=100"
teams=$(jq -s 'length' "${ITEMS_FILE}")
echo "  teams visible to the token: ${teams}"
jq -r 'select(.guest_invite_management_access_level == "all_team_members")
       | "FINDING: team \"\(.name)\" (\(.visibility // "unknown")) lets all_team_members accept guest invites."' "${ITEMS_FILE}"
open_teams=$(jq -s '[.[] | select(.guest_invite_management_access_level == "all_team_members")] | length' "${ITEMS_FILE}")
FINDINGS=$((FINDINGS + open_teams))
# A team that reports neither value was not evaluated; nor was an empty team list.
jq -r 'select(.guest_invite_management_access_level != "all_team_members" and .guest_invite_management_access_level != "only_team_admins")
       | "INCONCLUSIVE: team \"\(.name)\" reports guest_invite_management_access_level=\(.guest_invite_management_access_level // "unreported"); not evaluated."' "${ITEMS_FILE}"
UNEVALUATED=$((UNEVALUATED + $(jq -s '[.[] | select(.guest_invite_management_access_level != "all_team_members" and .guest_invite_management_access_level != "only_team_admins")] | length' "${ITEMS_FILE}")))
if [ "${teams}" -eq 0 ]; then
  echo "INCONCLUSIVE: no team is visible to the token; the team guest gate was not evaluated."
  UNEVALUATED=$((UNEVALUATED + 1))
fi
# HTH Guide Excerpt: end team-guest-invite-audit

if [ "${FINDINGS}" -gt 0 ]; then
  exit 1
fi
if [ "${UNEVALUATED}" -gt 0 ]; then
  echo "PRECONDITION: ${UNEVALUATED} role(s) or team check(s) could not be evaluated, so the pack does not report compliant (TRAP 3, TRAP 4)" >&2
  exit 2
fi
echo "COMPLIANT: no member- or guest-based role can invite outside addresses or create read-only links; every visible team reserves guest invites to team admins."
exit 0
