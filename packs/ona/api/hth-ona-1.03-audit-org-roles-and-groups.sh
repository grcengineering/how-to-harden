#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-1.3
#   guide:   https://howtoharden.com/guides/ona/#13-apply-least-privilege-organization-roles-and-groups
#   profile: L1
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional)
# =============================================================================
# HTH Ona Control 1.3: Apply Least-Privilege Organization Roles and Groups
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 5.4, 6.8
# Source: https://howtoharden.com/guides/ona/#13-apply-least-privilege-organization-roles-and-groups
# Dependencies: curl, jq
#
# WHY THIS IS AN api/ PACK — AND WHY terraform/ CANNOT REPLACE IT.
# `gitpod-io/ona` ships `ona_group`, `ona_group_membership` and
# `ona_organization_role_assignment`, so Terraform can DECLARE the target state.
# It cannot enumerate the live one: `terraform plan` speaks only about resources
# already in state, and the whole point of an access review is the grants nobody
# codified. There is also no `ona member` CLI verb. Read-only enumeration through
# the API is the only way to see every admin and every role assignment at once.
#
# ── TRAP 1: the seven granular roles are NOT in OrganizationRole ─────────────
# `SetRole` accepts exactly ORGANIZATION_ROLE_ADMIN and ORGANIZATION_ROLE_MEMBER.
# Runners Admin, Projects Admin, Groups Admin, Automations Admin, Insights
# Viewer, Audit Log Reader and Billing Viewer are `RESOURCE_ROLE_ORG_*` values
# assigned TO A GROUP over RESOURCE_TYPE_ORGANIZATION via
# GroupService/CreateRoleAssignment. Counting only ListMembers roles therefore
# misses every delegated privilege in the organization, which is why this pack
# reads ListRoleAssignments as a first-class source rather than a footnote.
#
# ── TRAP 2: derivedFromOrgRole separates inherited from ad-hoc ───────────────
# Verbatim: "The org-level role that created this assignment, if any.
# RESOURCE_ROLE_UNSPECIFIED means this is a direct share (manually created).
# Non-zero means this assignment was derived from an org-level role." A direct
# share is the one a review has to justify by hand; an inherited one is already
# explained by the member's org role. The two are printed separately.
#
# ── TRAP 3: systemManaged and directShare groups are not user-made ───────────
# `Group.systemManaged` marks groups the platform creates itself, and
# `directShare` marks the hidden pseudo-groups used to share a resource with one
# user. Both show up in ListGroups. Treating them as "someone created 40 groups"
# reads the organization wrong, so they are counted separately.
#
# ── TRAP 4: member email is PII and is never printed ─────────────────────────
# `OrganizationMember` carries `email` and `fullName`. This pack prints counts
# only. `--show-admins` prints the first 8 characters of each admin userId —
# enough to correlate against the console, not enough to be a directory dump.
#
# ── TRAP 5: ListMembers without a sort has a documented default ──────────────
# "sort specifies the order of results. When unspecified, the authenticated user
# is returned first." Order is therefore not stable evidence; this pack
# paginates to exhaustion and aggregates rather than reading the first page.
#
# Tunable: ONA_MAX_ADMINS (default 3) — the admin count above which this fails.
# Exit codes: 0 compliant | 1 finding | 2 precondition
# =============================================================================

set -euo pipefail

: "${ONA_TOKEN:?set ONA_TOKEN — an Ona personal access token (Read-only is enough) or service account token}"

# TRAP (base URL). The documented base is https://app.ona.com/api. That host
# answers 308 to app.gitpod.io, and `curl -L` DROPS the Authorization header
# across the cross-host hop, so a valid token comes back 401. Default to the
# host that actually answers; override only for a custom management-plane
# domain (tokens must be minted on that same domain).
ONA_API_BASE="${ONA_API_BASE:-https://app.gitpod.io/api}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

RPC_BODY=""; RPC_CODE=""; ORG_ID=""; ORG_TIER=""; PAGE_ITEMS="[]"
BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-ona.XXXXXX")"
trap 'rm -f "${BODY_FILE}"' EXIT

# Connect-RPC unary call. Every Ona method is a POST, but no -X flag is written:
# curl already implies POST when a body is supplied, which keeps this pack
# honestly read-only under scripts/validate-packs.sh check 14.
api() {
  set +e
  RPC_CODE=$(curl -sS -o "${BODY_FILE}" -w '%{http_code}' \
    "${ONA_API_BASE}/gitpod.v1.$1" \
    -H "Authorization: Bearer ${ONA_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$2" 2>/dev/null)
  local rc=$?
  set -e
  [ "${rc}" -eq 0 ] || RPC_CODE="000"
  RPC_BODY=$(cat "${BODY_FILE}" 2>/dev/null || echo '{}')
}

