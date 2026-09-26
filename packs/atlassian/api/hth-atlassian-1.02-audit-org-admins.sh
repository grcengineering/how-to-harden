#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: atlassian-1.2
#   guide:   https://howtoharden.com/guides/atlassian/#12-implement-granular-product-access-and-limit-organization-admins
#   profile: L1
#   mode:    read-only
#   requires: ORG_ID(organization id), ATLASSIAN_ORG_API_KEY(Organization API key, scope read:directories:admin), ATLASSIAN_SITE_URL+ATLASSIAN_EMAIL+ATLASSIAN_API_TOKEN(optional: Confluence anonymous-access check)
# =============================================================================
# HTH Atlassian Control 1.2: Limit Organization Admins (+ Confluence anonymous access)
# Profile Level: L1 (Crawl) | NIST 800-53: AC-6(1)
# Sources: https://developer.atlassian.com/cloud/admin/organization/rest/
#            GET /v2/orgs/{orgId}/directories/{directoryId}/users (roleIds=atlassian/org-admin)
#          https://developer.atlassian.com/cloud/confluence/rest/v2/
#            GET /spaces ; GET /spaces/{id}/role-assignments
#            (principal-type=ACCESS_CLASS, principal-id=anonymous-users)
# Dependencies: bash 3.2+, curl 7.55+ (-H @file), jq, base64
#
#  - Part 1 counts ACTIVE accounts holding atlassian/org-admin and fails above
#    MAX_ORG_ADMINS (default 3; the guide's "two or three dedicated accounts").
#    Zero admins is reported as "could not audit": an org always has one, so a
#    zero means the filter or the key's scope did not apply.
#  - Part 2 runs only when ATLASSIAN_SITE_URL is set. It asks every current
#    Confluence space whether the anonymous-users access class holds a role.
#    That endpoint is "available on tenants with Role-Based Access Control";
#    on other tenants it returns an error and this pack exits 2 rather than
#    reporting the space as closed.
#  - The users GET is deprecated after June 30, 2027 (replacement: POST
#    .../users/search, which documents no scope). Kept for its least-privilege scope.
#
# Exit codes: 0 no finding | 1 finding | 2 could not audit | 3 partial (page cap)
#             any other non-zero: a response that was not the documented JSON (never read as clean)
# =============================================================================
set -euo pipefail

: "${ORG_ID:?set ORG_ID}"
: "${ATLASSIAN_ORG_API_KEY:?set ATLASSIAN_ORG_API_KEY (Organization API key, scope read:directories:admin)}"
API="${ATLASSIAN_API_BASE:-https://api.atlassian.com}"
MAX_ORG_ADMINS="${MAX_ORG_ADMINS:-3}"
MAX_PAGES="${MAX_PAGES:-50}"
command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

