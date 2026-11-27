#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grafana-cloud-1.1
#   guide: https://howtoharden.com/guides/grafana-cloud/#11-require-mfa-for-portal-sign-in
#   profile: L1
#   mode: read-only
#   requires: Bash, curl, jq, GRAFANA_CLOUD_ORG_SLUG, GRAFANA_CLOUD_API_TOKEN
# Grafana Cloud 1.1 | L1 | NIST IA-2 | https://howtoharden.com/guides/grafana-cloud/#11-require-mfa-for-portal-sign-in
# https://grafana.com/docs/grafana-cloud/platform/security-and-account-management/security-and-access/authentication-and-permissions/mfa/
# HTH Guide Excerpt: begin read-grafana-cloud-org-mfa
set +x
set -euo pipefail

: "${GRAFANA_CLOUD_ORG_SLUG:?Set the Grafana Cloud organization slug}"
: "${GRAFANA_CLOUD_API_TOKEN:?Inject an authorized Grafana Cloud API token}"
[[ "$GRAFANA_CLOUD_ORG_SLUG" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]] || exit 2
[[ "$GRAFANA_CLOUD_API_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || exit 2

response=$(
  printf 'Authorization: Bearer %s\n' "$GRAFANA_CLOUD_API_TOKEN" |
    curl -q --fail --silent --show-error --proto '=https' --max-time 30 \
      --header @- "https://grafana.com/api/orgs/$GRAFANA_CLOUD_ORG_SLUG/settings"
)
jq -e 'if (.mfaRequired | type) == "boolean" then {mfaRequired} else error("invalid MFA settings response") end' <<< "$response"
# HTH Guide Excerpt: end read-grafana-cloud-org-mfa
