#!/usr/bin/env bash
# HTH Anthropic Claude Control 5.1: Monitor API Usage and Costs
# Profile: L1 | NIST: AU-6, SI-4 | SOC 2: CC7.2
# https://howtoharden.com/guides/anthropic-claude/#51-monitor-api-usage-and-costs
source "$(dirname "$0")/common.sh"

banner "5.1: Monitor API Usage and Costs"
require_admin_key

# HTH Guide Excerpt: begin api-usage-report
# Generate a daily usage report for the past 7 days, grouped by workspace
START_DATE=$(date -d '7 days ago' '+%Y-%m-%dT00:00:00Z' 2>/dev/null || \
             date -v-7d '+%Y-%m-%dT00:00:00Z' 2>/dev/null)
END_DATE=$(date '+%Y-%m-%dT23:59:59Z')

info "Fetching usage report from ${START_DATE} to ${END_DATE}..."
USAGE=$(anthropic_get "/v1/organizations/usage_report/messages?start_time=${START_DATE}&end_time=${END_DATE}&group_by=workspace&bucket_width=1d") || {
  fail "5.1 Failed to fetch usage report"
  summary; exit 0
}

echo "${USAGE}" | jq -r '.data[] | "  \(.workspace_id // "default") | Input: \(.input_tokens) | Output: \(.output_tokens) | Date: \(.bucket_start_time)"'
pass "5.1 Usage report retrieved"
# HTH Guide Excerpt: end api-usage-report

# HTH Guide Excerpt: begin api-cost-report
# Generate a cost report for the past 30 days, grouped by workspace
COST_START=$(date -d '30 days ago' '+%Y-%m-%dT00:00:00Z' 2>/dev/null || \
             date -v-30d '+%Y-%m-%dT00:00:00Z' 2>/dev/null)

info "Fetching cost report from ${COST_START}..."
COST=$(anthropic_get "/v1/organizations/cost_report?start_time=${COST_START}&end_time=${END_DATE}&group_by=workspace") || {
  fail "5.1 Failed to fetch cost report"
  summary; exit 0
}

echo "${COST}" | jq -r '.data[] | "  \(.workspace_id // "default") | Cost: $\(.cost_usd) | Date: \(.bucket_start_time)"'
pass "5.1 Cost report retrieved"
# HTH Guide Excerpt: end api-cost-report

summary
