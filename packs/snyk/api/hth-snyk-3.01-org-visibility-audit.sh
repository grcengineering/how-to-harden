#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: snyk-3.1
#   guide:   https://howtoharden.com/guides/snyk/#31-project-visibility
#   profile: L1
#   mode:    read-only
#   requires: SNYK_TOKEN(org.membership.read; tenant.roles.read for the role review), SNYK_ORG_ID, SNYK_TENANT_ID(optional)
# =============================================================================
# HTH Snyk Control 3.1: Project Visibility
# Profile: L1 | NIST 800-53: AC-21
# https://howtoharden.com/guides/snyk/#31-project-visibility
#
# Snyk documents no per-Project visibility setting: every pre-defined
# Organization role can view the Organization's Projects, ignores and reports.
# Visibility is therefore decided by who is a member of the Organization, and
# (Enterprise) by custom roles that withhold view permissions. This pack reads
# both:
#   1. who can see this Organization's findings - its memberships, per role;
#   2. with SNYK_TENANT_ID set, which Tenant roles hold the view permissions
#      that expose findings: org.project.read (View Projects),
#      org.project.snapshot.read (View Project history) and
#      org.report.read (View Organization reports).
#
# Plan gate: Snyk restricts its API to Enterprise plan customers; custom roles
# are Enterprise-only as well.
# Endpoints (Snyk REST spec):
#   GET /orgs/{org_id}/memberships   GA   (2024-08-25)      View Organization Memberships (org.membership.read)
#   GET /tenants/{tenant_id}/roles   BETA (2024-10-15~beta) View Tenant Roles (tenant.roles.read)
# Member lists are reduced to a count per role here; no names or emails.
#
# Exit codes: 0 read completed | 2 precondition, bad input, or a request that did not succeed
# Requires: curl, jq.
# Verified against:
#   https://docs.snyk.io/developer-tools/snyk-api/reference/orgs
#   https://docs.snyk.io/developer-tools/snyk-api/reference/tenantrole
#   https://docs.snyk.io/platform-administration/user-management/pre-defined-roles
set -euo pipefail

command -v curl >/dev/null || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq >/dev/null || { echo "PRECONDITION: jq not found" >&2; exit 2; }

# HTH Guide Excerpt: begin api-snyk-rest-get-paginated
if [ -z "${SNYK_TOKEN:-}" ]; then
  echo "PRECONDITION: set SNYK_TOKEN - see the least-privilege note in this pack header" >&2; exit 2
fi
SNYK_API="${SNYK_API:-https://api.snyk.io}"
SNYK_API_VERSION="${SNYK_API_VERSION:-2024-10-15}"
SNYK_ROLES_API_VERSION="${SNYK_ROLES_API_VERSION:-2024-10-15~beta}"
UUID_RE='^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
MAX_PAGES="${SNYK_MAX_PAGES:-1000}"

# One GET that fails closed: a transport error or any HTTP status >= 400
# aborts the audit instead of being read as an empty result.
snyk_get() {
  curl -sS -f \
    --header "Authorization: token ${SNYK_TOKEN}" \
    --header "Accept: application/vnd.api+json" \
    "$1"
}

# links.next arrives as a string or as {href}, absolute or relative to /rest.
# A link that leaves the configured API host is refused: the token would go
# with it.
next_url() {
  local next
  next=$(printf '%s' "$1" | jq -r '.links.next // empty | if type == "object" then .href else . end') || return 1
  case "${next}" in
    "") ;;
    "${SNYK_API}"/*) printf '%s' "${next}" ;;
    http://* | https://*) echo "ERROR: refusing to follow a pagination link to another host" >&2; return 1 ;;
    /rest/*) printf '%s' "${SNYK_API}${next}" ;;
    /*) printf '%s' "${SNYK_API}/rest${next}" ;;
    *) echo "ERROR: unrecognised pagination link" >&2; return 1 ;;
  esac
}

# Print one jq projection per item across every page of a list endpoint.
# Returns 2 on any failed request or on a body that is not a JSON:API list.
snyk_list() {
  local url="$1" projection="$2" page pages=0
  while [ -n "${url}" ]; do
    page=$(snyk_get "${url}") || { echo "ERROR: GET ${url%%\?*} did not succeed" >&2; return 2; }
    printf '%s' "${page}" | jq -e '.data | type == "array"' >/dev/null \
      || { echo "ERROR: response is not the documented JSON:API list" >&2; return 2; }
    printf '%s' "${page}" | jq -r ".data[] | ${projection}" || return 2
    pages=$((pages + 1))
    [ "${pages}" -lt "${MAX_PAGES}" ] || { echo "ERROR: pagination did not end after ${MAX_PAGES} pages" >&2; return 2; }
    url=$(next_url "${page}") || return 2
  done
}
# HTH Guide Excerpt: end api-snyk-rest-get-paginated

# HTH Guide Excerpt: begin api-org-visibility-audit
# Everyone listed here can read this Organization's Projects, issues and ignores.
org_viewers() {
  local org_id="$1" roles total
  roles=$(snyk_list "${SNYK_API}/rest/orgs/${org_id}/memberships?version=${SNYK_API_VERSION}&limit=100" \
    '.relationships.role.data.attributes.name // "(no role)"') || return 2
  total=$(printf '%s' "${roles}" | grep -c . || true)
  echo "== orgs/${org_id}: ${total} member(s) can view its Projects and findings =="
  [ "${total}" -eq 0 ] || printf '%s\n' "${roles}" | sort | uniq -c | sed 's/^ */  /'
}

# Which Tenant roles carry the permissions that expose findings. A role whose
# permission list comes back empty is reported as such, never as "no access".
role_view_permissions() {
  local tenant_id="$1"
  echo "== Tenant roles: view permissions (projects / project history / org reports) =="
  snyk_list "${SNYK_API}/rest/tenants/${tenant_id}/roles?version=${SNYK_ROLES_API_VERSION}&limit=100" \
    '.attributes | [ .name,
       (if .custom then "custom" else "pre-defined" end),
       (if ((.permissions // []) | length) == 0 then "permissions not returned - review in the console"
        else "org.project.read=" + (if (.permissions | any(. == "org.project.read")) then "yes" else "no" end)
          + " org.project.snapshot.read=" + (if (.permissions | any(. == "org.project.snapshot.read")) then "yes" else "no" end)
          + " org.report.read=" + (if (.permissions | any(. == "org.report.read")) then "yes" else "no" end)
        end) ] | @tsv' | sed 's/^/  /'
}
# HTH Guide Excerpt: end api-org-visibility-audit

# HTH Guide Excerpt: begin api-org-visibility-audit-run
if [ -z "${SNYK_ORG_ID:-}" ]; then
  echo "PRECONDITION: set SNYK_ORG_ID - visibility is decided per Organization" >&2; exit 2
fi
[[ "${SNYK_ORG_ID}" =~ ${UUID_RE} ]] || { echo "ERROR: SNYK_ORG_ID is not a UUID" >&2; exit 2; }
org_viewers "${SNYK_ORG_ID}"
if [ -n "${SNYK_TENANT_ID:-}" ]; then
  [[ "${SNYK_TENANT_ID}" =~ ${UUID_RE} ]] || { echo "ERROR: SNYK_TENANT_ID is not a UUID" >&2; exit 2; }
  role_view_permissions "${SNYK_TENANT_ID}"
fi
# HTH Guide Excerpt: end api-org-visibility-audit-run
