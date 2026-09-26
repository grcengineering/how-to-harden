#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: atlassian-1.1
#   guide:   https://howtoharden.com/guides/atlassian/#11-enforce-sso-with-mfa
#   profile: L1
#   mode:    read-only
#   requires: ORG_ID(organization id from admin.atlassian.com/o/<orgId>/), ATLASSIAN_ORG_API_KEY(Organization API key with scopes read:domains:admin + read:directories:admin)
# =============================================================================
# HTH Atlassian Control 1.1: Enforce SSO with MFA — domain and two-step audit
# Profile Level: L1 (Crawl) | NIST 800-53: IA-2(1)
# Source: https://developer.atlassian.com/cloud/admin/organization/rest/
#         (GET /v1/orgs/{orgId}/domains; GET /v2/orgs/{orgId}/directories/{directoryId}/users)
# Dependencies: bash 3.2+, curl 7.55+ (-H @file), jq
#
# What this proves, and what it cannot:
#  - Every domain the organization holds is VERIFIED (attributes.claim.status).
#    An unverified domain leaves its accounts unmanaged, outside every
#    authentication policy.
#  - Which active MANAGED accounts have no Atlassian two-step verification
#    (mfaEnabled=false). Accounts that sign in through an SSO-enforced
#    authentication policy get MFA from the IdP and can legitimately read false
#    here, so reconcile this list against the policy's members; do not auto-act on it.
#  - How many active UNMANAGED accounts exist (review: guests, or shadow accounts).
#  - SAML configuration and authentication policy settings have no resource in
#    any cloud admin REST API (https://developer.atlassian.com/cloud/admin/rest-apis/);
#    the Admin Control API only adds users to an existing policy and reports each
#    user's policyId. So "SSO is enforced" can only be proven in the console.
#
# Deprecation: GET /v2/orgs/{orgId}/directories/{directoryId}/users is marked
# "will no longer work after June 30, 2027" in the reference; its replacement,
# POST .../users/search, documents no scope. The GET is kept because it is the
# handle with a documented least-privilege scope (read:directories:admin).
#
# Exit codes: 0 no finding | 1 finding | 2 could not audit (HTTP/transport/precondition) | 3 partial (page cap)
#             any other non-zero: a response that was not the documented JSON (never read as clean)
# =============================================================================
set -euo pipefail

: "${ORG_ID:?set ORG_ID (organization id from admin.atlassian.com/o/<orgId>/)}"
: "${ATLASSIAN_ORG_API_KEY:?set ATLASSIAN_ORG_API_KEY (Organization API key, scopes read:domains:admin read:directories:admin)}"
API="${ATLASSIAN_API_BASE:-https://api.atlassian.com}"
MAX_PAGES="${MAX_PAGES:-50}"
command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

# HTH Guide Excerpt: begin api-audit-domains-and-2sv
# GET with the key in a process-substitution header file (never in argv).
# Any non-200 is "could not audit", never "no finding".
api_get() {
  local resp code
  resp=$(curl -sS --max-time 60 -w '\n%{http_code}' \
    -H @<(printf 'Authorization: Bearer %s\n' "$ATLASSIAN_ORG_API_KEY") \
    -H 'Accept: application/json' "${API}$1") || { echo "ERROR: GET ${1%%\?*} failed in transport" >&2; return 2; }
  code=${resp##*$'\n'}
  [ "$code" = "200" ] || { echo "ERROR: GET ${1%%\?*} -> HTTP ${code}" >&2; return 2; }
  printf '%s\n' "${resp%$'\n'*}"
}
# jq always reads through a pipe. No here-strings: a here-string needs a temp
# file, and if that cannot be created the audit would read "no data" as clean.

rc=0

# 1. Domains. links.next is a URL; its cursor= value feeds the documented cursor param.
domains='[]'; cursor=''; pages=0
while :; do
  page=$(api_get "/admin/v1/orgs/${ORG_ID}/domains${cursor:+?cursor=${cursor}}")
  domains=$(printf '%s' "$page" | jq -ce --argjson acc "$domains" 'if (.data | type) == "array" then $acc + .data else error("no data array") end')
  next=$(printf '%s' "$page" | jq -r '.links.next // empty')
  [ -z "$next" ] && break
  cursor=$(printf '%s' "$next" | sed -n 's/.*[?&]cursor=\([^&]*\).*/\1/p')
  [ -n "$cursor" ] || { echo "ERROR: links.next carries no cursor; domain list is partial" >&2; exit 3; }
  pages=$((pages + 1)); [ "$pages" -lt "$MAX_PAGES" ] || { echo "ERROR: MAX_PAGES reached; domain list is partial" >&2; exit 3; }
done
n_dom=$(printf '%s' "$domains" | jq 'length')
[ "$n_dom" -gt 0 ] || { echo "ERROR: the organization returned 0 domains; nothing to evaluate (verify a domain first)" >&2; exit 2; }
unverified=$(printf '%s' "$domains" | jq -r '.[] | select((.attributes.claim.status // "missing") != "verified")
                    | "  \(.attributes.name // .id)  claim.status=\(.attributes.claim.status // "missing")"')
echo "domains: ${n_dom}"
if [ -n "$unverified" ]; then
  echo "FINDING: domains not in claim.status=verified (their accounts sit outside authentication policies):"
  printf '%s\n' "$unverified"; rc=1
fi

# 2. Directory users (directoryId '-' = every directory). links.next is a cursor
#    value. $1 = filter query string; prints one accountId per line. A page
#    without a data array is "could not audit": it must never count as 0 users.
list_users() {
  local q="$1" c='' p=0 pg nx
  while :; do
    pg=$(api_get "/admin/v2/orgs/${ORG_ID}/directories/-/users?limit=100&${q}${c:+&cursor=$(jq -rn --arg v "$c" '$v|@uri')}") || return 2
    printf '%s' "$pg" | jq -r 'if (.data | type) == "array" then .data[] | (.accountId // error("user without accountId")) else error("no data array") end' \
      || { echo "ERROR: users response was not the documented JSON; nothing was audited" >&2; return 2; }
    nx=$(printf '%s' "$pg" | jq -r '.links.next // empty') || return 2
    [ -z "$nx" ] && return 0
    c="$nx"; p=$((p + 1)); [ "$p" -lt "$MAX_PAGES" ] || { echo "ERROR: MAX_PAGES reached; user list is partial" >&2; return 3; }
  done
}

no2sv=$(list_users 'claimStatus=managed&mfaEnabled=false&status=active')
n_no2sv=$(printf '%s' "$no2sv" | grep -c . || true)
echo "active managed accounts without two-step verification: ${n_no2sv}"
if [ "$n_no2sv" -gt 0 ]; then
  echo "FINDING: reconcile these against your SSO-enforced authentication policy members:"
  printf '%s\n' "$no2sv" | sed 's/^/  accountId=/'; rc=1
fi

unmanaged=$(list_users 'claimStatus=unmanaged&status=active')
n_unmanaged=$(printf '%s' "$unmanaged" | grep -c . || true)
echo "REVIEW: active unmanaged accounts (guests, or accounts on a domain you have not claimed): ${n_unmanaged}"

exit "$rc"
# HTH Guide Excerpt: end api-audit-domains-and-2sv
