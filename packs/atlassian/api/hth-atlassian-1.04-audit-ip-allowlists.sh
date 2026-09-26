#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: atlassian-1.4
#   guide:   https://howtoharden.com/guides/atlassian/#14-restrict-product-access-with-ip-allowlisting
#   profile: L3
#   mode:    read-only
#   requires: ORG_ID(organization id), ATLASSIAN_ORG_API_KEY(Organization API key with scopes, read:policies:admin only)
# =============================================================================
# HTH Atlassian Control 1.4: Restrict Product Access with IP Allowlisting — audit
# Profile Level: L3 (Run) | NIST 800-53: AC-3, AC-17, SC-7
# Source: https://developer.atlassian.com/cloud/admin/control/rest/  (Admin Control API)
#         GET /admin/control/v1/orgs/{orgId}/policies?type=ip-allowlist
#         GET /admin/control/v1/orgs/{orgId}/policies/{policyId}/resources
#         (scope read:policies:admin; IPAllowListPolicyAttributes: name, status,
#         rule.in[], rule.allowMobileBypass; PolicyResource.applicationStatus)
# Dependencies: bash 3.2+, curl 7.55+ (-H @file), jq
#
#  - Findings: no ENABLED ip-allowlist policy; an enabled policy whose rule
#    admits every address (0.0.0.0/0 or ::/0); a covered resource whose
#    applicationStatus is "failed".
#  - Review: an enabled policy with rule.allowMobileBypass=true. The field is in
#    the reference schema without a description, so it is surfaced, not judged.
#  - Deliberately NOT called: .../policies/{policyId}/validate. The Organizations
#    REST reference documents that GET as queueing a DNS-validation task (202),
#    so it is not a plain read. This pack never creates or edits an allowlist,
#    because an allowlist change can lock administrators out.
#
# Exit codes: 0 no finding | 1 finding | 2 could not audit | 3 partial (page cap, or a next page this pack cannot follow)
#             any other non-zero: a response that was not the documented JSON (never read as clean)
# =============================================================================
set -euo pipefail

: "${ORG_ID:?set ORG_ID}"
: "${ATLASSIAN_ORG_API_KEY:?set ATLASSIAN_ORG_API_KEY (Organization API key, scope read:policies:admin)}"
API="${ATLASSIAN_API_BASE:-https://api.atlassian.com}"
MAX_PAGES="${MAX_PAGES:-20}"
command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

# HTH Guide Excerpt: begin api-audit-ip-allowlists
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

# 1. Policies of this type; meta.next is a cursor value.
policies='[]'; cursor=''; pages=0
while :; do
  page=$(api_get "${BASE}?type=ip-allowlist${cursor:+&cursor=$(jq -rn --arg v "$cursor" '$v|@uri')}")
  policies=$(printf '%s' "$page" | jq -ce --argjson acc "$policies" 'if (.data | type) == "array" then $acc + .data else error("no data array") end')
  cursor=$(printf '%s' "$page" | jq -r '.meta.next // empty')
  [ -z "$cursor" ] && break
  pages=$((pages + 1)); [ "$pages" -lt "$MAX_PAGES" ] || { echo "ERROR: MAX_PAGES reached; policy list is partial" >&2; exit 3; }
done

# 2. Where each policy has been applied (a separate resource in this API).
n=$(printf '%s' "$policies" | jq 'length'); i=0
while [ "$i" -lt "$n" ]; do
  pid=$(printf '%s' "$policies" | jq -r --argjson i "$i" '.[$i].id')
  st=$(policy_resources "$pid")
  policies=$(printf '%s' "$policies" | jq -c --argjson i "$i" --argjson s "$st" '.[$i].appliedTo = $s')
  i=$((i + 1))
done

printf '%s' "$policies" | jq -r '.[] | "  \(.attributes.name // .id): status=\(.attributes.status // "unknown") ranges=\(.attributes.rule.in // [] | length) mobileBypass=\(.attributes.rule.allowMobileBypass | if . == null then "unset" else tostring end) resources=\(.appliedTo | map(.applicationStatus) | group_by(.) | map("\(.[0])=\(length)") | join(","))"'
findings=$(printf '%s' "$policies" | jq -r '
  (if ([.[] | select(.attributes.status == "enabled")] | length) == 0
     then "no enabled ip-allowlist policy: product access is not restricted by source IP" else empty end),
  (.[] | select(.attributes.status == "enabled")
       | select((.attributes.rule.in // []) | any(. == "0.0.0.0/0" or . == "::/0"))
       | "\(.attributes.name // .id): enabled rule admits every address"),
  (.[] | . as $p | .appliedTo[] | select(.applicationStatus == "failed")
       | "\($p.attributes.name // $p.id): application failed on resource \(.id)")')
review=$(printf '%s' "$policies" | jq -r '.[] | select(.attributes.status == "enabled" and .attributes.rule.allowMobileBypass == true)
  | "\(.attributes.name // .id): allowMobileBypass=true, confirm mobile apps are meant to bypass this allowlist"')
echo "ip-allowlist policies: ${n}"
[ -z "$review" ] || { echo "REVIEW:"; printf '%s\n' "$review" | sed 's/^/  /'; }
if [ -n "$findings" ]; then
  echo "FINDING:"; printf '%s\n' "$findings" | sed 's/^/  /'; exit 1
fi
exit 0
# HTH Guide Excerpt: end api-audit-ip-allowlists
