#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grafana-cloud-1.2
#   guide: https://howtoharden.com/guides/grafana-cloud/#12-scope-cloud-access-policies-by-stack-and-task
#   profile: L1
#   mode: read-only
#   requires: Bash, curl, jq, GRAFANA_CLOUD_POLICY_ID, GRAFANA_CLOUD_REGION, GRAFANA_CLOUD_API_TOKEN
# Grafana Cloud 1.2 | L1 | NIST AC-6 | https://howtoharden.com/guides/grafana-cloud/#12-scope-cloud-access-policies-by-stack-and-task
# https://grafana.com/docs/grafana-cloud/learn-and-build/developer-resources/api-reference/cloud-api/
# HTH Guide Excerpt: begin read-grafana-cloud-regional-policy
set +x
set -euo pipefail

: "${GRAFANA_CLOUD_POLICY_ID:?Set the access policy UUID}"
: "${GRAFANA_CLOUD_REGION:?Set the access policy region}"
: "${GRAFANA_CLOUD_API_TOKEN:?Inject an authorized Grafana Cloud API token}"
[[ "$GRAFANA_CLOUD_POLICY_ID" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]] || exit 2
[[ "$GRAFANA_CLOUD_REGION" =~ ^[A-Za-z0-9-]+$ ]] || exit 2
[[ "$GRAFANA_CLOUD_API_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || exit 2

response=$(
  printf 'Authorization: Bearer %s\n' "$GRAFANA_CLOUD_API_TOKEN" |
    curl -q --fail --silent --show-error --proto '=https' --max-time 30 \
      --header @- --get --data-urlencode "region=$GRAFANA_CLOUD_REGION" \
      "https://www.grafana.com/api/v1/accesspolicies/$GRAFANA_CLOUD_POLICY_ID"
)
jq -e --arg id "$GRAFANA_CLOUD_POLICY_ID" '
    if (.id != $id) or ((.scopes | type) != "array") or ((.realms | type) != "array")
    then error("invalid access policy response")
    else {id, orgId, name, scopes, realms, allowedSubnets: (.conditions.allowedSubnets // [])}
    end' <<< "$response"
# HTH Guide Excerpt: end read-grafana-cloud-regional-policy
