#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: sap-ariba-1.2
#   guide: https://howtoharden.com/guides/sap-ariba/#12-review-sensitive-groups-and-provisioning-connectors
#   profile: L1
#   mode: read-only
#   requires: bash, curl, US SCIM API runtime, authorized token and application key
# Source (checked 2026-11-27): https://help.sap.com/doc/88812c450b43467bb6a0445a1486580a/cloud/en-US/094ff0c1f32e42a1acc0c21e27483ca7.pdf
# HTH Control 1.2: Review sensitive groups and provisioning connectors (AC-6) (L1)
# Guide: https://howtoharden.com/guides/sap-ariba/
# Use the SCIM Runtime URL from Environment Details for your Developer Portal API.
# This example is scoped to the US openapi.ariba.com gateway; do not reuse it for other regions.
# Supply the approved application key, short-lived token and known SCIM group ID.

# HTH Guide Excerpt: begin sap-ariba-evidence
set +x
set -euo pipefail
fail() { printf '%s\n' "$*" >&2; exit 2; }
: "${HTH_ARIBA_SCIM_URL:?Set the US SAP Ariba SCIM runtime URL}"
: "${HTH_ARIBA_GROUP_ID:?Set the SCIM group ID}"
: "${HTH_ARIBA_KEY:?Set the approved Ariba API key}"
: "${HTH_ARIBA_TOKEN:?Set a short-lived OAuth token}"
base=${HTH_ARIBA_SCIM_URL%/}
[[ "$base" =~ ^https://openapi\.ariba\.com(/api/[A-Za-z0-9_-]+/v[0-9]+/(prod|sandbox))(/[-A-Za-z0-9_]+)*$ ]] || fail "Invalid US Ariba SCIM runtime URL."
[[ "$HTH_ARIBA_GROUP_ID" =~ ^[A-Za-z0-9_-]+$ ]] || fail "Invalid SCIM group ID."
[[ "$HTH_ARIBA_KEY" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || fail "Invalid API key format."
[[ "$HTH_ARIBA_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || fail "Invalid bearer token format."
printf 'Authorization: Bearer %s\napikey: %s\n' "$HTH_ARIBA_TOKEN" "$HTH_ARIBA_KEY" |
  curl -q --silent --show-error --fail --proto '=https' --connect-timeout 10 --max-time 30 --header @- --header 'Accept: application/json' \
    "$base/Groups/$HTH_ARIBA_GROUP_ID"
# HTH Guide Excerpt: end sap-ariba-evidence
