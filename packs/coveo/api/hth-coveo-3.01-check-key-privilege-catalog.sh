#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: coveo-3.1
#   guide: https://howtoharden.com/guides/coveo/#31-scope-api-keys-to-required-privileges-and-origins
#   profile: L2
#   mode: read-only
#   requires: Bash, curl and vendor read credentials; jq for structured samples
# HTH coveo 3.1: Scope API keys to required privileges and origins
# Profile: L2 (Walk)
# Guide: https://howtoharden.com/guides/coveo/
# Reference: https://docs.coveo.com/en/60
# HTH Guide Excerpt: begin check-key-privilege-catalog
set +x
set -euo pipefail
: "${COVEO_PLATFORM_HOST:?Set COVEO_PLATFORM_HOST for the approved target}"
: "${COVEO_ORGANIZATION_ID:?Set COVEO_ORGANIZATION_ID for the approved target}"
: "${COVEO_OAUTH_TOKEN:?Set COVEO_OAUTH_TOKEN for the approved target}"
case "$COVEO_PLATFORM_HOST" in
  platform.cloud.coveo.com|platform-ca.cloud.coveo.com|platform-eu.cloud.coveo.com|platform-au.cloud.coveo.com) ;;
  *) printf '%s\n' 'Unsupported Coveo platform host' >&2; exit 2 ;;
esac
if ! [[ "$COVEO_ORGANIZATION_ID" =~ ^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$ && "$COVEO_OAUTH_TOKEN" =~ ^[A-Za-z0-9_./+~=-]+$ ]]; then
  printf '%s\n' 'Invalid organization ID or token format' >&2
  exit 2
fi

printf 'header = "Authorization: Bearer %s"\n' "$COVEO_OAUTH_TOKEN" |
  curl --disable --config - --proto '=https' --silent --show-error --fail \
    --connect-timeout 10 --max-time 30 --max-filesize 1048576 \
    --request GET --write-out ' %{http_code}' "https://$COVEO_PLATFORM_HOST/rest/organizations/$COVEO_ORGANIZATION_ID/privileges/apikeys" |
  jq -ces 'if length == 2 and .[1] == 200 and
      (.[0] | type == "array" and all(.[]; type == "object" and
        (.owner | type == "string") and (.targetDomain | type == "string")))
    then {assignable_privilege_combinations: (.[0] | length)}
    else error("Unexpected Coveo privilege response") end'
# HTH Guide Excerpt: end check-key-privilege-catalog
