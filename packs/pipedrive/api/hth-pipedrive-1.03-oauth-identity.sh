#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: pipedrive-1.3
#   guide: https://howtoharden.com/guides/pipedrive/#13-bind-oauth-evidence-to-the-expected-company-and-user
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq, authorized OAuth access token, expected company and user IDs
# Source (checked 2026-11-27): https://developers.pipedrive.com/docs/api/v1/Users
# Review locally; protect evidence from unnecessary disclosure.

# HTH Guide Excerpt: begin pipedrive-evidence
set +x
set -euo pipefail
: "${HTH_PIPEDRIVE_DOMAIN:?Set your exact company slug before .pipedrive.com.}"
: "${HTH_PIPEDRIVE_TOKEN:?Set an authorized OAuth access token.}"
: "${HTH_PIPEDRIVE_COMPANY_ID:?Set the expected company ID.}"
: "${HTH_PIPEDRIVE_USER_ID:?Set the expected user ID.}"
[[ "$HTH_PIPEDRIVE_DOMAIN" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ &&
   "$HTH_PIPEDRIVE_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ &&
   "$HTH_PIPEDRIVE_COMPANY_ID" =~ ^[1-9][0-9]{0,14}$ &&
   "$HTH_PIPEDRIVE_USER_ID" =~ ^[1-9][0-9]{0,14}$ ]] ||
  { printf 'Invalid tenant slug, OAuth token or ID.\n' >&2; exit 2; }
printf 'Authorization: Bearer %s\n' "$HTH_PIPEDRIVE_TOKEN" |
  curl -q --silent --show-error --fail --proto '=https' --connect-timeout 10 --max-time 30 --header @- \
    "https://$HTH_PIPEDRIVE_DOMAIN.pipedrive.com/api/v1/users/me" |
  jq -e -s --arg company "$HTH_PIPEDRIVE_COMPANY_ID" --arg user "$HTH_PIPEDRIVE_USER_ID" '
    if length == 1 and .[0].success == true and (.[0].data.id | tostring) == $user
      and (.[0].data.company_id | tostring) == $company then .[0].data | {id,company_id}
      else error("Unexpected authenticated user or company") end'
# HTH Guide Excerpt: end pipedrive-evidence
