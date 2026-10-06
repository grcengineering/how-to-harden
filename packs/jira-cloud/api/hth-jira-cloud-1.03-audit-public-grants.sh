#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: jira-cloud-1.3
#   guide:   https://howtoharden.com/guides/jira-cloud/#13-eliminate-unintended-public-and-anonymous-space-exposure
#   profile: L1
#   mode:    read-only
#   requires: JIRA_EMAIL, JIRA_API_TOKEN(API token with the granular read scopes listed below; owner must hold Administer Jira), JIRA_CLOUD_ID or JIRA_API_BASE, HTH_JIRA_PUBLIC_SCHEME_IDS(optional)
# =============================================================================
# HTH Jira Cloud Control 1.3: Eliminate Unintended Public and Anonymous Space Exposure
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 3.3, 4.8 | NIST 800-53 AC-3, AC-22 | ISO 27001:2022 A.5.10, A.8.3
# Source: https://howtoharden.com/guides/jira-cloud/#13-eliminate-unintended-public-and-anonymous-space-exposure
# Dependencies: bash (3.2+), curl, jq
#
# READ-ONLY. Every call is a GET against the Jira Cloud REST API v3, transcribed
# from the vendor's OpenAPI spec
# (https://developer.atlassian.com/cloud/jira/platform/swagger-v3.v3.json):
#   GET /rest/api/3/mypermissions?permissions=ADMINISTER
#   GET /rest/api/3/permissionscheme?expand=permissions
#   GET /rest/api/3/project/search              (paged: startAt/maxResults/isLast)
#   GET /rest/api/3/project/{projectKeyOrId}/permissionscheme
# The console's **Public** is the spec's holder type `anyone`, "Grant for
# anonymous users". Removing one is
# DELETE /rest/api/3/permissionscheme/{schemeId}/permission/{permissionId};
# this pack only reports, because the scheme may be shared (guide Step 2.3).
#
# CREDENTIALS. Same as the 1.1 pack: an API token *with scopes*, called through
# https://api.atlassian.com/ex/jira/{cloudId} (cloud ID from
# https://<site>.atlassian.net/_edge/tenant_info), with only these granular
# read scopes (the spec marks them "Beta"):
#   read:permission-scheme:jira read:permission:jira read:project:jira
#   read:project-role:jira read:project-category:jira read:project-version:jira
#   read:project.component:jira read:project.property:jira read:issue-type:jira
#   read:issue-type-hierarchy:jira read:application-role:jira read:group:jira
#   read:user:jira read:field:jira read:avatar:jira
# A token without scopes works with JIRA_API_BASE=https://<site>.atlassian.net.
# The token's owner must hold *Administer Jira*, or project/search returns a
# partial list of spaces; the pack checks this first and stops.
#
# DELIBERATELY PUBLIC SPACES (guide Step 3). List their dedicated scheme IDs in
# HTH_JIRA_PUBLIC_SCHEME_IDS (comma-separated, e.g. "10310,10311"). A listed
# scheme is reported as governed when no more than one space uses it, and as a
# finding when it is shared, because a shared public scheme leaks sideways.
#
# Exit codes: 0 no unintended public grant | 1 finding | 2 precondition or failed call.
# A failed call is never reported as a clean result.
# =============================================================================

set -euo pipefail

need() { [ -n "${!1:-}" ] || { echo "PRECONDITION: set $1 - $2" >&2; exit 2; }; }
need JIRA_EMAIL "the Atlassian account email that owns JIRA_API_TOKEN"
need JIRA_API_TOKEN "an Atlassian API token (see CREDENTIALS above)"
if [ -z "${JIRA_API_BASE:-}" ]; then
  need JIRA_CLOUD_ID "the site's cloud ID (https://<site>.atlassian.net/_edge/tenant_info), or set JIRA_API_BASE"
  case "${JIRA_CLOUD_ID}" in
    *[!0-9A-Za-z-]*) echo "PRECONDITION: JIRA_CLOUD_ID must be the site's cloud ID (letters, digits, hyphens)" >&2; exit 2 ;;
  esac
  JIRA_API_BASE="https://api.atlassian.com/ex/jira/${JIRA_CLOUD_ID}"
fi
JIRA_API_BASE="${JIRA_API_BASE%/}"
case "${JIRA_API_BASE}" in
  https://*) ;;
  *) echo "PRECONDITION: JIRA_API_BASE must be an https:// URL; basic auth is never sent over plain HTTP" >&2; exit 2 ;;
esac
case "${JIRA_EMAIL}${JIRA_API_TOKEN}" in
  *\"*|*\\*) echo "PRECONDITION: JIRA_EMAIL or JIRA_API_TOKEN contains a quote or backslash" >&2; exit 2 ;;
