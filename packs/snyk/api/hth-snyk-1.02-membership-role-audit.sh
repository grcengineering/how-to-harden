#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: snyk-1.2
#   guide:   https://howtoharden.com/guides/snyk/#12-role-based-access
#   profile: L1
#   mode:    read-only
#   requires: SNYK_TOKEN(org.membership.read and/or group.membership.read), SNYK_ORG_ID and/or SNYK_GROUP_ID, SNYK_MAX_ADMINS(optional)
# =============================================================================
# HTH Snyk Control 1.2: Role-Based Access
# Profile: L1 | NIST 800-53: AC-3, AC-6
# https://howtoharden.com/guides/snyk/#12-role-based-access
#
# Access-review evidence for least privilege: every membership of an
# Organization and/or Group with its role, a count per role, and the admins by
# username (no emails). Roles are SET in the console (Organization -> Members)
# or with PATCH .../memberships/{membership_id}; this pack only reads.
#
# Plan gate: roles exist on every plan, but Snyk restricts its API to Enterprise
# plan customers, so this pack needs an Enterprise organization.
# Endpoints (Snyk REST spec; GA since 2024-08-25, so pin a version on or after it):
#   GET /orgs/{org_id}/memberships      View Organization Memberships (org.membership.read)
#   GET /groups/{group_id}/memberships  View Group Memberships (group.membership.read)
# Role names are the API's own. A role counts as admin when its name contains
# "admin" (case-insensitive), which includes custom roles named that way.
# Set SNYK_MAX_ADMINS to turn the review into a gate: more admins than that in
# any scope is a finding.
#
# Exit codes: 0 read completed (and within SNYK_MAX_ADMINS when set)
#             1 admin count above SNYK_MAX_ADMINS
#             2 precondition, bad input, or a request that did not succeed
# Requires: curl, jq.
# Verified against:
#   https://docs.snyk.io/developer-tools/snyk-api/reference/orgs
#   https://docs.snyk.io/developer-tools/snyk-api/reference/groups
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

# HTH Guide Excerpt: begin api-membership-role-audit
FINDINGS=0

# Review one scope: "orgs <org_id>" or "groups <group_id>".
audit_memberships() {
  local scope="$1" scope_id="$2" rows total admins
  rows=$(snyk_list "${SNYK_API}/rest/${scope}/${scope_id}/memberships?version=${SNYK_API_VERSION}&limit=100" \
    '[(.relationships.role.data.attributes.name // "(no role)"),
      (.relationships.user.data.attributes.username // "(unknown user)")] | @tsv') || return 2
  total=$(printf '%s' "${rows}" | grep -c . || true)
  admins=$(printf '%s\n' "${rows}" | awk -F '\t' 'tolower($1) ~ /admin/' | grep -c . || true)
  echo "== ${scope}/${scope_id}: ${total} membership(s), ${admins} with an admin role =="
  if [ "${total}" -gt 0 ]; then
    echo "-- members per role:"
    printf '%s\n' "${rows}" | cut -f1 | sort | uniq -c | sed 's/^ */  /'
    echo "-- admins (review each against need):"
    printf '%s\n' "${rows}" | awk -F '\t' 'tolower($1) ~ /admin/ { print "  " $1 "\t" $2 }'
  fi
  if [ -n "${SNYK_MAX_ADMINS:-}" ] && [ "${admins}" -gt "${SNYK_MAX_ADMINS}" ]; then
    echo "FINDING: ${scope}/${scope_id} has ${admins} admins, above SNYK_MAX_ADMINS=${SNYK_MAX_ADMINS}"
    FINDINGS=$((FINDINGS + 1))
  fi
}
# HTH Guide Excerpt: end api-membership-role-audit

# HTH Guide Excerpt: begin api-membership-role-audit-run
if [ -z "${SNYK_GROUP_ID:-}" ] && [ -z "${SNYK_ORG_ID:-}" ]; then
  echo "ERROR: set SNYK_ORG_ID and/or SNYK_GROUP_ID - nothing to review" >&2; exit 2
fi
if [ -n "${SNYK_MAX_ADMINS:-}" ] && ! [[ "${SNYK_MAX_ADMINS}" =~ ^[0-9]+$ ]]; then
  echo "ERROR: SNYK_MAX_ADMINS must be a whole number" >&2; exit 2
fi
for scope in groups orgs; do
  if [ "${scope}" = groups ]; then scope_id="${SNYK_GROUP_ID:-}"; else scope_id="${SNYK_ORG_ID:-}"; fi
  [ -n "${scope_id}" ] || continue
  [[ "${scope_id}" =~ ${UUID_RE} ]] || { echo "ERROR: the ${scope} id is not a UUID" >&2; exit 2; }
  audit_memberships "${scope}" "${scope_id}"
done
[ "${FINDINGS}" -eq 0 ] || exit 1
# HTH Guide Excerpt: end api-membership-role-audit-run
