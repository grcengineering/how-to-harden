#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: jira-cloud-2.2
#   guide:   https://howtoharden.com/guides/jira-cloud/#22-control-guest-and-external-collaborator-access
#   profile: L2
#   mode:    read-only
#   requires: ATLASSIAN_ORG_API_KEY(Organization API key with scopes, read:directories:admin only), ATLASSIAN_ORG_ID, HTH_GUEST_ROSTER(needed for a verdict)
# =============================================================================
# HTH Jira Cloud Control 2.2: Control Guest and External Collaborator Access
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 6.1, 6.2, 6.8 | NIST 800-53 AC-2, AC-3, PS-7 | ISO 27001:2022 A.5.19, A.5.20
# Source: https://howtoharden.com/guides/jira-cloud/#22-control-guest-and-external-collaborator-access
# Dependencies: bash (3.2+), curl, jq
#
# READ-ONLY. Two GETs on the Organization REST API
# (https://developer.atlassian.com/cloud/admin/organization/rest/api-group-users/),
# base https://api.atlassian.com/admin, both documented under the scope
# read:directories:admin:
#   GET /v2/orgs/{orgId}/directories/-/users?roleIds=atlassian/guest
#       "atlassian/guest - Can only access one space you or space admins specify"
#   GET /v2/orgs/{orgId}/directories/-/users/{accountId}/role-assignments?roleIds=atlassian/guest
# ("-" = every directory the key may manage; pages follow links.next as ?cursor=).
# DEPRECATION: Atlassian marks the users GET "deprecated and will no longer work
# after June 30, 2027" in favour of POST .../users/search. This pack keeps the GET
# because read:directories:admin is documented for it, so the key can stay
# read-only; move to the search endpoint before that date.
# The same API also WRITES this role (POST /v1/orgs/{orgId}/users/{userId}/roles/assign
# and .../roles/revoke with role atlassian/guest); this pack never calls them.
# Adding a guest to a space (Guest - Collaborator) happens in the space's People
# settings and is not covered here.
#
# CREDENTIALS. An Organization API key *with scopes* (admin.atlassian.com >
# Organization settings > API keys > API keys with scopes), read:directories:admin
# only, shortest expiry offered, sent as "Authorization: Bearer". It goes to curl
# as a config on a file descriptor, never in the process list. Minting it needs
# the Organization admin role. ATLASSIAN_ORG_ID is in the Atlassian
# Administration URL.
#
# THE VERDICT NEEDS YOUR ROSTER. Guide Step 4.2: "treat any guest with no
# matching contract as an incident". Put the account IDs of sponsored guests in
# HTH_GUEST_ROSTER (comma-separated). Without it the pack prints the inventory
# and exits 2, because it cannot tell a sponsored guest from a forgotten one.
#
# Exit codes: 0 every active Jira guest is on the roster | 1 finding |
#             2 precondition, failed call, or no roster supplied.
# A failed call is never reported as a clean result.
# =============================================================================

set -euo pipefail

need() { [ -n "${!1:-}" ] || { echo "PRECONDITION: set $1 - $2" >&2; exit 2; }; }
need ATLASSIAN_ORG_API_KEY "an Organization API key with scope read:directories:admin"
need ATLASSIAN_ORG_ID "the organization ID from the Atlassian Administration URL"
ORG_API_BASE="https://api.atlassian.com/admin"
case "${ATLASSIAN_ORG_ID}" in
  ''|*[!0-9A-Za-z-]*) echo "PRECONDITION: ATLASSIAN_ORG_ID must be the organization ID (letters, digits, hyphens)" >&2; exit 2 ;;
esac
case "${ATLASSIAN_ORG_API_KEY}" in
  *\"*|*\\*) echo "PRECONDITION: ATLASSIAN_ORG_API_KEY contains a quote or backslash" >&2; exit 2 ;;
esac
ROSTER="${HTH_GUEST_ROSTER:-}"
case "${ROSTER}" in
  *[!0-9A-Za-z:_,-]*) echo "PRECONDITION: HTH_GUEST_ROSTER must be comma-separated Atlassian account IDs" >&2; exit 2 ;;
esac

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/hth-jira-cloud-202.XXXXXX")" \
  || { echo "PRECONDITION: cannot create a temp directory under ${TMPDIR:-/tmp}" >&2; exit 2; }
trap 'rm -rf "${WORK}"' EXIT
BODY="${WORK}/body.json"

# One GET. Anything other than a 2xx JSON body stops the run with exit 2, so a
# failed call can never be mistaken for an empty (clean) result.
org_get() {
  local path="$1" code rc
  set +e
  code=$(curl -sS --max-time 60 -o "${BODY}" -w '%{http_code}' \
    -K <(printf 'header = "Authorization: Bearer %s"\n' "${ATLASSIAN_ORG_API_KEY}") \
    -H 'Accept: application/json' \
    "${ORG_API_BASE}${path}")
  rc=$?
  set -e
  if [ "${rc}" -ne 0 ]; then
    echo "PRECONDITION: GET ${path} - no HTTP response (curl exit ${rc})" >&2; exit 2
  fi
  case "${code}" in
    2??) ;;
    401) echo "PRECONDITION: GET ${path} returned HTTP 401 - the Organization API key is invalid, expired or revoked" >&2; exit 2 ;;
    403) echo "PRECONDITION: GET ${path} returned HTTP 403 - the key lacks read:directories:admin or belongs to another organization" >&2; exit 2 ;;
    *)   echo "PRECONDITION: GET ${path} returned HTTP ${code}: $(jq -r '[(.errors // [])[] | (.title // .code // empty)] | join("; ")' "${BODY}" 2>/dev/null || true)" >&2; exit 2 ;;
  esac
  jq -e 'has("data") and (.data | type == "array")' "${BODY}" >/dev/null 2>&1 \
    || { echo "PRECONDITION: GET ${path} did not return a .data array" >&2; exit 2; }
}

