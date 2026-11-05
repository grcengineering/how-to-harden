#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: openai-ads-4.2
#   guide: https://howtoharden.com/guides/openai-ads/#42-bind-signed-lead-delivery-to-its-subscription
#   profile: L2
#   mode: read-only
#   requires: OPENAI_ADS_API_KEY, OPENAI_ADS_EXPECTED_ACCOUNT_ID, curl, jq
# Source: https://developers.openai.com/ads/openapi.json
# NIST 800-53 AC-4, SC-8. List exposes subscription id/status, not signing secrets.
source "$(dirname "$0")/common.sh"
ads_require_key
: "${OPENAI_ADS_EXPECTED_ACCOUNT_ID:?Choose an independently approved ad account ID}"
# HTH Guide Excerpt: begin list-lead-subscriptions
ads_get '/lead_sync_subscriptions' \
  --data-urlencode "ad_account_id=${OPENAI_ADS_EXPECTED_ACCOUNT_ID}" |
  jq -e 'if (.data|type == "array") and .has_more == false
    then [.data[] | {subscription_id, status}]
    else error("Unexpected or incomplete lead subscription response; reconcile before use") end'
# The current GET schema has no cursor request parameter. Refuse has_more=true
# rather than inventing pagination or declaring a partial list complete.
# HTH Guide Excerpt: end list-lead-subscriptions
