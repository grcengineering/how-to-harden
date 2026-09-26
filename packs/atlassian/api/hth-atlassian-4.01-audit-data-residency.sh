#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: atlassian-4.1
#   guide:   https://howtoharden.com/guides/atlassian/#41-configure-data-residency
#   profile: L2
#   mode:    read-only
#   requires: ORG_ID(organization id), ATLASSIAN_ORG_API_KEY(Organization API key with scopes, read:policies:admin only), EXPECTED_REALM(optional)
# =============================================================================
# HTH Atlassian Control 4.1: Configure Data Residency — policy audit
# Profile Level: L2 (Walk) | NIST 800-53: SC-28
# Source: https://developer.atlassian.com/cloud/admin/control/rest/  (Admin Control API)
#         GET /admin/control/v1/orgs/{orgId}/policies?type=data-residency
#         GET /admin/control/v1/orgs/{orgId}/policies/{policyId}/resources
#         (scope read:policies:admin; DataResidencyPolicyAttributes: name, status,
#         rule.in[]; PolicyResource.applicationStatus)
# Dependencies: bash 3.2+, curl 7.55+ (-H @file), jq
#
#  - Findings: no ENABLED data-residency policy; a covered resource whose
#    applicationStatus is "failed"; and, when EXPECTED_REALM is set, an enabled
#    policy whose rule.in does not contain that realm (compared case-insensitively,
#    and the observed value is printed so you can confirm the realm spelling).
#  - Moving a product between realms is a scheduled migration. This pack never
#    creates or edits a policy.
#
# Exit codes: 0 no finding | 1 finding | 2 could not audit | 3 partial (page cap, or a next page this pack cannot follow)
#             any other non-zero: a response that was not the documented JSON (never read as clean)
# =============================================================================
set -euo pipefail

: "${ORG_ID:?set ORG_ID}"
: "${ATLASSIAN_ORG_API_KEY:?set ATLASSIAN_ORG_API_KEY (Organization API key, scope read:policies:admin)}"
API="${ATLASSIAN_API_BASE:-https://api.atlassian.com}"
EXPECTED_REALM="${EXPECTED_REALM:-}"
MAX_PAGES="${MAX_PAGES:-20}"
command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

# HTH Guide Excerpt: begin api-audit-data-residency
api_get() {  # key in a process-substitution header file, never in argv; non-200 -> 2
  local resp code
  resp=$(curl -sS --max-time 60 -w '\n%{http_code}' \
    -H @<(printf 'Authorization: Bearer %s\n' "$ATLASSIAN_ORG_API_KEY") \
    -H 'Accept: application/json' "${API}$1") || { echo "ERROR: GET ${1%%\?*} failed in transport" >&2; return 2; }
  code=${resp##*$'\n'}
  [ "$code" = "200" ] || { echo "ERROR: GET ${1%%\?*} -> HTTP ${code} (403 = access forbidden: check the key carries read:policies:admin)" >&2; return 2; }
  printf '%s\n' "${resp%$'\n'*}"
}
BASE="/admin/control/v1/orgs/${ORG_ID}/policies"

# Resources of one policy. Models.PolicyResourcePage is paged (meta.next, links.next),
# but this GET documents no cursor parameter, so a next page is fetched only through
# the links.next URL the API returns, and only on this API base (the key never leaves
# it). A next page that cannot be followed makes the list partial (exit 3): a failed
# application on an unread page must never read as "no finding".
policy_resources() {  # $1 = policy id; prints a JSON array of {id, applicationStatus}
  local path="${BASE}/$1/resources" acc='[]' pg nx mn p=0
  while :; do
    pg=$(api_get "$path") || return 2
    acc=$(printf '%s' "$pg" | jq -ce --argjson acc "$acc" 'if (.data | type) == "array" then $acc + [.data[] | {id, applicationStatus}] else error("no data array") end') || return 5
    nx=$(printf '%s' "$pg" | jq -r '.links.next // empty') || return 5
    mn=$(printf '%s' "$pg" | jq -r '.meta.next // empty') || return 5
    if [ -z "$nx" ] && [ -z "$mn" ]; then printf '%s\n' "$acc"; return 0; fi
    case "$nx" in
      "${API}"/admin/control/*) path="${nx#"$API"}" ;;
      /admin/control/*)         path="$nx" ;;
      *) echo "ERROR: resources of policy $1 continue on a page this pack cannot follow; list is partial" >&2; return 3 ;;
    esac
    p=$((p + 1)); [ "$p" -lt "$MAX_PAGES" ] || { echo "ERROR: MAX_PAGES reached; resources of policy $1 are partial" >&2; return 3; }
  done
}

policies='[]'; cursor=''; pages=0
while :; do
  page=$(api_get "${BASE}?type=data-residency${cursor:+&cursor=$(jq -rn --arg v "$cursor" '$v|@uri')}")
  policies=$(printf '%s' "$page" | jq -ce --argjson acc "$policies" 'if (.data | type) == "array" then $acc + .data else error("no data array") end')
  cursor=$(printf '%s' "$page" | jq -r '.meta.next // empty')
  [ -z "$cursor" ] && break
  pages=$((pages + 1)); [ "$pages" -lt "$MAX_PAGES" ] || { echo "ERROR: MAX_PAGES reached; policy list is partial" >&2; exit 3; }
done

n=$(printf '%s' "$policies" | jq 'length'); i=0
while [ "$i" -lt "$n" ]; do
  pid=$(printf '%s' "$policies" | jq -r --argjson i "$i" '.[$i].id')
  st=$(policy_resources "$pid")
  policies=$(printf '%s' "$policies" | jq -c --argjson i "$i" --argjson s "$st" '.[$i].appliedTo = $s')
  i=$((i + 1))
done

printf '%s' "$policies" | jq -r '.[] | "  \(.attributes.name // .id): status=\(.attributes.status // "unknown") realm=\(.attributes.rule.in // [] | join(",")) resources=\(.appliedTo | map(.applicationStatus) | group_by(.) | map("\(.[0])=\(length)") | join(","))"'
findings=$(printf '%s' "$policies" | jq -r --arg want "$EXPECTED_REALM" '
  (if ([.[] | select(.attributes.status == "enabled")] | length) == 0
     then "no enabled data-residency policy: no product is pinned to a realm" else empty end),
  (if $want == "" then empty else
     (.[] | select(.attributes.status == "enabled")
          | select((.attributes.rule.in // []) | map(ascii_downcase) | index($want | ascii_downcase) | not)
          | "\(.attributes.name // .id): realm \(.attributes.rule.in // [] | join(",")) is not \($want)") end),
  (.[] | . as $p | .appliedTo[] | select(.applicationStatus == "failed")
       | "\($p.attributes.name // $p.id): realm move failed on resource \(.id)")')
echo "data-residency policies: ${n}${EXPECTED_REALM:+; expected realm: ${EXPECTED_REALM}}"
if [ -n "$findings" ]; then
  echo "FINDING:"; printf '%s\n' "$findings" | sed 's/^/  /'; exit 1
fi
exit 0
# HTH Guide Excerpt: end api-audit-data-residency