# All pages of $1 into the JSON array file $2. The API's cursor replaces every
# other query parameter on later pages ("If present, all other parameters are
# discarded"), so a next page is requested with the cursor alone.
org_pages() {
  local first="$1" out="$2" path cursor pages=0
  path="${first}"
  : > "${out}.jsonl"
  while :; do
    org_get "${path}"
    jq -c '.data[]' "${BODY}" >> "${out}.jsonl"
    cursor=$(jq -r '.links.next // "" | @uri' "${BODY}")
    [ -n "${cursor}" ] || break
    path="${first%%\?*}?cursor=${cursor}"
    pages=$((pages + 1))
    [ "${pages}" -lt 500 ] || { echo "PRECONDITION: ${first%%\?*} still paging after 500 pages" >&2; exit 2; }
  done
  jq -s '.' "${out}.jsonl" > "${out}"
}

# HTH Guide Excerpt: begin guest-roster-audit
# Guide Step 1: inventory every account holding the Guest role and the Jira
# resources it holds it on. Guide Step 4.2: an active Jira guest with no entry
# in the sponsor roster (HTH_GUEST_ROSTER) is a finding.
audit() {
  local org="/v2/orgs/${ATLASSIAN_ORG_ID}/directories/-/users"
  org_pages "${org}?roleIds=atlassian%2Fguest&limit=100" "${WORK}/guests.json"
  local expected acct
  expected=$(jq 'length' "${WORK}/guests.json")
  : > "${WORK}/rows.jsonl"
  while read -r acct; do
    case "${acct}" in ''|*[!0-9A-Za-z:_-]*) echo "PRECONDITION: users GET returned a malformed accountId" >&2; exit 2 ;; esac
    org_pages "${org}/${acct}/role-assignments?roleIds=atlassian%2Fguest&limit=100" "${WORK}/ra.json"
    jq -c --slurpfile g "${WORK}/guests.json" --arg a "${acct}" '
      ($g[0][] | select(.accountId == $a)) as $u
      | { account: $a,
          status: ($u.status // "unknown"),
          added: (($u.addedToOrg // "") | .[0:10]),
          jira: [ .[] | select((.resourceOwner // "") | startswith("jira")) | .resourceId ],
          other: [ .[] | select(((.resourceOwner // "") | startswith("jira")) | not) | (.resourceOwner // "unknown") ] }' \
      "${WORK}/ra.json" >> "${WORK}/rows.jsonl"
  done < <(jq -r '.[].accountId' "${WORK}/guests.json")
  jq -s '.' "${WORK}/rows.jsonl" > "${WORK}/rows.json"
  if [ "$(jq 'length' "${WORK}/rows.json")" -ne "${expected}" ]; then
    echo "PRECONDITION: read role assignments for $(jq 'length' "${WORK}/rows.json") of ${expected} guests" >&2; exit 2
  fi

  echo "Jira Cloud 2.2 - guest account inventory"
  echo "  accounts holding atlassian/guest: ${expected}; on a Jira resource: $(jq '[.[] | select(.jira | length > 0)] | length' "${WORK}/rows.json")"
  jq -r '.[] | select(.jira | length > 0)
    | "  - ...\(.account | .[-6:]) status=\(.status) added=\(.added) jira resources=\(.jira | length)"' "${WORK}/rows.json"
  jq -r '[.[] | select(.jira | length == 0) | .other[]] | group_by(.) | .[]
    | "  INFO: \(length) guest role(s) on non-Jira resource owner \(.[0])"' "${WORK}/rows.json"

  if [ "$(jq '[.[] | select(.jira | length > 0)] | length' "${WORK}/rows.json")" -eq 0 ]; then
    echo "COMPLIANT: no account holds the Guest role on a Jira resource."
    return 0
  fi
  if [ -z "${ROSTER}" ]; then
    echo "PRECONDITION: set HTH_GUEST_ROSTER to the sponsored guests' account IDs to get a verdict (guide Step 4.2)." >&2
    exit 2
  fi

  jq --arg roster "${ROSTER}" '
    ($roster | split(",") | map(select(length > 0))) as $ok
    | [ .[] | select(.jira | length > 0) | select(.status == "active")
        | select(.account as $a | $ok | index($a) == null)
        | "FINDING: active Jira guest ...\(.account | .[-6:]) (added \(.added)) has no sponsor on the roster - confirm the engagement or remove the guest (Steps 3.3, 4.2)" ]
    + [ $ok[] as $r | select([.[] | .account] | index($r) == null)
        | "INFO: roster entry ...\($r | .[-6:]) no longer holds the Guest role - update the roster" ]' \
    "${WORK}/rows.json" > "${WORK}/lines.json"

  jq -r '.[]' "${WORK}/lines.json"
  local n
  n=$(jq '[.[] | select(startswith("FINDING"))] | length' "${WORK}/lines.json")
  if [ "${n}" -gt 0 ]; then
    echo "${n} unsponsored active Jira guest(s)."
    return 1
  fi
  echo "COMPLIANT: every active Jira guest is on the sponsor roster."
}
# HTH Guide Excerpt: end guest-roster-audit

audit
