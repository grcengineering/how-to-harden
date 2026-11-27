#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: make-2.1
#   guide: https://howtoharden.com/guides/make/#21-turn-off-public-sharing-for-internal-scenarios
#   profile: L1
#   mode: read-only
#   requires: Bash, curl and vendor read credentials; jq for structured samples
# HTH make 2.1: Turn off public sharing for internal scenarios
# Profile: L1 (Crawl)
# Guide: https://howtoharden.com/guides/make/
# Reference: https://developers.make.com/api-documentation/api-reference/scenarios.md
# HTH Guide Excerpt: begin sample-active-shared-scenarios
set +x
set -euo pipefail
: "${MAKE_PRODUCTION_HOST:?Set MAKE_PRODUCTION_HOST for the approved target}"
: "${MAKE_ORGANIZATION_ID:?Set MAKE_ORGANIZATION_ID for the approved target}"
: "${MAKE_API_TOKEN:?Set MAKE_API_TOKEN for the approved target}"
case "$MAKE_PRODUCTION_HOST" in
  eu1.make.com|eu2.make.com|us1.make.com|us2.make.com) ;;
  *) printf '%s\n' 'Use an approved Make.com production zone' >&2; exit 2 ;;
esac
if ! [[ "$MAKE_ORGANIZATION_ID" =~ ^[1-9][0-9]{0,15}$ && "$MAKE_API_TOKEN" =~ ^[A-Za-z0-9_./+~=-]+$ ]]; then
  printf '%s\n' 'Invalid Make organization ID or API token format' >&2
  exit 2
fi

printf 'header = "Authorization: Token %s"\n' "$MAKE_API_TOKEN" |
  curl --disable --config - --proto '=https' --silent --show-error --fail \
    --connect-timeout 10 --max-time 30 --max-filesize 1048576 \
    --request GET --write-out ' %{http_code}' "https://$MAKE_PRODUCTION_HOST/api/v2/scenarios?organizationId=$MAKE_ORGANIZATION_ID&isActive=true&cols%5B%5D=id&cols%5B%5D=isShared&pg%5Blimit%5D=25" |
  jq -ces 'if length == 2 and .[1] == 200 and
      (.[0] | type == "object" and (.scenarios | type == "array" and length <= 25 and
        all(.[]; type == "object" and (.id | type == "number") and
            (.isShared | type == "boolean"))))
    then .[0] | {sampled: (.scenarios | length),
                 shared_scenario_ids: [.scenarios[] | select(.isShared) | .id]}
    else error("Unexpected Make scenario response") end'
# HTH Guide Excerpt: end sample-active-shared-scenarios
