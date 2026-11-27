#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: contentful-1.1
#   guide: https://howtoharden.com/guides/contentful/#11-restrict-privileged-organization-membership
#   profile: L1
#   mode: read-only
#   requires: curl, jq, Contentful CMA token with organization membership access
# Source (reviewed 2026-11-27): https://www.contentful.com/developers/docs/references/user-management-api/organization-memberships/get-all-organization-memberships/
# HTH Guide Excerpt: begin inventory-organization-memberships
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${CONTENTFUL_CMA_TOKEN:-}" =~ ^[[:alnum:]_.~+/=-]+$ ]] || fail 'Missing or invalid CONTENTFUL_CMA_TOKEN'
[[ "${CONTENTFUL_ORG_ID:-}" =~ ^[[:alnum:]_-]+$ ]] || fail 'Missing or invalid CONTENTFUL_ORG_ID'

case "${CONTENTFUL_REGION:-us}" in
  us) host=api.contentful.com ;;
  eu) host=api.eu.contentful.com ;;
  *) fail 'CONTENTFUL_REGION must be us or eu' ;;
esac
skip=${CONTENTFUL_SKIP:-0}
[[ "$skip" =~ ^(0|[1-9][0-9]{0,7})$ ]] || fail 'Invalid page offset'
auth=$CONTENTFUL_CMA_TOKEN
response=$(printf 'header = "Authorization: Bearer %s"\n' "$auth" |
  curl --disable --config - --silent --show-error --fail --proto '=https' \
    --connect-timeout 10 --max-time 45 "https://$host/organizations/$CONTENTFUL_ORG_ID/organization_memberships?limit=100&skip=$skip") || fail 'Read request did not succeed'

jq -e '(.total|type)=="number" and (.items|type)=="array" and all(.items[]; (.sys.id|type)=="string" and (.role|type)=="string")' <<<"$response" >/dev/null || fail 'Unexpected organization membership response'
jq --argjson offset "$skip" '{scope:"one page scoped to the current identity",offset:$offset,total,memberships:[.items[]|{id:.sys.id,role,status:.sys.status}]}' <<<"$response"
# HTH Guide Excerpt: end inventory-organization-memberships
