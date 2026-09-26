#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: atlassian-4.2
#   guide:   https://howtoharden.com/guides/atlassian/#42-implement-data-classification
#   profile: L2
#   mode:    read-only
#   requires: ATLASSIAN_SITE_URL(https://<your-domain>.atlassian.net), ATLASSIAN_EMAIL(Confluence account that can view every space), ATLASSIAN_API_TOKEN(that account's API token)
# =============================================================================
# HTH Atlassian Control 4.2: Implement Data Classification — Confluence coverage audit
# Profile Level: L2 (Walk) | NIST 800-53: AC-3
# Source: https://developer.atlassian.com/cloud/confluence/rest/v2/
#         GET /classification-levels ; GET /spaces ;
#         GET /spaces/{id}/classification-level/default
# Dependencies: bash 3.2+, curl 7.55+ (-H @file), jq, base64
#
#  - Findings: the site has no PUBLISHED classification level; a current space
#    with no default classification level.
#  - The default-level GET answers 404 for three different reasons, per the
#    reference: no default applied, no data-classification entitlement on the
#    site's edition, or a space this account cannot view. All three leave the
#    space unclassified as far as this account can prove, so a 404 is reported
#    as a finding and never skipped. Any other non-200 exits 2.
#  - Levels are defined for the organization, in the console (admin.atlassian.com
#    → Data classification) or through the Data Loss Prevention REST API
#    (https://developer.atlassian.com/cloud/admin/dlp/rest/, marked experimental;
#    write:classification-levels:admin). No write pack is shipped for it. Jira
#    project classification is not covered by this pack.
#
# Exit codes: 0 no finding | 1 finding | 2 could not audit | 3 partial (page cap)
#             any other non-zero: a response that was not the documented JSON (never read as clean)
# =============================================================================
set -euo pipefail

: "${ATLASSIAN_SITE_URL:?set ATLASSIAN_SITE_URL, e.g. https://your-domain.atlassian.net}"
: "${ATLASSIAN_EMAIL:?set ATLASSIAN_EMAIL}"
: "${ATLASSIAN_API_TOKEN:?set ATLASSIAN_API_TOKEN}"
MAX_PAGES="${MAX_PAGES:-50}"
command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

# HTH Guide Excerpt: begin api-audit-classification
# $1 = path+query under /wiki/api/v2. Prints "<http_code>\n<body>"; transport failure -> 2.
site_get() {
  local resp
  resp=$(curl -sS --max-time 60 -w '\n%{http_code}' \
    -H @<(printf 'Authorization: Basic %s\n' "$(printf '%s:%s' "$ATLASSIAN_EMAIL" "$ATLASSIAN_API_TOKEN" | base64 | tr -d '\n')") \
    -H 'Accept: application/json' "${ATLASSIAN_SITE_URL}/wiki/api/v2$1") || { echo "ERROR: GET ${1%%\?*} failed in transport" >&2; return 2; }
  printf '%s\n%s\n' "${resp##*$'\n'}" "${resp%$'\n'*}"
}
ok_body() {  # $1 = site_get output, $2 = path for the message; body on 200, else return 2
  local code="${1%%$'\n'*}"
  [ "$code" = "200" ] || { echo "ERROR: GET ${2%%\?*} -> HTTP ${code}" >&2; return 2; }
  printf '%s\n' "${1#*$'\n'}"
}

rc=0
out=$(site_get "/classification-levels"); levels=$(ok_body "$out" "/classification-levels")
published=$(printf '%s' "$levels" | jq -e -r 'if type == "array" then map(select(.status == "PUBLISHED") | .name) | join(", ") else error("not an array") end')
if [ -z "$published" ]; then echo "FINDING: no PUBLISHED classification level on this site"; rc=1
else echo "published classification levels: ${published}"; fi

spaces=''; cursor=''; pages=0
while :; do
  out=$(site_get "/spaces?status=current&limit=250${cursor:+&cursor=${cursor}}"); page=$(ok_body "$out" "/spaces")
  # A page without a results array stops the audit (jq error); it never shortens the space list.
  spaces="${spaces}$(printf '%s' "$page" | jq -r 'if (.results | type) == "array" then .results[] | "\(.id) \(.key)" else error("no results array") end')"$'\n'
  next=$(printf '%s' "$page" | jq -r '._links.next // empty')
  [ -z "$next" ] && break
  cursor=$(printf '%s' "$next" | sed -n 's/.*[?&]cursor=\([^&]*\).*/\1/p')
  [ -n "$cursor" ] || { echo "ERROR: _links.next carries no cursor; space list is partial" >&2; exit 3; }
  pages=$((pages + 1)); [ "$pages" -lt "$MAX_PAGES" ] || { echo "ERROR: MAX_PAGES reached; space list is partial" >&2; exit 3; }
done
n_spaces=$(printf '%s' "$spaces" | grep -c . || true)
[ "$n_spaces" -gt 0 ] || { echo "ERROR: 0 current spaces visible to this account; nothing was audited" >&2; exit 2; }

unclassified=''
while read -r sid skey; do
  [ -n "$sid" ] || continue
  out=$(site_get "/spaces/${sid}/classification-level/default")
  case "${out%%$'\n'*}" in
    200) ;;
    404) unclassified="${unclassified}  ${skey}"$'\n' ;;
    *)   echo "ERROR: GET /spaces/${sid}/classification-level/default -> HTTP ${out%%$'\n'*}" >&2; exit 2 ;;
  esac
done < <(printf '%s' "$spaces")
echo "current spaces checked: ${n_spaces}"
if [ -n "$unclassified" ]; then
  echo "FINDING: spaces with no default classification level (404: none applied, no entitlement, or not visible):"
  printf '%s' "$unclassified"; rc=1
fi
exit "$rc"
# HTH Guide Excerpt: end api-audit-classification
