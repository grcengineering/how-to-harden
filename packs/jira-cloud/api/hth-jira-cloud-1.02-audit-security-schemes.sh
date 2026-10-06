#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: jira-cloud-1.2
#   guide:   https://howtoharden.com/guides/jira-cloud/#12-restrict-sensitive-work-items-with-security-schemes
#   profile: L2
#   mode:    read-only
#   requires: JIRA_EMAIL, JIRA_API_TOKEN(API token with the granular read scopes listed below; owner must hold Administer Jira), JIRA_CLOUD_ID or JIRA_API_BASE
# =============================================================================
# HTH Jira Cloud Control 1.2: Restrict Sensitive Work Items with Security Schemes
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 3.3, 3.12 | NIST 800-53 AC-3, AC-4, AC-21 | ISO 27001:2022 A.5.12, A.8.3
# Source: https://howtoharden.com/guides/jira-cloud/#12-restrict-sensitive-work-items-with-security-schemes
# Dependencies: bash (3.2+), curl, jq
#
# READ-ONLY. Every call is a GET against the Jira Cloud REST API v3, transcribed
# from the vendor's OpenAPI spec
# (https://developer.atlassian.com/cloud/jira/platform/swagger-v3.v3.json):
#   GET /rest/api/3/mypermissions?permissions=ADMINISTER
#   GET /rest/api/3/issuesecurityschemes/search            (paged; defaultLevel per scheme)
#   GET /rest/api/3/issuesecurityschemes/level             (paged; levels per scheme)
#   GET /rest/api/3/project/search                         (paged)
#   GET /rest/api/3/issuesecurityschemes/search?projectId= (the scheme a space uses)
# Security schemes apply only to company-managed ("classic") spaces; the spec
# says each of these endpoints returns "only issue security schemes in the
# context of classic projects". The API also creates schemes and levels, sets
# the default level and associates schemes with spaces; this pack only reads.
#
# CREDENTIALS. Use an API token *with scopes*, called through
# https://api.atlassian.com/ex/jira/{cloudId} (cloud ID from
# https://<site>.atlassian.net/_edge/tenant_info). The spec's classic OAuth
# scope for the scheme GETs is write-capable (manage:jira-configuration), so
# grant the granular read scopes instead (marked "Beta" in the spec):
#   read:issue-security-scheme:jira read:issue-security-level:jira
#   read:permission:jira read:project:jira read:project-category:jira
#   read:project-version:jira read:project.component:jira
#   read:project.property:jira read:issue-type:jira read:issue-type-hierarchy:jira
#   read:application-role:jira read:group:jira read:user:jira read:avatar:jira
# A token without scopes works with JIRA_API_BASE=https://<site>.atlassian.net.
# The endpoints require *Administer Jira*; the pack checks this first.
#
# WHAT IS A FINDING. No scheme at all (the control is not implemented); a scheme
# with no levels (it cannot restrict anything); a scheme with no default level
# (unclassified items are created fully visible - guide Rationale). Spaces with
# no scheme are listed for the guide's Step 5 move-gap review, not scored: only
# you know which spaces restricted items can be moved into.
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

WORK="$(mktemp -d "${TMPDIR:-/tmp}/hth-jira-cloud-102.XXXXXX")" \
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



# Writes [{scheme, space}] for company-managed spaces that use a security scheme,
# and the list of all company-managed space keys, to $WORK.
map_spaces_to_security_schemes() {
  jira_pages "/rest/api/3/project/search" "${WORK}/projects.json" allow404
  jq '[.[] | select(.style == "classic") | .key]' "${WORK}/projects.json" > "${WORK}/classic.json"
  local expected seen=0 pid pkey
  expected=$(jq 'length' "${WORK}/classic.json")
  : > "${WORK}/map.jsonl"
  while IFS="$(printf '\t')" read -r pid pkey; do
    case "${pid}" in ''|*[!0-9]*) echo "PRECONDITION: project/search returned a non-numeric project id" >&2; exit 2 ;; esac
    jira_pages "/rest/api/3/issuesecurityschemes/search?projectId=${pid}" "${WORK}/one.json"
    jq -c --arg k "${pkey}" '.[] | {scheme: (.id | tostring), space: $k}' "${WORK}/one.json" >> "${WORK}/map.jsonl"
    seen=$((seen + 1))
  done < <(jq -r '.[] | select(.style == "classic") | [.id, .key] | @tsv' "${WORK}/projects.json")
  jq -s '.' "${WORK}/map.jsonl" > "${WORK}/map.json"
  if [ "${seen}" -ne "${expected}" ]; then
    echo "PRECONDITION: checked ${seen} of ${expected} company-managed spaces" >&2; exit 2
  fi
}

# HTH Guide Excerpt: begin security-scheme-audit
# Guide Steps 1-2: a scheme exists, has levels, and has a DEFAULT level.
# Guide Step 5: list the company-managed spaces with no scheme (move-gap review).
audit() {
  require_admin
  jira_pages "/rest/api/3/issuesecurityschemes/search" "${WORK}/schemes.json"
  jira_pages "/rest/api/3/issuesecurityschemes/level" "${WORK}/levels.json"
  map_spaces_to_security_schemes

  echo "Jira Cloud 1.2 - work item security scheme audit"
  echo "  security schemes: $(jq 'length' "${WORK}/schemes.json")"
  echo "  company-managed spaces: $(jq 'length' "${WORK}/classic.json"); using a scheme: $(jq '[.[].space] | unique | length' "${WORK}/map.json")"

  jq --slurpfile levels "${WORK}/levels.json" --slurpfile map "${WORK}/map.json" --slurpfile classic "${WORK}/classic.json" '
    ($map[0] | map(.space) | unique) as $covered
    | if length == 0 then
        ["FINDING: no work item security scheme exists - every item in a space is visible to everyone who can browse it (guide Step 1; unavailable on Free sites)"]
      else
        [ .[]
          | (.id | tostring) as $id
          | ([$levels[0][] | select((.issueSecuritySchemeId | tostring) == $id)]) as $lv
          | ([$map[0][] | select(.scheme == $id) | .space]) as $sp
          | "  - \"\(.name)\" (id \($id)): \($lv | length) level(s), default \((first($lv[] | select(.isDefault == true) | .name) // "none")), spaces: \(if ($sp | length) == 0 then "none" else ($sp | join(", ")) end)",
            (if ($lv | length) == 0 then "FINDING: \"\(.name)\" has no security levels - it cannot restrict anything (Step 2)" else empty end),
            (if .defaultLevel == null and ($lv | any(.isDefault == true)) == false
             then "FINDING: \"\(.name)\" has no default level - items created without a choice are fully visible (Step 2.3)" else empty end)
        ]
      end
    + [ $classic[0][] | select(. as $k | $covered | index($k) | not)
        | "REVIEW: space \(.) has no security scheme - a restricted item moved here becomes visible to anyone with access to the space (Step 5)" ]' \
    "${WORK}/schemes.json" > "${WORK}/lines.json"

  jq -r '.[]' "${WORK}/lines.json"
  local n
  n=$(jq '[.[] | select(startswith("FINDING"))] | length' "${WORK}/lines.json")
  if [ "${n}" -gt 0 ]; then
    echo "${n} finding(s). Fix in Settings > Work items > Work item security schemes (guide Steps 1-2)."
    return 1
  fi
  echo "COMPLIANT: every security scheme has levels and a default level."
}
# HTH Guide Excerpt: end security-scheme-audit

audit
