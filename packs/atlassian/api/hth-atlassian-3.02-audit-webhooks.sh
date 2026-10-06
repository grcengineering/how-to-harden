#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: atlassian-3.2
#   guide:   https://howtoharden.com/guides/atlassian/#32-configure-webhook-security
#   profile: L2
#   mode:    read-only
#   requires: ATLASSIAN_SITE_URL(https://<your-domain>.atlassian.net), ATLASSIAN_EMAIL(Jira administrator account), ATLASSIAN_API_TOKEN(that account's API token)
# =============================================================================
# HTH Atlassian Control 3.2: Configure Webhook Security — admin webhook audit
# Profile Level: L2 (Walk) | NIST 800-53: SC-8
# Source: https://developer.atlassian.com/cloud/jira/platform/webhooks/
#         "To get all webhooks for a Jira instance, perform a GET" on
#         /rest/webhooks/1.0/webhook; each webhook carries url, enabled and
#         isSigned ("isSigned is true if a secret is defined").
# Dependencies: bash 3.2+, curl 7.55+ (-H @file), jq, base64
#
#  - Findings: an admin webhook with no secret (isSigned is not true), so its
#    deliveries cannot be verified with X-Hub-Signature (see the sdk pack for
#    this control), or a destination that is not https://.
#  - Enabled webhooks with an empty JQL filter are listed for review, because
#    they send every matching event's payload to the destination.
#  - Credentials are basic auth (email:API token) built inside a process
#    substitution; neither value reaches argv. Reads only: no POST/PUT/DELETE.
#
# Exit codes: 0 no finding | 1 finding | 2 could not audit
#             any other non-zero: a response that was not the documented JSON (never read as clean)
# =============================================================================
set -euo pipefail

: "${ATLASSIAN_SITE_URL:?set ATLASSIAN_SITE_URL, e.g. https://your-domain.atlassian.net}"
: "${ATLASSIAN_EMAIL:?set ATLASSIAN_EMAIL (a Jira administrator)}"
: "${ATLASSIAN_API_TOKEN:?set ATLASSIAN_API_TOKEN}"
command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

# HTH Guide Excerpt: begin api-audit-webhooks
resp=$(curl -sS --max-time 60 -w '\n%{http_code}' \
  -H @<(printf 'Authorization: Basic %s\n' "$(printf '%s:%s' "$ATLASSIAN_EMAIL" "$ATLASSIAN_API_TOKEN" | base64 | tr -d '\n')") \
  -H 'Accept: application/json' "${ATLASSIAN_SITE_URL}/rest/webhooks/1.0/webhook") \
  || { echo "ERROR: GET /rest/webhooks/1.0/webhook failed in transport" >&2; exit 2; }
code=${resp##*$'\n'}; body=${resp%$'\n'*}
[ "$code" = "200" ] || { echo "ERROR: GET /rest/webhooks/1.0/webhook -> HTTP ${code} (needs a Jira administrator)" >&2; exit 2; }

# The list must be a JSON array; any other shape is "could not audit".
hooks=$(printf '%s' "$body" | jq -ce 'if type == "array" then . else error("webhook list is not an array") end') \
  || { echo "ERROR: unexpected response shape; nothing was audited" >&2; exit 2; }

echo "admin webhooks: $(printf '%s' "$hooks" | jq 'length')"
printf '%s' "$hooks" | jq -r '.[] | "  \(.name // "(unnamed)"): enabled=\(.enabled) isSigned=\(.isSigned) url=\(.url)"'
findings=$(printf '%s' "$hooks" | jq -r '.[]
  | (if .isSigned == true then empty else "\(.name // .self): no secret set, deliveries cannot be verified" end),
    (if ((.url // "") | startswith("https://")) then empty else "\(.name // .self): destination is not https://" end)')
review=$(printf '%s' "$hooks" | jq -r '.[] | select(.enabled == true)
  | select(((.filters // {}) | to_entries | map(.value // "") | join("")) == "")
  | "\(.name // .self): no JQL filter, sends every matching event"')
[ -z "$review" ] || { echo "REVIEW:"; printf '%s\n' "$review" | sed 's/^/  /'; }
if [ -n "$findings" ]; then
  echo "FINDING:"; printf '%s\n' "$findings" | sed 's/^/  /'; exit 1
fi
exit 0
# HTH Guide Excerpt: end api-audit-webhooks
