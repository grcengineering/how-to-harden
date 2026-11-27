#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: weights-biases-2.1
#   guide: https://howtoharden.com/guides/weights-biases/#21-scope-service-accounts-to-individual-teams
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq, approved W&B scoped audit or SCIM principal
# HTH weights-biases 2.1: Scope service accounts to individual teams
# Profile: L1 (Crawl)
# Guide: https://howtoharden.com/guides/weights-biases/
# Reference: https://github.com/wandb/docs/blob/main/platform/hosting/iam/scim.mdx
# HTH Guide Excerpt: begin count-scim-service-account-types
set -euo pipefail
set +x
: "${WANDB_SCIM_BASE_URL:?Set the verified W&B SCIM HTTPS origin}"
: "${WANDB_SCIM_API_KEY:?Use the authorized organization SCIM credential}"
[[ "$WANDB_SCIM_BASE_URL" =~ ^https://[A-Za-z0-9][A-Za-z0-9.-]*(:[1-9][0-9]{0,4})?$ && "$WANDB_SCIM_API_KEY" =~ ^[A-Za-z0-9._~-]+$ ]] || exit 2
printf 'header = "Authorization: Bearer %s"\n' "$WANDB_SCIM_API_KEY" |
  curl --disable --config - --proto '=https' --fail --silent --show-error \
    --connect-timeout 10 --max-time 30 --max-filesize 2097152 \
    --header 'Accept: application/scim+json' \
    "$WANDB_SCIM_BASE_URL/scim/Users" |
  jq -e 'if (.Resources|type) == "array" then {total_reported: .totalResults, inspected: (.Resources | length), account_types: ([.Resources[].accountType // "UNREPORTED"] | group_by(.) | map({type:.[0], count:length}))} else error("Unexpected SCIM response") end'
# HTH Guide Excerpt: end count-scim-service-account-types