esac

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/hth-jira-cloud-103.XXXXXX")" \
  || { echo "PRECONDITION: cannot create a temp directory under ${TMPDIR:-/tmp}" >&2; exit 2; }
trap 'rm -rf "${WORK}"' EXIT
BODY="${WORK}/body.json"

# One GET. Anything other than a 2xx JSON body stops the run with exit 2, so a
# failed call can never be mistaken for an empty (clean) result. Pass "allow404"
# only for project/search, whose spec documents 404 as "no projects found".
jira_get() {
  local path="$1" allow404="${2:-}" code rc
  set +e
  code=$(curl -sS --max-time 60 -o "${BODY}" -w '%{http_code}' \
    -K <(printf 'user = "%s:%s"\n' "${JIRA_EMAIL}" "${JIRA_API_TOKEN}") \
    -H 'Accept: application/json' \
    "${JIRA_API_BASE}${path}")
  rc=$?
  set -e
  if [ "${rc}" -ne 0 ]; then
    echo "PRECONDITION: GET ${path} - no HTTP response (curl exit ${rc})" >&2; exit 2
  fi
  if [ "${code}" = "404" ] && [ "${allow404}" = "allow404" ]; then
    printf '%s' '{"values":[],"isLast":true}' > "${BODY}"; return 0
  fi
  case "${code}" in
    2??) ;;
    401) echo "PRECONDITION: GET ${path} returned HTTP 401 - token invalid or expired, or a scoped token sent to a site URL instead of api.atlassian.com/ex/jira/{cloudId}" >&2; exit 2 ;;
    403) echo "PRECONDITION: GET ${path} returned HTTP 403 - the token lacks a scope listed above, or its owner lacks the permission" >&2; exit 2 ;;
    *)   echo "PRECONDITION: GET ${path} returned HTTP ${code}: $(jq -r '(.errorMessages // []) | join("; ")' "${BODY}" 2>/dev/null || true)" >&2; exit 2 ;;
  esac
  jq -e 'type == "object" or type == "array"' "${BODY}" >/dev/null 2>&1 \
    || { echo "PRECONDITION: GET ${path} returned a body that is not JSON" >&2; exit 2; }
}

# Collects .values[] across startAt/maxResults pages into the JSON array file $2.
jira_pages() {
  local path="$1" out="$2" allow404="${3:-}" start=0 sep='?' n pages=0
  case "${path}" in *\?*) sep='&' ;; esac
  : > "${out}.jsonl"
  while :; do
    jira_get "${path}${sep}startAt=${start}&maxResults=50" "${allow404}"
    jq -e 'has("values") and (.values | type == "array")' "${BODY}" >/dev/null 2>&1 \
      || { echo "PRECONDITION: GET ${path} did not return a paged .values array" >&2; exit 2; }
    jq -c '.values[]' "${BODY}" >> "${out}.jsonl"
    n=$(jq '.values | length' "${BODY}")
    if [ "$(jq -r '.isLast // false' "${BODY}")" = "true" ] || [ "${n}" -eq 0 ]; then break; fi
    start=$((start + n)); pages=$((pages + 1))
    [ "${pages}" -lt 500 ] || { echo "PRECONDITION: GET ${path} still paging after 500 pages" >&2; exit 2; }
  done
  jq -s '.' "${out}.jsonl" > "${out}"
}

require_admin() {
  jira_get "/rest/api/3/mypermissions?permissions=ADMINISTER"
  if [ "$(jq -r '.permissions.ADMINISTER.havePermission // false' "${BODY}")" != "true" ]; then
    echo "PRECONDITION: the token's owner does not hold the Administer Jira global permission." >&2
    echo "  project/search would return only the spaces it can see, so the audit would be partial." >&2
    exit 2
  fi
}

