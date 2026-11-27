#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: adobe-creative-cloud-1.3
#   guide: https://howtoharden.com/guides/adobe-creative-cloud/#13-verify-a-creative-cloud-content-log-subscription
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq, Adobe I/O Management API and approved Content Logs journal credentials
# Source (checked 2026-11-27): https://developer.adobe.com/events/docs/guides/api/journaling-api
# Review locally; protect evidence from unnecessary disclosure.

# HTH Guide Excerpt: begin adobe-creative-cloud-evidence
set +x
set -euo pipefail
fail() { printf '%s\n' "$*" >&2; exit 2; }
: "${HTH_ADOBE_ORG_ID:?Set the exact Adobe organization ID.}"
: "${HTH_ADOBE_CLIENT_ID:?Set the authorized Adobe client ID.}"
: "${HTH_ADOBE_TOKEN:?Set the approved short-lived token for this integration.}"
[[ "$HTH_ADOBE_ORG_ID" =~ ^[A-Fa-f0-9]+@AdobeOrg$ ]] || fail 'Invalid Adobe organization ID.'
[[ "$HTH_ADOBE_CLIENT_ID" =~ ^[A-Za-z0-9_-]+$ ]] || fail 'Invalid client ID.'
[[ "$HTH_ADOBE_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || fail 'Invalid token format.'
: "${HTH_ADOBE_CONTENT_JOURNAL:?Set the specific Content Logs registration URL from Developer Console.}"
journal=${HTH_ADOBE_CONTENT_JOURNAL%/}
[[ "$journal" =~ ^https://events-[a-z0-9-]+\.adobe\.io/organizations/[0-9]+/integrations/[0-9]+/[a-fA-F0-9-]+$ ]] ||
  fail 'Invalid Adobe I/O Events journal URL.'
printf 'Authorization: Bearer %s\nX-Api-Key: %s\nx-ims-org-id: %s\n' \
  "$HTH_ADOBE_TOKEN" "$HTH_ADOBE_CLIENT_ID" "$HTH_ADOBE_ORG_ID" |
  curl -q --silent --show-error --fail --proto '=https' --connect-timeout 10 --max-time 30 --header @- --header 'Accept: application/json' \
    --get --data-urlencode 'limit=10' --data-urlencode 'seek=-PT2H' "$journal" |
  jq -e -s 'if length == 1 and (.[0].events | type) == "array" and
    (.[0]._page.count | type) == "number" and .[0]._page.count == (.[0].events | length)
    then .[0] | {sampleCount: ._page.count, window: "seek=-PT2H", payloadsEmitted: false}
    else error("No verified journal batch; verify product subscription, credentials and window") end'
# HTH Guide Excerpt: end adobe-creative-cloud-evidence
