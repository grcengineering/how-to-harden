#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: openai-ads-3.4
#   guide: https://howtoharden.com/guides/openai-ads/#34-protect-feed-ingestion-and-catalog-lifecycle
#   profile: L2
#   mode: read-only
#   requires: OPENAI_ADS_API_KEY, OPENAI_ADS_FEED_ID, curl, jq
# Sources: https://developers.openai.com/ads/product-feeds
# https://developers.openai.com/ads/openapi.json
# NIST 800-53 AC-6, SI-12. Never prints SFTP location, password or catalog content.
source "$(dirname "$0")/common.sh"
ads_require_key
: "${OPENAI_ADS_FEED_ID:?Choose an independently approved feed}"
[[ "$OPENAI_ADS_FEED_ID" =~ ^fd_[A-Za-z0-9_-]+$ ]] || exit 2
# HTH Guide Excerpt: begin read-feed-access
ads_get "/feeds/${OPENAI_ADS_FEED_ID}/sftp_access" |
  jq -e 'if (.enabled|type == "boolean") then {enabled, authentication_method}
    else error("Unexpected SFTP access response") end'
ads_get "/feeds/${OPENAI_ADS_FEED_ID}/settings" |
  jq '{id, is_eligible_search, is_full_refresh}'
# A missing is_full_refresh is unknown: current prose documents an eligible
# feature that is not yet listed in this OpenAPI settings schema.
# HTH Guide Excerpt: end read-feed-access
