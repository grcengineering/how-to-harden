#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: openai-ads-1.2
#   guide: https://howtoharden.com/guides/openai-ads/#12-bind-keys-and-oauth-to-the-intended-account
#   profile: L1
#   mode: read-only
#   requires: OPENAI_ADS_API_KEY, OPENAI_ADS_EXPECTED_ACCOUNT_ID, curl, jq
# Sources: https://developers.openai.com/ads/api-reference/authentication
# https://developers.openai.com/ads/api-partner-setup
# NIST 800-53 AC-3, IA-5. Output excludes account names, URLs and credentials.
source "$(dirname "$0")/common.sh"
ads_require_key
: "${OPENAI_ADS_EXPECTED_ACCOUNT_ID:?Set the independently approved ad account ID}"
# HTH Guide Excerpt: begin verify-account
account=$(ads_get '/ad_account')
jq -e --arg expected "$OPENAI_ADS_EXPECTED_ACCOUNT_ID" \
  '(.id | type == "string") and .id == $expected' <<<"$account" >/dev/null || {
  echo 'Credential belongs to an unexpected or unreadable Ads account' >&2; exit 1;
}
jq '{id, status, currency_code, timezone, review_status: .review.status,
  integrity_review_status: .account_integrity_review.review.status}' <<<"$account"
# A missing review is unknown, not an approval. This does not assess roles/SSO.
# HTH Guide Excerpt: end verify-account