# HTH Guide Excerpt: begin api-audit-org-admins
# $1 = base URL, $2 = path+query, $3 = Authorization header value (built
# inside the process substitution, so no secret ever reaches argv).
http_get() {
  local resp code
  resp=$(curl -sS --max-time 60 -w '\n%{http_code}' -H @<(printf 'Authorization: %s\n' "$3") \
    -H 'Accept: application/json' "$1$2") || { echo "ERROR: GET ${2%%\?*} failed in transport" >&2; return 2; }
  code=${resp##*$'\n'}
  [ "$code" = "200" ] || { echo "ERROR: GET ${2%%\?*} -> HTTP ${code}" >&2; return 2; }
  printf '%s\n' "${resp%$'\n'*}"
}
org_get()  { http_get "$API" "$1" "Bearer ${ATLASSIAN_ORG_API_KEY}"; }
site_get() { http_get "$ATLASSIAN_SITE_URL" "$1" \
  "Basic $(printf '%s:%s' "$ATLASSIAN_EMAIL" "$ATLASSIAN_API_TOKEN" | base64 | tr -d '\n')"; }

rc=0

# Part 1: org admins. links.next on this resource is a cursor value.
admins=''; cursor=''; pages=0
while :; do
  page=$(org_get "/admin/v2/orgs/${ORG_ID}/directories/-/users?limit=100&roleIds=atlassian/org-admin&status=active${cursor:+&cursor=$(jq -rn --arg v "$cursor" '$v|@uri')}")
  # A page without a data array stops the audit (jq error); it never counts as 0 admins.
  admins="${admins}$(printf '%s' "$page" | jq -r 'if (.data | type) == "array" then .data[] | (.accountId // error("user without accountId")) else error("no data array") end')"$'\n'
  cursor=$(printf '%s' "$page" | jq -r '.links.next // empty')
  [ -z "$cursor" ] && break
  pages=$((pages + 1)); [ "$pages" -lt "$MAX_PAGES" ] || { echo "ERROR: MAX_PAGES reached; admin list is partial" >&2; exit 3; }
done
n_admins=$(printf '%s' "$admins" | grep -c . || true)
[ "$n_admins" -gt 0 ] || { echo "ERROR: 0 active org admins returned; the roleIds filter or key scope did not apply" >&2; exit 2; }
echo "active organization admins: ${n_admins} (limit ${MAX_ORG_ADMINS})"
printf '%s' "$admins" | grep . | sed 's/^/  accountId=/'
if [ "$n_admins" -gt "$MAX_ORG_ADMINS" ]; then
  echo "FINDING: more org admins than MAX_ORG_ADMINS; move product-only admins to product admin roles"; rc=1
fi

# Part 2 (optional): Confluence spaces where anonymous users hold a role.
if [ -n "${ATLASSIAN_SITE_URL:-}" ]; then
  : "${ATLASSIAN_EMAIL:?set ATLASSIAN_EMAIL for the Confluence check}"
  : "${ATLASSIAN_API_TOKEN:?set ATLASSIAN_API_TOKEN for the Confluence check}"
  spaces=''; cursor=''; pages=0
  while :; do
    page=$(site_get "/wiki/api/v2/spaces?status=current&limit=250${cursor:+&cursor=${cursor}}")
    spaces="${spaces}$(printf '%s' "$page" | jq -r 'if (.results | type) == "array" then .results[] | "\(.id) \(.key)" else error("no results array") end')"$'\n'
    next=$(printf '%s' "$page" | jq -r '._links.next // empty')
    [ -z "$next" ] && break
    cursor=$(printf '%s' "$next" | sed -n 's/.*[?&]cursor=\([^&]*\).*/\1/p')
    [ -n "$cursor" ] || { echo "ERROR: _links.next carries no cursor; space list is partial" >&2; exit 3; }
    pages=$((pages + 1)); [ "$pages" -lt "$MAX_PAGES" ] || { echo "ERROR: MAX_PAGES reached; space list is partial" >&2; exit 3; }
  done
  n_spaces=$(printf '%s' "$spaces" | grep -c . || true)
  [ "$n_spaces" -gt 0 ] || { echo "ERROR: 0 current spaces visible to this account; nothing was audited" >&2; exit 2; }
  open_spaces=''
  while read -r sid skey; do
    [ -n "$sid" ] || continue
    ra=$(site_get "/wiki/api/v2/spaces/${sid}/role-assignments?principal-type=ACCESS_CLASS&principal-id=anonymous-users")
    # An unexpected shape is an error (jq -e), never an implicit "0 assignments".
    n_anon=$(printf '%s' "$ra" | jq -e '.results | if type == "array" then length else error("no results array") end')
    [ "$n_anon" -eq 0 ] || open_spaces="${open_spaces}  ${skey}"$'\n'
  done < <(printf '%s' "$spaces")
  echo "confluence spaces checked for anonymous access: ${n_spaces}"
  if [ -n "$open_spaces" ]; then
    echo "FINDING: anonymous users hold a role in these spaces:"; printf '%s' "$open_spaces"; rc=1
  fi
else
  echo "NOT CHECKED: Confluence anonymous access (set ATLASSIAN_SITE_URL, ATLASSIAN_EMAIL, ATLASSIAN_API_TOKEN)" >&2
fi

exit "$rc"
# HTH Guide Excerpt: end api-audit-org-admins
