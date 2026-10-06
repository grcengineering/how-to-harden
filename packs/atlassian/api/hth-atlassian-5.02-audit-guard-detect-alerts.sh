#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: atlassian-5.2
#   guide:   https://howtoharden.com/guides/atlassian/#52-configure-anomaly-detection
#   profile: L2
#   mode:    read-only
#   requires: ORG_ID(organization id), ATLASSIAN_ORG_API_KEY(Organization API key with scopes, read:events:admin only), GUARD_PREMIUM(optional: "confirmed" once the console shows Guard Premium detections are on)
# =============================================================================
# HTH Atlassian Control 5.2: Configure Anomaly Detection — Guard Detect alert audit
# Profile Level: L2 (Walk)
# Source: https://developer.atlassian.com/cloud/admin/organization/rest/api-group-events/
#         GET /v1/orgs/{orgId}/events?product=guard_detect  (product enum:
#         bitbucket, confluence, guard_detect, jira, loom; meta.next cursor; limit<=500)
# Dependencies: bash 3.2+, curl 7.55+ (-H @file), jq
#
#  - Counts audit-log events whose product is guard_detect in the last
#    LOOKBACK_DAYS days and breaks them down by action. Any such event is an
#    alert to triage, so a non-zero count exits 1.
#  - Any non-200 exits 2. The reference documents no 403 for this operation
#    and says nothing about organizations without Guard Premium, so this pack
#    does not assume they get an error.
#  - Zero guard_detect events is therefore ambiguous: no detections fired, or
#    detection is not active and nothing could have fired. It exits 4
#    (inconclusive) unless GUARD_PREMIUM=confirmed says you checked in the
#    console that Guard Premium detections are on; only then is it "no alerts".
#  - Turning detections on has no REST resource; that stays in the console.
#  - Events API rate limit is 10 requests/minute; pages are spaced PAGE_DELAY s.
#
# Exit codes: 0 no alerts in window (GUARD_PREMIUM=confirmed) | 1 alerts to triage | 2 could not audit
#             3 partial (page cap) | 4 inconclusive (no events, detection not confirmed active)
#             any other non-zero: a response that was not the documented JSON (never read as clean)
# =============================================================================
set -euo pipefail

: "${ORG_ID:?set ORG_ID}"
: "${ATLASSIAN_ORG_API_KEY:?set ATLASSIAN_ORG_API_KEY (Organization API key, scope read:events:admin)}"
API="${ATLASSIAN_API_BASE:-https://api.atlassian.com}"
LOOKBACK_DAYS="${LOOKBACK_DAYS:-7}"
MAX_PAGES="${MAX_PAGES:-20}"
PAGE_DELAY="${PAGE_DELAY:-6}"
GUARD_PREMIUM="${GUARD_PREMIUM:-}"
command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

# HTH Guide Excerpt: begin api-audit-guard-detect-alerts
api_get() {  # key in a process-substitution header file, never in argv; non-200 -> 2
  local resp code
  resp=$(curl -sS --max-time 60 -w '\n%{http_code}' \
    -H @<(printf 'Authorization: Bearer %s\n' "$ATLASSIAN_ORG_API_KEY") \
    -H 'Accept: application/json' "${API}$1") || { echo "ERROR: GET ${1%%\?*} failed in transport" >&2; return 2; }
  code=${resp##*$'\n'}
  [ "$code" = "200" ] || { echo "ERROR: GET ${1%%\?*} -> HTTP ${code} (check the key is valid and carries read:events:admin)" >&2; return 2; }
  printf '%s\n' "${resp%$'\n'*}"
}

from_ms=$(( ( $(date +%s) - LOOKBACK_DAYS * 86400 ) * 1000 ))
events='[]'; cursor=''; pages=0
while :; do
  page=$(api_get "/admin/v1/orgs/${ORG_ID}/events?product=guard_detect&from=${from_ms}&limit=500${cursor:+&cursor=$(jq -rn --arg c "$cursor" '$c|@uri')}")
  events=$(printf '%s' "$page" | jq -ce --argjson acc "$events" 'if (.data | type) == "array" then $acc + .data else error("no data array") end')
  cursor=$(printf '%s' "$page" | jq -r '.meta.next // empty')
  [ -z "$cursor" ] && break
  pages=$((pages + 1)); [ "$pages" -lt "$MAX_PAGES" ] || { echo "ERROR: MAX_PAGES reached; alert list is partial" >&2; exit 3; }
  sleep "$PAGE_DELAY"
done

n=$(printf '%s' "$events" | jq 'length')
echo "guard_detect events in the last ${LOOKBACK_DAYS} days: ${n}"
if [ "$n" -gt 0 ]; then
  printf '%s' "$events" | jq -r 'group_by(.attributes.action) | .[] | "  \(.[0].attributes.action): \(length) (latest \(map(.attributes.time) | max))"'
  echo "FINDING: triage these detections in admin.atlassian.com, then record the outcome"
  exit 1
fi
# The API returns the same empty list whether or not detection is running.
if [ "$GUARD_PREMIUM" != "confirmed" ]; then
  echo "INCONCLUSIVE: no guard_detect events, and nothing here shows detection is active." >&2
  echo "  Confirm detection is on (admin.atlassian.com > Security > Anomaly detection), then re-run with GUARD_PREMIUM=confirmed." >&2
  exit 4
fi
echo "no alerts in window (Guard Premium detections confirmed active by the operator)"
exit 0
# HTH Guide Excerpt: end api-audit-guard-detect-alerts