# Writes [{scheme, space}] for every company-managed space to $WORK/map.json.
# Team-managed ("next-gen") spaces are not governed by permission schemes.
map_spaces_to_schemes() {
  jira_pages "/rest/api/3/project/search" "${WORK}/projects.json" allow404
  local expected pid pkey
  expected=$(jq '[.[] | select(.style == "classic")] | length' "${WORK}/projects.json")
  : > "${WORK}/map.jsonl"
  while IFS="$(printf '\t')" read -r pid pkey; do
    case "${pid}" in ''|*[!0-9]*) echo "PRECONDITION: project/search returned a non-numeric project id" >&2; exit 2 ;; esac
    jira_get "/rest/api/3/project/${pid}/permissionscheme"
    jq -e '.id != null' "${BODY}" >/dev/null 2>&1 \
      || { echo "PRECONDITION: no permission scheme id returned for space ${pkey}" >&2; exit 2; }
    jq -c --arg k "${pkey}" '{scheme: (.id | tostring), space: $k}' "${BODY}" >> "${WORK}/map.jsonl"
  done < <(jq -r '.[] | select(.style == "classic") | [.id, .key] | @tsv' "${WORK}/projects.json")
  jq -s '.' "${WORK}/map.jsonl" > "${WORK}/map.json"
  if [ "$(jq 'length' "${WORK}/map.json")" -ne "${expected}" ]; then
    echo "PRECONDITION: mapped $(jq 'length' "${WORK}/map.json") of ${expected} company-managed spaces" >&2; exit 2
  fi
}


# HTH Guide Excerpt: begin public-grant-audit
# Guide Step 1: find every grant to Public (holder type anyone) and every space
# each such scheme exposes. Guide Step 3: a declared public scheme must be
# dedicated to a single space.
audit() {
  local declared="${HTH_JIRA_PUBLIC_SCHEME_IDS:-}"
  case "${declared}" in
    *[!0-9,]*) echo "PRECONDITION: HTH_JIRA_PUBLIC_SCHEME_IDS must be comma-separated numeric scheme IDs" >&2; exit 2 ;;
  esac
  require_admin
  jira_get "/rest/api/3/permissionscheme?expand=permissions"
  cp "${BODY}" "${WORK}/schemes.json"
  local total public
  total=$(jq '(.permissionSchemes // []) | length' "${WORK}/schemes.json")
  if [ "${total}" -eq 0 ]; then
    echo "PRECONDITION: zero permission schemes returned - Free sites have none and cannot be public (guide Appendix A); nothing was audited" >&2
    exit 2
  fi
  jq -e '[.permissionSchemes[] | has("permissions")] | all' "${WORK}/schemes.json" >/dev/null 2>&1 \
    || { echo "PRECONDITION: schemes came back without their grants (expand=permissions not honoured)" >&2; exit 2; }
  public=$(jq '[.permissionSchemes[] | select(any(.permissions[]; .holder.type == "anyone"))] | length' "${WORK}/schemes.json")

  echo "Jira Cloud 1.3 - public and anonymous space exposure audit"
  echo "  permission schemes: ${total}; with a Public (anyone) grant: ${public}"
  if [ "${public}" -eq 0 ]; then
    echo "COMPLIANT: no permission scheme grants anything to Public (holder type anyone)."
    return 0
  fi
  map_spaces_to_schemes

  jq --slurpfile map "${WORK}/map.json" --arg declared "${declared}" '
    ($declared | split(",") | map(select(length > 0))) as $ok
    | ($map[0] | group_by(.scheme) | map({key: .[0].scheme, value: map(.space)}) | from_entries) as $spaces
    | [ .permissionSchemes[]
        | select(any(.permissions[]; .holder.type == "anyone"))
        | (.id | tostring) as $id
        | ($spaces[$id] // []) as $sp
        | ([.permissions[] | select(.holder.type == "anyone") | .permission] | unique) as $keys
        | (if ($sp | length) == 0 then "no space yet (any space later given this scheme becomes public)" else ($sp | join(", ")) end) as $where
        | if ($ok | index($id)) == null then
            "FINDING: \"\(.name)\" (id \($id)) grants \($keys | join(", ")) to Public - readable without authentication in: \($where)"
          elif ($sp | length) > 1 then
            "FINDING: declared public scheme \"\(.name)\" (id \($id)) is shared by \($sp | length) spaces (\($where)) - give the public space a scheme no other space uses (Step 3.1)"
          else
            "GOVERNED: declared public scheme \"\(.name)\" (id \($id)) grants \($keys | join(", ")) to Public for: \($where)"
            + (if ($keys | index("CREATE_ISSUES")) != null
               then "\nREVIEW: anonymous work item creation is on for \"\(.name)\" - keep it only with a moderation workflow (Step 3.3)"
               else "" end)
          end ]' "${WORK}/schemes.json" > "${WORK}/lines.json"

  jq -r '.[]' "${WORK}/lines.json"
  local n
  n=$(jq '[.[] | select(startswith("FINDING"))] | length' "${WORK}/lines.json")
  if [ "${n}" -gt 0 ]; then
    echo "${n} finding(s). Remove the Public grant, or replace it with Any logged in user (guide Step 2)."
    return 1
  fi
  echo "COMPLIANT: every Public grant is on a declared, dedicated public scheme."
}
# HTH Guide Excerpt: end public-grant-audit

audit
