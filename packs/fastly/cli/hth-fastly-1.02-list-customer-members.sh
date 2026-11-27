#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: fastly-1.2
#   guide: https://howtoharden.com/guides/fastly/#12-review-account-members-and-roles
#   profile: L1
#   mode: read-only
#   requires: Bash, fastly, FASTLY_CUSTOMER_ID, FASTLY_API_TOKEN
# Fastly 1.2 | L1 | NIST AC-6 | https://howtoharden.com/guides/fastly/#12-review-account-members-and-roles
# https://www.fastly.com/documentation/reference/cli/user/list/
# HTH Guide Excerpt: begin list-fastly-customer-members
set +x
set -euo pipefail

: "${FASTLY_CUSTOMER_ID:?Set a Fastly customer ID}"
: "${FASTLY_API_TOKEN:?Inject an authorized Fastly API token}"
[[ "$FASTLY_CUSTOMER_ID" =~ ^[A-Za-z0-9]+$ ]] || exit 2
fastly user list --customer-id "$FASTLY_CUSTOMER_ID"
# HTH Guide Excerpt: end list-fastly-customer-members
