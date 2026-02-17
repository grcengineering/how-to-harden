#!/usr/bin/env bash
# HTH JumpCloud Control 5.1: Enable Directory Insights
# Profile: L1 | NIST: AU-2, AU-6 | CIS: 8.2
# https://howtoharden.com/guides/jumpcloud/#51-enable-directory-insights
source "$(dirname "$0")/common.sh"

banner "5.1: Enable Directory Insights"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "5.1 Enabling Directory Insights and auditing recent events..."

# HTH Guide Excerpt: begin api-enable-directory-insights
# Enable Directory Insights feature
ORG_ID=$(jc_get_v1 "/organizations" | jq -r '.[0].id // empty')
if [ -z "${ORG_ID}" ]; then
  fail "5.1 Unable to determine organization ID"
  increment_failed; summary; exit 0
fi

CURRENT=$(jc_get_v1 "/organizations/${ORG_ID}" | jq -r '.settings.features.directoryInsights.enabled // false')
info "5.1 Directory Insights enabled: ${CURRENT}"

if [ "${CURRENT}" != "true" ]; then
  info "5.1 Enabling Directory Insights..."
  jc_put_v1 "/organizations/${ORG_ID}" '{
    "settings": {
      "features": {
        "directoryInsights": { "enabled": true }
      }
    }
  }' || {
    fail "5.1 Failed to enable Directory Insights"
    increment_failed; summary; exit 0
  }
  pass "5.1 Directory Insights enabled"
fi

# Query recent security-relevant events
START_TIME=$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-7d +%Y-%m-%dT%H:%M:%SZ)
info "5.1 Querying admin events from last 7 days..."

ADMIN_EVENTS=$(jc_insights "/events" "{
  \"service\": [\"directory\"],
  \"start_time\": \"${START_TIME}\",
  \"limit\": 20,
  \"sort\": \"DESC\",
  \"search_term\": {
    \"and\": [
      {\"event_type\": {\"\$in\": [
        \"admin_login_attempt\",
        \"admin_update\",
        \"admin_create\",
        \"organization_update\"
      ]}}
    ]
  }
}") || {
  warn "5.1 Unable to query Directory Insights (may require Platform plan)"
  increment_applied; summary; exit 0
}

EVENT_COUNT=$(echo "${ADMIN_EVENTS}" | jq 'length')
info "5.1 Admin/org events in last 7 days: ${EVENT_COUNT}"

if [ "${EVENT_COUNT}" -gt 0 ]; then
  echo "${ADMIN_EVENTS}" | jq -r '.[:5][] | "  - \(.timestamp): \(.event_type) by \(.initiated_by.email // "unknown")"'
fi

pass "5.1 Directory Insights configured and operational"
increment_applied
# HTH Guide Excerpt: end api-enable-directory-insights

summary
