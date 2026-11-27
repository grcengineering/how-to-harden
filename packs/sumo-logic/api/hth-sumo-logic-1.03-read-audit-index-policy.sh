#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: sumo-logic-1.3
#   guide: https://howtoharden.com/guides/sumo-logic/#13-enable-and-reconcile-the-audit-index
#   profile: L1
#   mode: read-only
#   requires: Bash, curl, jq, base64, SUMO_DEPLOYMENT, SUMO_ACCESS_ID, SUMO_ACCESS_KEY
# Vendor contract: https://api.sumologic.com/docs/sumologic-api.yaml
# HTH Guide Excerpt: begin read-audit-index-policy
set +x
set -euo pipefail

: "${SUMO_DEPLOYMENT:?Set the authorized tenant deployment, e.g. us1 or eu}"
: "${SUMO_ACCESS_ID:?Inject the Sumo Logic Access ID}"
: "${SUMO_ACCESS_KEY:?Inject the Sumo Logic Access Key}"
[[ "$SUMO_ACCESS_ID" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || exit 2
[[ "$SUMO_ACCESS_KEY" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || exit 2
case "$SUMO_DEPLOYMENT" in
  us1) host=api.sumologic.com ;;
  au|ca|ch|de|eu|fed|jp|kr|us2) host="api.$SUMO_DEPLOYMENT.sumologic.com" ;;
  *) printf '%s\n' 'This pack does not recognize the deployment' >&2; exit 2 ;;
esac

response=$(
  encoded=$(printf '%s:%s' "$SUMO_ACCESS_ID" "$SUMO_ACCESS_KEY" | base64 | tr -d '\r\n')
  printf 'Authorization: Basic %s\n' "$encoded" |
    curl -q --fail --silent --show-error --proto '=https' --max-time 30 \
      --header @- "https://$host/api/v1/policies/audit"
)
jq -e 'if (.enabled | type) == "boolean" then {enabled} else error("invalid audit policy") end' <<< "$response"
# HTH Guide Excerpt: end read-audit-index-policy
