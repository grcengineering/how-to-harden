#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: openai-ads-2.1
#   guide: https://howtoharden.com/guides/openai-ads/#21-enforce-reviewed-spend-and-activation-boundaries
#   profile: L1
#   mode: read-only
#   requires: jq, approved integer ADS_DAILY_AMOUNT_MICROS and latest ADS_EXPECTED_REVISION
# Source: https://developers.openai.com/ads/api-reference/ad-account#set-a-daily-limit
# Native request emitter only; no HTTP call. NIST 800-53 SC-5.
: "${ADS_DAILY_AMOUNT_MICROS:?Set the reviewed cap in account currency micros}"
: "${ADS_EXPECTED_REVISION:?Copy the latest configuration revision from the native GET}"
set -euo pipefail
[[ "$ADS_DAILY_AMOUNT_MICROS" =~ ^[0-9]+$ && "$ADS_EXPECTED_REVISION" =~ ^[0-9]+$ ]] || exit 2
# HTH Guide Excerpt: begin draft-daily-limit
jq -n --argjson amount "$ADS_DAILY_AMOUNT_MICROS" --argjson revision "$ADS_EXPECTED_REVISION" \
  'if $amount <= 1000000000000000 then
    {amount_micros:$amount, expected_revision:$revision}
   else error("Amount exceeds documented maximum") end'
# Native body for POST /ad_account/daily_spend_limit (edit an existing rule).
# Creation/recreation also needs a reviewed start_date from current allowed dates.
# Refresh revision on conflict; never silently retry with a new revision.
# HTH Guide Excerpt: end draft-daily-limit
