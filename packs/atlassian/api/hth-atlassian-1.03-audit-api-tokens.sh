#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: atlassian-1.3
#   guide:   https://howtoharden.com/guides/atlassian/#13-configure-api-token-policies
#   profile: L1
#   mode:    read-only
#   requires: ORG_ID(organization id), ATLASSIAN_ORG_API_KEY(Organization API key with scopes, read:tokens:admin only)
# =============================================================================
# HTH Atlassian Control 1.3: Configure API Token Policies — token expiry audit
# Profile Level: L1 (Crawl) | NIST 800-53: IA-5
# Source: https://developer.atlassian.com/cloud/admin/api-access/rest/
#         GET /admin/api-access/v1/orgs/{orgId}/api-tokens  (scope read:tokens:admin;
#         ApiToken: id, label, status ALLOWED|BLOCKED, createdAt, expiresAt,
#         lastActiveAt, user; links.next is a cursor, other params repeat alongside it)
# Dependencies: bash 3.2+, curl 7.55+ (-H @file), jq
#
#  - Lists every user API token in the organization and flags an ALLOWED token
#    with NO expiry, an expiry later than MAX_TOKEN_DAYS from now (default 90,
#    the guide's organizational standard, well inside the platform's 1-year
#    ceiling), or an expiry this pack cannot parse (never read as compliant).
#  - Any non-200 exits 2; it is never read as "no tokens". The reference
#    documents a 403 only as missing permission to read user API tokens.
#  - The "Allow users to create API tokens" setting has no resource in any of
#    the six admin REST APIs; it is console-only. This pack proves token
#    hygiene, not that setting. Reads only: it never calls the bulk-revoke DELETE.
#
# Exit codes: 0 no finding | 1 finding | 2 could not audit | 3 partial (page cap)
#             any other non-zero: a response that was not the documented JSON (never read as clean)
# =============================================================================
set -euo pipefail

: "${ORG_ID:?set ORG_ID}"
: "${ATLASSIAN_ORG_API_KEY:?set ATLASSIAN_ORG_API_KEY (Organization API key, scope read:tokens:admin)}"
API="${ATLASSIAN_API_BASE:-https://api.atlassian.com}"
MAX_TOKEN_DAYS="${MAX_TOKEN_DAYS:-90}"
MAX_PAGES="${MAX_PAGES:-50}"
command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

# HTH Guide Excerpt: begin api-audit-api-tokens
api_get() {  # key in a process-substitution header file, never in argv; non-200 -> 2
  local resp code
  resp=$(curl -sS --max-time 60 -w '\n%{http_code}' \
    -H @<(printf 'Authorization: Bearer %s\n' "$ATLASSIAN_ORG_API_KEY") \
    -H 'Accept: application/json' "${API}$1") || { echo "ERROR: GET ${1%%\?*} failed in transport" >&2; return 2; }
  code=${resp##*$'\n'}
  [ "$code" = "200" ] || { echo "ERROR: GET ${1%%\?*} -> HTTP ${code} (403 = the key lacks permission to read user API tokens: read:tokens:admin)" >&2; return 2; }
  printf '%s\n' "${resp%$'\n'*}"
}

tokens='[]'; cursor=''; pages=0
while :; do
  page=$(api_get "/admin/api-access/v1/orgs/${ORG_ID}/api-tokens?pageSize=1000${cursor:+&cursor=$(jq -rn --arg v "$cursor" '$v|@uri')}")
  tokens=$(printf '%s' "$page" | jq -ce --argjson acc "$tokens" 'if (.data | type) == "array" then $acc + .data else error("no data array") end')
  cursor=$(printf '%s' "$page" | jq -r '.links.next // empty')
  [ -z "$cursor" ] && break
  pages=$((pages + 1)); [ "$pages" -lt "$MAX_PAGES" ] || { echo "ERROR: MAX_PAGES reached; token list is partial" >&2; exit 3; }
done

# expiresAt is ISO-8601; fractional seconds and a +00:00 offset are normalised
# before parsing, and anything still unparseable is flagged, not skipped.
limit=$(( $(date +%s) + MAX_TOKEN_DAYS * 86400 ))
findings=$(printf '%s' "$tokens" | jq -r --argjson lim "$limit" '
  .[] | select(.status == "ALLOWED") | (.expiresAt // "") as $e
  | (if $e == "" then "no-expiry"
     else (try ($e | sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601) catch -1) as $t
          | if $t < 0 then "unparseable-expiry" elif $t > $lim then "expiry-beyond-standard" else empty end
     end) as $why
  | "  user=\(.user.id) token=\(.label) created=\(.createdAt) expires=\(if $e == "" then "never" else $e end) lastActive=\(.lastActiveAt // "never") -> \($why)"')
echo "API tokens: $(printf '%s' "$tokens" | jq 'length') ($(printf '%s' "$tokens" | jq '[.[] | select(.status == "ALLOWED")] | length') allowed); standard: expiry within ${MAX_TOKEN_DAYS} days"
if [ -n "$findings" ]; then
  echo "FINDING: tokens to rotate or revoke:"; printf '%s\n' "$findings"; exit 1
fi
exit 0
# HTH Guide Excerpt: end api-audit-api-tokens
