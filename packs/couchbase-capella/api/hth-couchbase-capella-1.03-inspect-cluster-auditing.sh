#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: couchbase-capella-1.3
#   guide: https://howtoharden.com/guides/couchbase-capella/#13-enable-cluster-audit-logging
#   profile: L2
#   mode: read-only
#   requires: Bash, curl, jq, CAPELLA_ORGANIZATION_ID, CAPELLA_PROJECT_ID, CAPELLA_CLUSTER_ID, CAPELLA_API_TOKEN
# Vendor contract: https://production.docs.couchbase.com/cloud/management-api-reference/index.html
# HTH Guide Excerpt: begin inspect-cluster-auditing
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
      --header @- --header 'Accept: application/json' "$base/auditLog"
)

# The API examples show an array of IDs nested inside an array.
jq -e '
  if (.auditEnabled | type) != "boolean" or (.disabledUsers | type) != "array"
    or (.enabledEventIDs | type) != "array"
    or any(.enabledEventIDs | flatten | .[]; type != "number" or floor != .)
  then error("malformed cluster audit evidence")
  else {auditEnabled, disabledUserCount: (.disabledUsers | length),
        enabledEventIDs: (.enabledEventIDs | flatten)} end
' <<< "$response"
# HTH Guide Excerpt: end inspect-cluster-auditing
