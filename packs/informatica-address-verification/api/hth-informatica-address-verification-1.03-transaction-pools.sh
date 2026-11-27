#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: informatica-address-verification-1.3
#   guide: https://howtoharden.com/guides/informatica-address-verification/#13-review-one-dqc-accounts-available-transaction-pools
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq, approved DQC credentials for the documented EU reporting endpoint
# Source (checked 2026-11-27): https://docs.informatica.com/data-as-a-service/address-verification-%28cloud%29/6-8-0/developer-guide/part-1--cloud-operations/rest-call-creation/request-format/transaction-reporting-example.html
# Review locally; protect evidence from unnecessary disclosure.

# HTH Guide Excerpt: begin informatica-address-verification-evidence
set +x
set -euo pipefail
: "${HTH_ADDRESS_DQC_LOGIN:?Set the account ID for the approved DQC integration.}"
: "${HTH_ADDRESS_DQC_PASSWORD:?Set the DQC service password using your secret manager.}"
printf '%s\0%s' "$HTH_ADDRESS_DQC_LOGIN" "$HTH_ADDRESS_DQC_PASSWORD" |
  jq -Rsc 'split("\u0000") | {Login:.[0], Password:.[1]}' |
  curl -q --silent --show-error --fail --proto '=https' --tlsv1.2 --connect-timeout 10 --max-time 30 \
    --header 'Content-Type: application/json' --data-binary @- \
    'https://eu-av.informaticadaas.com/AV6/v1/getTransactionDetails' |
  jq -es '
    if length != 1 or (.[0] | type) != "array" then error("Expected transaction-report array") else .[0] end
    | if length == 0 or (all(.[]; (.TransactionType | type) == "string"
        and (.PoolType | IN("TEST","PRODUCTION")) and (.UsedTransactions | type) == "number") | not)
      then error("Transaction pools unavailable or invalid")
      else {pool_entry_count:length, transaction_pools:(map(.PoolType) | unique)} end'
# HTH Guide Excerpt: end informatica-address-verification-evidence
