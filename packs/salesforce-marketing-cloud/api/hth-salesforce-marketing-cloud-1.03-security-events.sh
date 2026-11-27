#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: salesforce-marketing-cloud-1.3
#   guide: https://howtoharden.com/guides/salesforce-marketing-cloud/#13-collect-and-verify-security-events
#   profile: L1
#   mode: read-only
#   requires: bash, curl, Marketing Cloud Engagement token with tracking_events_read
# Source (checked 2026-11-27): https://developer.salesforce.com/docs/marketing/marketing-cloud/references/mc_rest_rest_permission_scopes/rest-permissions-and-scopes.html
# HTH Control 1.3: Collect and verify Security Events (AU-6) (L1)
# Guide: https://howtoharden.com/guides/salesforce-marketing-cloud/
# Supply your MCE REST subdomain and a short-lived token with tracking_events_read.
# Prints one page; protect the output as potentially sensitive. No write calls.

# HTH Guide Excerpt: begin salesforce-marketing-cloud-evidence
set +x
set -euo pipefail
fail() { printf '%s\n' "$*" >&2; exit 2; }
: "${HTH_MCE_SUBDOMAIN:?Set the subdomain from the package REST Base URI}"
: "${HTH_MCE_TOKEN:?Set a short-lived REST bearer token}"
[[ "$HTH_MCE_SUBDOMAIN" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]] || fail "Invalid tenant subdomain."
[[ "$HTH_MCE_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || fail "Invalid bearer token format."
printf 'Authorization: Bearer %s\n' "$HTH_MCE_TOKEN" |
  curl -q --silent --show-error --fail --proto '=https' --connect-timeout 10 --max-time 30 --header @- --header 'Accept: application/json' \
    --get --data-urlencode "\$pagesize=100" --data-urlencode "\$page=1" \
    --data-urlencode "\$orderBy=createdDate desc" \
    "https://$HTH_MCE_SUBDOMAIN.rest.marketingcloudapis.com/data/v1/audit/securityEvents"
# HTH Guide Excerpt: end salesforce-marketing-cloud-evidence
