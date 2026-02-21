#!/usr/bin/env bash
# HTH Anthropic Claude Control 5.2: Configure Spend Limits per Workspace
# Profile: L1 | NIST: SA-9, SI-4 | SOC 2: CC7.2, CC6.8
# https://howtoharden.com/guides/anthropic-claude/#52-configure-spend-limits-per-workspace
#
# Note: Spend limits are configured via the Claude Console (Settings > Limits).
# The Admin API does not currently expose spend limit configuration endpoints.
# This script monitors cost to detect when limits should be adjusted.
source "$(dirname "$0")/common.sh"

banner "5.2: Configure Spend Limits per Workspace"
require_admin_key

# HTH Guide Excerpt: begin api-cost-anomaly
# Check for cost anomalies — alert if any workspace exceeds a threshold
THRESHOLD_USD="${THRESHOLD_USD:-1000}"
PERIOD_DAYS="${PERIOD_DAYS:-7}"

START_DATE=$(date -d "${PERIOD_DAYS} days ago" '+%Y-%m-%dT00:00:00Z' 2>/dev/null || \
             date -v-"${PERIOD_DAYS}"d '+%Y-%m-%dT00:00:00Z' 2>/dev/null)
END_DATE=$(date '+%Y-%m-%dT23:59:59Z')

info "Checking for workspaces exceeding \$${THRESHOLD_USD} in the past ${PERIOD_DAYS} days..."
COST=$(anthropic_get "/v1/organizations/cost_report?start_time=${START_DATE}&end_time=${END_DATE}&group_by=workspace") || {
  fail "5.2 Failed to fetch cost report"
  summary; exit 0
}

# Aggregate cost per workspace
OVER_THRESHOLD=$(echo "${COST}" | jq --argjson threshold "${THRESHOLD_USD}" '
  [.data | group_by(.workspace_id)[] |
   {workspace: .[0].workspace_id, total: ([.[].cost_usd] | add)} |
   select(.total > $threshold)]')

ALERT_COUNT=$(echo "${OVER_THRESHOLD}" | jq 'length')
if [[ "${ALERT_COUNT}" -gt 0 ]]; then
  warn "5.2 ${ALERT_COUNT} workspace(s) exceed \$${THRESHOLD_USD} threshold:"
  echo "${OVER_THRESHOLD}" | jq -r '.[] | "  \(.workspace) — $\(.total)"'
else
  pass "5.2 No workspaces exceed \$${THRESHOLD_USD} threshold in ${PERIOD_DAYS}-day window"
fi
# HTH Guide Excerpt: end api-cost-anomaly

summary
