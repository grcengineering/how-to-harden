#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: oracle-fusion-cloud-erp-1.2
#   guide: https://howtoharden.com/guides/oracle-fusion-cloud-erp/#12-bind-finance-job-roles-to-the-proper-data-context
#   profile: L1
#   mode: read-only
#   requires: bash, curl, authorized Fusion OAuth token and assignment ID
# Source (checked 2026-11-27): https://docs.oracle.com/en/cloud/saas/financials/26b/farfa/api-data-security-users.html
# HTH Control 1.2: Bind finance job roles to the proper data context (AC-3) (L1)
# Guide: https://howtoharden.com/guides/oracle-fusion-cloud-erp/
# Supply the Oracle Fusion pod host, one assignment ID and an authorized bearer token.
# Only documented *.fa.<region>.oraclecloud.com pod hosts are supported by this example.

# HTH Guide Excerpt: begin oracle-fusion-cloud-erp-evidence
set +x
set -euo pipefail
fail() { printf '%s\n' "$*" >&2; exit 2; }
: "${HTH_FUSION_HOST:?Set the Oracle Fusion pod host without a scheme or path}"
: "${HTH_FUSION_ASSIGNMENT_ID:?Set the UserRoleDataAssignmentId}"
: "${HTH_FUSION_TOKEN:?Set a short-lived bearer token}"
[[ "$HTH_FUSION_HOST" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?\.fa\.[a-z0-9]([a-z0-9-]*[a-z0-9])?\.oraclecloud\.com$ ]] || fail "Invalid Oracle Fusion host."
[[ "$HTH_FUSION_ASSIGNMENT_ID" =~ ^[0-9]+$ ]] || fail "Invalid assignment ID."
[[ "$HTH_FUSION_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || fail "Invalid bearer token format."
printf 'Authorization: Bearer %s\n' "$HTH_FUSION_TOKEN" |
  curl -q --silent --show-error --fail --proto '=https' --connect-timeout 10 --max-time 30 --header @- --header 'Accept: application/json' \
    "https://$HTH_FUSION_HOST/fscmRestApi/resources/11.13.18.05/dataSecurities/$HTH_FUSION_ASSIGNMENT_ID"
# HTH Guide Excerpt: end oracle-fusion-cloud-erp-evidence
