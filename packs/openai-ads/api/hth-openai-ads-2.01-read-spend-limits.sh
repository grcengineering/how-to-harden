#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: openai-ads-2.1
#   guide: https://howtoharden.com/guides/openai-ads/#21-enforce-reviewed-spend-and-activation-boundaries
#   profile: L1
#   mode: read-only
#   requires: OPENAI_ADS_API_KEY(account billing-management permission), curl, jq
# Source: https://developers.openai.com/ads/api-reference/ad-account#list-account-spending-limits
# NIST 800-53 SC-5, AC-6. This reads; it cannot enable an ineligible billing feature.
source "$(dirname "$0")/common.sh"
ads_require_key
# HTH Guide Excerpt: begin read-spend-limits
ads_get '/ad_account/spend_limit_windows' | jq -e '
  if (.data|type == "array") and (.revision == null or (.revision|type == "number"))
  then {revision, earliest_daily_start_date, can_create_daily_limit, daily_limit,
    windows: [.data[] | {window_id, start_date, end_date, amount_micros, status,
      can_edit, can_delete, spent_micros}]}
  else error("Unexpected spending-limit response") end'
# Preserve unknown/missing counters as null. evaluated_at is not spend freshness.
# HTH Guide Excerpt: end read-spend-limits