rpc_err() { printf '%s' "${RPC_BODY}" | jq -r '.code // "unknown"' 2>/dev/null || echo unknown; }
rpc_msg() { printf '%s' "${RPC_BODY}" | jq -r '.message // "no message"' 2>/dev/null || echo "no message"; }

# Fatal classifier. Connect errors carry {"code": "...", "message": "..."}.
# Plan gating, auth failure and transport failure are all preconditions (exit 2),
# never findings — a control cannot be judged non-compliant on evidence that was
# never returned.
api_strict() {
  api "$1" "$2"
  if [ "${RPC_CODE}" = "200" ]; then return 0; fi
  case "${RPC_CODE}:$(rpc_err)" in
    400:failed_precondition)
      echo "PRECONDITION: $1 — $(rpc_msg)" >&2 ;;
    401:*|403:*)
      echo "PRECONDITION: $1 returned HTTP ${RPC_CODE} ($(rpc_err)) — $(rpc_msg)" >&2
      echo "  The token is invalid, expired, or lacks the permission this method requires." >&2 ;;
    000:*)
      echo "PRECONDITION: $1 — no HTTP response (network, DNS, or TLS failure)." >&2 ;;
    *)
      echo "PRECONDITION: $1 returned HTTP ${RPC_CODE} ($(rpc_err)) — $(rpc_msg)" >&2 ;;
  esac
  exit 2
}

# Follows pagination.nextToken to exhaustion. pageSize is capped at 100 by the
# API (int32.lte=100); the 200-page ceiling is a runaway guard, not a limit.
paginate() { # paginate <Service/Method> <base-json> <response-array-field>
  local method="$1" base="$2" field="$3" token="" req pages=0 tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/hth-ona-page.XXXXXX")"
  while :; do
    req=$(jq -nc --argjson base "${base}" --arg t "${token}" \
      '$base + {pagination: ({pageSize: 100} + (if $t == "" then {} else {token: $t} end))}')
    api_strict "${method}" "${req}"
    printf '%s' "${RPC_BODY}" | jq -c --arg f "${field}" '.[$f][]?' >> "${tmp}"
    token=$(printf '%s' "${RPC_BODY}" | jq -r '.pagination.nextToken // ""')
    pages=$((pages + 1))
    [ -n "${token}" ] && [ "${pages}" -lt 200 ] || break
  done
  PAGE_ITEMS=$(jq -s '.' "${tmp}")
  rm -f "${tmp}"
}

# Organization id: explicit override, else derived from the token's own identity.
resolve_org() {
  if [ -n "${ONA_ORGANIZATION_ID:-}" ]; then ORG_ID="${ONA_ORGANIZATION_ID}"; ORG_TIER="(not read)"; return 0; fi
  api_strict "IdentityService/GetAuthenticatedIdentity" '{}'
  ORG_ID=$(printf '%s' "${RPC_BODY}" | jq -r '.organizationId // ""')
  ORG_TIER=$(printf '%s' "${RPC_BODY}" | jq -r '.organizationTier // "(unset)"')
  [ -n "${ORG_ID}" ] || { echo "PRECONDITION: GetAuthenticatedIdentity returned no organizationId" >&2; exit 2; }
}

# GetOrganizationPolicies is the single read anchor for every org-wide control.
# Proto3 JSON omits defaults, so callers must read every field with a `// false`,
# `// 0`, `// []` or `// "*_UNSPECIFIED"` fallback — absence is the default
# value, not an error and not compliance.
get_policies() {
  resolve_org
  api_strict "OrganizationService/GetOrganizationPolicies" \
    "$(jq -nc --arg o "${ORG_ID}" '{organizationId: $o}')"
  POLICIES=$(printf '%s' "${RPC_BODY}" | jq -c '.policies // {}')
}
ONA_MAX_ADMINS="${ONA_MAX_ADMINS:-3}"
SHOW_ADMINS=0
case "${1:-}" in
  ""|audit) ;;
  --show-admins) SHOW_ADMINS=1 ;;
  *) echo "usage: $(basename "$0") [--show-admins]" >&2; exit 2 ;;
esac

