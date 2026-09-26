#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: atlassian-3.1
#   guide:   https://howtoharden.com/guides/atlassian/#31-secure-applinks-configuration
#   profile: L2
#   mode:    read-only
#   requires: APPLINKS_BASE_URL(Jira or Confluence Data Center base URL), DC_USERNAME(administrator), DC_PASSWORD(that administrator's password)
# =============================================================================
# HTH Atlassian Control 3.1: Secure AppLinks Configuration — Data Center inventory
# Profile Level: L2 (Walk) | NIST 800-53: SC-8
# Sources (Atlassian knowledge base, Data Center):
#   https://support.atlassian.com/jira/kb/how-to-fetch-application-link-status-through-rest-api/
#     GET <base>/rest/applinks/3.0/applinks        -> array of links, each with .id
#     GET <base>/rest/applinks/3.0/status/<id>     -> .working (true | false)
#   https://support.atlassian.com/atlassian-knowledge-base/kb/how-to-generate-an-application-links-configuration-summary/
# Dependencies: bash 3.2+, curl 7.55+ (-H @file), jq, base64
#
#  - Lists every application link and whether it is working. A link that is
#    not working is a finding: it is standing trust to a system that no longer
#    answers, which is the first thing the guide's audit step removes.
#  - Deliberately NOT called: .../applicationlink/{id}/authentication. Per the
#    configuration-summary KB, when a link uses Basic Auth "the configured
#    username and password will be returned in the JSON data", so that call can
#    pull a stored credential into this pack's output. The authentication type
#    (OAuth 2.0 versus OAuth 1.0a) therefore stays a console check:
#    Administration → Application links → Edit.
#  - Data Center only; Atlassian Cloud has no Application Links REST resource
#    in the Organizations API. Reads only.
#
# Exit codes: 0 no finding | 1 finding | 2 could not audit
#             any other non-zero: a response that was not the documented JSON (never read as clean)
# =============================================================================
set -euo pipefail

: "${APPLINKS_BASE_URL:?set APPLINKS_BASE_URL, e.g. https://jira.example.com}"
: "${DC_USERNAME:?set DC_USERNAME (an administrator)}"
: "${DC_PASSWORD:?set DC_PASSWORD}"
command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

# HTH Guide Excerpt: begin api-audit-applinks
dc_get() {  # $1 = path; basic auth built inside a process substitution (never argv); non-200 -> 2
  local resp code
  resp=$(curl -sS --max-time 60 -w '\n%{http_code}' \
    -H @<(printf 'Authorization: Basic %s\n' "$(printf '%s:%s' "$DC_USERNAME" "$DC_PASSWORD" | base64 | tr -d '\n')") \
    -H 'Accept: application/json' "${APPLINKS_BASE_URL}$1") || { echo "ERROR: GET $1 failed in transport" >&2; return 2; }
  code=${resp##*$'\n'}
  [ "$code" = "200" ] || { echo "ERROR: GET $1 -> HTTP ${code} (needs an administrator)" >&2; return 2; }
  printf '%s\n' "${resp%$'\n'*}"
}

links=$(dc_get "/rest/applinks/3.0/applinks")
# error() exits jq non-zero, so an unexpected shape stops the audit; an empty array is a real "none".
ids=$(printf '%s' "$links" | jq -r 'if type == "array" then .[].id else error("link list is not an array") end')
n=$(printf '%s' "$ids" | grep -c . || true)
echo "application links: ${n}"
[ "$n" -gt 0 ] || { echo "no application links configured (nothing to trust, nothing to remove)"; exit 0; }

broken=''
while read -r id; do
  [ -n "$id" ] || continue
  st=$(dc_get "/rest/applinks/3.0/status/${id}")
  # no -e here: jq -e treats a legitimate `false` as failure. error() still exits non-zero.
  working=$(printf '%s' "$st" | jq -r 'if (.working | type) == "boolean" then .working else error("no working flag") end')
  echo "  ${id}: working=${working}"
  [ "$working" = "true" ] || broken="${broken}  ${id}"$'\n'
done < <(printf '%s\n' "$ids")

echo "REVIEW: confirm each link is still needed and uses OAuth 2.0 (console: Administration → Application links)"
if [ -n "$broken" ]; then
  echo "FINDING: links that are not working (stale trust, remove or repair):"; printf '%s' "$broken"; exit 1
fi
exit 0
# HTH Guide Excerpt: end api-audit-applinks
