#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: jira-cloud-1.1
#   guide:   https://howtoharden.com/guides/jira-cloud/#11-configure-permission-schemes-for-least-privilege
#   profile: L1
#   mode:    read-only
#   requires: JIRA_EMAIL, JIRA_API_TOKEN(API token with the granular read scopes listed below; owner must hold Administer Jira), JIRA_CLOUD_ID or JIRA_API_BASE
# =============================================================================
# HTH Jira Cloud Control 1.1: Configure Permission Schemes for Least Privilege
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 3.3, 5.4, 6.8 | NIST 800-53 AC-3, AC-6 | ISO 27001:2022 A.5.15, A.8.3
# Source: https://howtoharden.com/guides/jira-cloud/#11-configure-permission-schemes-for-least-privilege
# Dependencies: bash (3.2+), curl, jq
#
# READ-ONLY. Every call is a GET against the Jira Cloud REST API v3, transcribed
# from the vendor's OpenAPI spec
# (https://developer.atlassian.com/cloud/jira/platform/swagger-v3.v3.json):
#   GET /rest/api/3/mypermissions?permissions=ADMINISTER
#   GET /rest/api/3/permissionscheme?expand=permissions
#   GET /rest/api/3/project/search              (paged: startAt/maxResults/isLast)
#   GET /rest/api/3/project/{projectKeyOrId}/permissionscheme
# The API can also WRITE grants (POST and DELETE on
# /rest/api/3/permissionscheme/{schemeId}/permission). This pack deliberately
# does not: a scheme is shared by every space that uses it, so change grants in
# the console where you can see that blast radius (guide Steps 2-4).
#
# CREDENTIALS. Atlassian recommends an API token *with scopes*. A scoped token
# must call https://api.atlassian.com/ex/jira/{cloudId}, which is this pack's
# default base (find the cloud ID at https://<site>.atlassian.net/_edge/tenant_info).
# Grant only the granular read scopes the spec lists for the four GETs above:
#   read:permission-scheme:jira read:permission:jira read:project:jira
#   read:project-role:jira read:project-category:jira read:project-version:jira
#   read:project.component:jira read:project.property:jira read:issue-type:jira
#   read:issue-type-hierarchy:jira read:application-role:jira read:group:jira
#   read:user:jira read:field:jira read:avatar:jira
# (the spec marks the granular scopes "Beta"). A token without scopes also works
# with JIRA_API_BASE=https://<site>.atlassian.net, but it can do everything its
# owner can. Auth is HTTP basic <email>:<token>, handed to curl as a config on a
# file descriptor so the token never appears in the process list.
#
# THE TOKEN'S OWNER MUST HOLD *Administer Jira*. project/search returns only the
# spaces the caller can browse or administer, so a non-admin would audit part of
# the site and report it as the whole. The pack checks this first and stops.
#
# HOLDER TYPES (spec, "About permission schemes and grants"): `anyone` = "Grant
# for anonymous users" (the console's Public); `applicationRole` = "Grant for
# users with access to the specified application"; `user` = one account.
#
# Exit codes: 0 no finding | 1 finding | 2 precondition or failed call.
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

WORK="$(mktemp -d "${TMPDIR:-/tmp}/hth-jira-cloud-101.XXXXXX")" \
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

# HTH Guide Excerpt: begin permission-scheme-audit
# Guide Step 1: inventory every scheme and the spaces using it, then flag
#   - any grant to Public (holder type anyone)
#   - Browse spaces, or a destructive grant, given to a whole application population
#   - any grant to a single named user instead of a space role or group
audit() {
  require_admin
  jira_get "/rest/api/3/permissionscheme?expand=permissions"
  cp "${BODY}" "${WORK}/schemes.json"
  local total
  total=$(jq '(.permissionSchemes // []) | length' "${WORK}/schemes.json")
  if [ "${total}" -eq 0 ]; then
    echo "PRECONDITION: zero permission schemes returned - Free sites have none (guide Appendix A); nothing was audited" >&2
    exit 2
  fi
  jq -e '[.permissionSchemes[] | has("permissions")] | all' "${WORK}/schemes.json" >/dev/null 2>&1 \
    || { echo "PRECONDITION: schemes came back without their grants (expand=permissions not honoured)" >&2; exit 2; }
  map_spaces_to_schemes

  echo "Jira Cloud 1.1 - permission scheme least-privilege audit"
  echo "  permission schemes: ${total}"
  echo "  company-managed spaces: $(jq 'length' "${WORK}/map.json")"
  echo "  team-managed spaces (not governed by schemes): $(jq '[.[] | select(.style != "classic")] | length' "${WORK}/projects.json")"

  jq --slurpfile map "${WORK}/map.json" '
    ["ADMINISTER_PROJECTS", "DELETE_ISSUES", "DELETE_ALL_COMMENTS"] as $destructive
    | ($map[0] | group_by(.scheme) | map({key: .[0].scheme, value: map(.space)}) | from_entries) as $spaces
    | [ .permissionSchemes[] as $s
        | ($spaces[($s.id | tostring)] // []) as $sp
        | (if ($sp | length) == 0 then "no company-managed space" else ($sp | join(", ")) end) as $where
        | $s.permissions[] as $g
        | ($g.holder.type // "unknown") as $t
        | if $t == "anyone" then
            "FINDING: \"\($s.name)\" grants \($g.permission) to Public (holder type anyone) - spaces: \($where)"
          elif $t == "applicationRole" and ($g.permission == "BROWSE_PROJECTS" or ($destructive | any(. == $g.permission))) then
            "FINDING: \"\($s.name)\" grants \($g.permission) to applicationRole \($g.holder.parameter // "(no application named)") - every user with that product access - spaces: \($where)"
          elif $t == "user" then
            "FINDING: \"\($s.name)\" grants \($g.permission) to a single user (...\(($g.holder.value // $g.holder.parameter // "") | .[-6:])) - grant through a space role or group instead - spaces: \($where)"
          else empty end ]' "${WORK}/schemes.json" > "${WORK}/findings.json"

  jq -r --slurpfile map "${WORK}/map.json" '
    ($map[0] | map(.scheme)) as $used
    | .permissionSchemes[]
    | (.id | tostring) as $id
    | "  - \"\(.name)\" (id \($id)): \(.permissions | length) grants, \([$used[] | select(. == $id)] | length) spaces"' \
    "${WORK}/schemes.json"
  jq -r '.[]' "${WORK}/findings.json"

  local n
  n=$(jq 'length' "${WORK}/findings.json")
  if [ "${n}" -gt 0 ]; then
    echo "${n} finding(s). Fix in Settings > Work items > Permission schemes (guide Steps 2-4)."
    return 1
  fi
  echo "COMPLIANT: no Public, application-wide Browse/destructive, or single-user grants in ${total} scheme(s)."
}
# HTH Guide Excerpt: end permission-scheme-audit

audit