# HTH Guide Excerpt: begin org-roles-and-groups-audit
# Three reads, one picture: who is an org ADMIN (ListMembers), what groups exist
# (ListGroups), and what privileges those groups hold (ListRoleAssignments).
# Control 1.3 is not provable from any one of them (TRAP 1).
audit() {
  resolve_org
  echo "Ona 1.3 — organization roles, groups and role assignments"
  echo "  organization: …${ORG_ID: -6} (tier ${ORG_TIER})"

  # TRAP 5: paginate to exhaustion; the default ordering is not evidence.
  paginate "OrganizationService/ListMembers" \
           "$(jq -nc --arg o "${ORG_ID}" '{organizationId: $o}')" "members"
  local members="${PAGE_ITEMS}" admins total
  total=$(jq 'length' <<<"${members}")
  admins=$(jq '[.[] | select((.role // "ORGANIZATION_ROLE_UNSPECIFIED") == "ORGANIZATION_ROLE_ADMIN")] | length' <<<"${members}")
  echo "  members: total=${total} ORGANIZATION_ROLE_ADMIN=${admins} ORGANIZATION_ROLE_MEMBER=$((total - admins))"

  # TRAP 4: counts by login provider, never the addresses themselves.
  jq -r 'group_by(.loginProvider // "(unset)") | .[] |
    "    - loginProvider=\(.[0].loginProvider // "(unset)") members=\(length)"' <<<"${members}"

  if [ "${SHOW_ADMINS}" -eq 1 ]; then
    echo "  admin userId prefixes:"
    jq -r '.[] | select((.role // "") == "ORGANIZATION_ROLE_ADMIN")
           | "    - …\(((.userId // "unknown")[-6:])) status=\(.status // "USER_STATUS_UNSPECIFIED")"' <<<"${members}"
  fi

  paginate "GroupService/ListGroups" '{}' "groups"
  local groups="${PAGE_ITEMS}"
  echo "  groups: total=$(jq 'length' <<<"${groups}")" \
       "systemManaged=$(jq '[.[] | select((.systemManaged // false) == true)] | length' <<<"${groups}")" \
       "directShare=$(jq '[.[] | select((.directShare // false) == true)] | length' <<<"${groups}")"
  # TRAP 3: only the groups a human actually created are worth listing.
  jq -r '.[] | select((.systemManaged // false) == false) | select((.directShare // false) == false)
         | "    - name=\(.name // "(unnamed)") memberCount=\(.memberCount // 0)"' <<<"${groups}"

  paginate "GroupService/ListRoleAssignments" '{}' "assignments"
  local ras="${PAGE_ITEMS}"
  echo "  role assignments: total=$(jq 'length' <<<"${ras}")"

  # TRAP 1 + TRAP 2. Join each assignment to its group name, then split the list
  # by whether it was derived from an org role or shared directly.
  local joined
  joined=$(jq -c --argjson g "${groups}" '
    ($g | map({key: (.id // ""), value: (.name // "(unknown group)")}) | from_entries) as $names
    | map(. + {groupName: ($names[.groupId // ""] // "(group not visible)")})' <<<"${ras}")

  jq -r 'group_by((.resourceType // "RESOURCE_TYPE_UNSPECIFIED") + "|" + (.resourceRole // "RESOURCE_ROLE_UNSPECIFIED"))
         | .[] | "    - \(.[0].resourceType // "RESOURCE_TYPE_UNSPECIFIED") \(.[0].resourceRole // "RESOURCE_ROLE_UNSPECIFIED") count=\(length)"' <<<"${joined}"

  local direct
  direct=$(jq '[.[] | select((.derivedFromOrgRole // "RESOURCE_ROLE_UNSPECIFIED") == "RESOURCE_ROLE_UNSPECIFIED")] | length' <<<"${joined}")
  echo "  direct (manually created) assignments: ${direct} — these are the ones a review must justify"

  local org_admin_grants
  org_admin_grants=$(jq -c '[.[] | select((.resourceRole // "") == "RESOURCE_ROLE_ORG_ADMIN")]' <<<"${joined}")
  local org_admin_count
  org_admin_count=$(jq 'length' <<<"${org_admin_grants}")
  if [ "${org_admin_count}" -gt 0 ]; then
    echo "  RESOURCE_ROLE_ORG_ADMIN grants: ${org_admin_count}"
    jq -r '.[] | "    ! group=\(.groupName) resourceType=\(.resourceType // "RESOURCE_TYPE_UNSPECIFIED") derivedFromOrgRole=\(.derivedFromOrgRole // "RESOURCE_ROLE_UNSPECIFIED")"' <<<"${org_admin_grants}"
    echo "    Every member of those groups holds organization administrator privilege."
  fi

  if [ "${admins}" -gt "${ONA_MAX_ADMINS}" ]; then
    echo "FINDING: ${admins} organization administrators exceeds ONA_MAX_ADMINS=${ONA_MAX_ADMINS}."
    echo "  ORGANIZATION_ROLE_ADMIN is all-or-nothing. The seven RESOURCE_ROLE_ORG_* roles"
    echo "  (Runners/Projects/Groups/Automations Admin, Insights Viewer, Audit Log Reader,"
    echo "  Billing Viewer) exist so that day-to-day work does not need it — assign those to a"
    echo "  group instead and demote the surplus admins to ORGANIZATION_ROLE_MEMBER."
    return 1
  fi
  echo "COMPLIANT: ${admins} organization administrator(s), at or under ONA_MAX_ADMINS=${ONA_MAX_ADMINS}."
  return 0
}
# HTH Guide Excerpt: end org-roles-and-groups-audit

audit
