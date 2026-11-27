#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: customer-io-1.3
#   guide: https://howtoharden.com/guides/customer-io/#13-use-an-audit-only-key-for-account-evidence
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq, current account audit-only key, expected region and account ID
# Source (checked 2026-11-27): https://docs.customer.io/integrations/api/app/tag/audit-logs/listaccountauditlogs/
# Review locally; protect evidence from unnecessary disclosure.

# HTH Guide Excerpt: begin customer-io-evidence
set +x
set -euo pipefail
: "${HTH_CIO_REGION:?Set us or eu, as configured in your Customer.io account.}"
: "${HTH_CIO_AUDIT_KEY:?Set a private account audit-only key.}"
: "${HTH_CIO_ACCOUNT_ID:?Set the expected numeric account ID from approved evidence.}"
case "$HTH_CIO_REGION" in us) host=api.customer.io;; eu) host=api-eu.customer.io;; *) exit 2;; esac
[[ "$HTH_CIO_AUDIT_KEY" =~ ^sk_([a-z][a-z])_[A-Za-z0-9_-]+$ &&
   "${BASH_REMATCH[1]}" == "$HTH_CIO_REGION" && "$HTH_CIO_ACCOUNT_ID" =~ ^[1-9][0-9]{0,14}$ ]] ||
  { printf 'Invalid API key format, region mismatch or invalid account ID.\n' >&2; exit 2; }
printf 'Authorization: Bearer %s\n' "$HTH_CIO_AUDIT_KEY" |
  curl -q --silent --show-error --fail --proto '=https' --connect-timeout 10 --max-time 30 --header @- \
    "https://$host/v1/account/audit_logs?limit=20&sort_order=desc" |
  jq -e -s --arg id "$HTH_CIO_ACCOUNT_ID" '
    if length != 1 then error("Expected one audit response") else .[0] end
    | if (.data | type) != "array" or (.data | length) > 20
      or (.pagination.next_cursor | type) != "number"
      or (all(.data[]; (.account_id | tostring) == $id) | not)
      then error("Unexpected audit response or account")
      else {source:"account_audit_logs", sample_count:(.data | length),
            account_verified:((.data | length) > 0), more:(.pagination.next_cursor != 0)} end'
# HTH Guide Excerpt: end customer-io-evidence
