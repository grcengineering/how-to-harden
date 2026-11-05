#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: openai-ads-3.2
#   guide: https://howtoharden.com/guides/openai-ads/#32-protect-server-conversion-credentials-and-delivery
#   profile: L1
#   mode: mutating
#   requires: jq; --send additionally needs OPENAI_ADS_CONVERSION_KEY and OPENAI_ADS_PIXEL_ID
# Source: https://developers.openai.com/ads/conversions-api#send-events
# NIST 800-53 IA-5, SI-10. Default outputs a native validation request only.
# --send transmits supplied data to OpenAI even though validate_only avoids saving events.
source "$(dirname "$0")/common.sh"
# HTH Guide Excerpt: begin validate-conversions
body=$(jq -ce 'if (.events|type == "array") and (.events|length > 0 and length <= 1000)
  then . + {validate_only:true} else error("Supply 1–1000 approved fixture events") end')
if [[ "${1:-}" != '--send' ]]; then printf '%s\n' "$body"; exit 0; fi
: "${OPENAI_ADS_CONVERSION_KEY:?Inject a server-side Conversions API key}"
: "${OPENAI_ADS_PIXEL_ID:?Set the approved Web data-source Pixel ID}"
[[ "$OPENAI_ADS_PIXEL_ID" =~ ^[A-Za-z0-9_-]+$ ]] || exit 2
base=$(ads_checked_base "${OPENAI_ADS_CONVERSION_BASE_URL:-https://bzr.openai.com}" 'https://bzr.openai.com')
umask 077
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
trap 'exit 1' HUP INT TERM
printf '%s' "$body" > "$work/request"
(( $(wc -c < "$work/request") <= 8388608 )) || { echo 'Conversion request exceeds 8 MiB safety bound' >&2; exit 2; }
status=$(ads_http_to_file "$base" "$OPENAI_ADS_CONVERSION_KEY" \
  "/v1/events?pid=${OPENAI_ADS_PIXEL_ID}" "$work/response" \
  --request POST -H 'Content-Type: application/json' --data-binary "@$work/request")
[[ "$status" == 200 ]] || { echo "Conversion validation failed: HTTP $status; response body withheld" >&2; exit 1; }
cat "$work/response"
# Never change validate_only to false as part of a retry. Browser and server
# senders must retain the same event id AND Pixel ID for the same conversion.
# HTH Guide Excerpt: end validate-conversions
