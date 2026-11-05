#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: openai-ads-4.1
#   guide: https://howtoharden.com/guides/openai-ads/#41-export-account-audit-records-with-stable-cursors
#   profile: L1
#   mode: read-only
#   requires: OPENAI_ADS_API_KEY, OPENAI_ADS_AUDIT_START(unix seconds), curl, jq
# Source: https://developers.openai.com/ads/api-reference/audit-logs
# NIST 800-53 AU-2, AU-6. Ads OAuth tokens do not authorize this endpoint.
source "$(dirname "$0")/common.sh"
ads_require_key
: "${OPENAI_ADS_AUDIT_START:?Set the reviewed inclusive start time}"
[[ "$OPENAI_ADS_AUDIT_START" =~ ^[0-9]+$ ]] || exit 2
((OPENAI_ADS_AUDIT_START >= 946684800 && OPENAI_ADS_AUDIT_START <= 4102444800)) || exit 2
# HTH Guide Excerpt: begin export-ads-audit
ads_audit_list
# Stage stdout and commit only on exit 0. Overlap the next window, deduplicate
# on audit-log id and retain the same order/filters across cursor pages.
# Export may contain personal identities and changed values: protect the sink.
# HTH Guide Excerpt: end export-ads-audit
