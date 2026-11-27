#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: couchbase-capella-1.1
#   guide: https://howtoharden.com/guides/couchbase-capella/#11-restrict-cluster-public-ip-access
#   profile: L1
#   mode: read-only
#   requires: Bash, curl, jq, CAPELLA_ORGANIZATION_ID, CAPELLA_PROJECT_ID, CAPELLA_CLUSTER_ID, CAPELLA_API_TOKEN
# Vendor contract: https://production.docs.couchbase.com/cloud/management-api-reference/index.html
# HTH Guide Excerpt: begin inspect-public-cidrs
set +x
set -euo pipefail

: "${CAPELLA_ORGANIZATION_ID:?Set the approved organization UUID}"
: "${CAPELLA_PROJECT_ID:?Set the approved project UUID}"
: "${CAPELLA_CLUSTER_ID:?Set the approved cluster UUID}"
: "${CAPELLA_API_TOKEN:?Inject the authorized project-scoped API token}"
uuid='^[a-fA-F0-9]{8}(-[a-fA-F0-9]{4}){3}-[a-fA-F0-9]{12}$'
for id in "$CAPELLA_ORGANIZATION_ID" "$CAPELLA_PROJECT_ID" "$CAPELLA_CLUSTER_ID"; do
  [[ "$id" =~ $uuid ]] || exit 2
done
[[ "$CAPELLA_API_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || exit 2
base="https://cloudapi.cloud.couchbase.com/v4/organizations/$CAPELLA_ORGANIZATION_ID/projects/$CAPELLA_PROJECT_ID/clusters/$CAPELLA_CLUSTER_ID"
response=$(
  printf 'Authorization: Bearer %s\n' "$CAPELLA_API_TOKEN" |
    curl -q --fail --silent --show-error --proto '=https' --max-time 30 \
      --header @- --header 'Accept: application/json' "$base/allowedcidrs?page=1&perPage=75"
)

# The documented per-cluster maximum is 75; fail closed if the API sends a partial page.
jq -e '
  if (.data | type) != "array" or (.cursor.pages.totalItems != (.data | length))
    or any(.data[]; (.cidr | type) != "string" or (.status | type) != "string")
  then error("incomplete or malformed cluster CIDR evidence")
  else {cidrs: [.data[] | {cidr, status, expiresAt}]} end
' <<< "$response"
# HTH Guide Excerpt: end inspect-public-cidrs
