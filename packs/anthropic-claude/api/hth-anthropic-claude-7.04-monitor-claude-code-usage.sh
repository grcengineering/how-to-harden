#!/usr/bin/env bash
# HTH Anthropic Claude Control 7.4: Monitor Claude Code Developer Metrics
# Profile: L1 | NIST: AU-6, SI-4 | SOC 2: CC7.2
# https://howtoharden.com/guides/anthropic-claude/#74-monitor-claude-code-developer-metrics
source "$(dirname "$0")/common.sh"

banner "7.4: Monitor Claude Code Developer Metrics"
require_admin_key

# HTH Guide Excerpt: begin api-claude-code-analytics
# Fetch per-user Claude Code analytics for a given day
# Usage: Set REPORT_DATE (YYYY-MM-DD) or defaults to yesterday
REPORT_DATE="${REPORT_DATE:-$(date -d 'yesterday' '+%Y-%m-%d' 2>/dev/null || \
                              date -v-1d '+%Y-%m-%d' 2>/dev/null)}"

info "Fetching Claude Code analytics for ${REPORT_DATE}..."
ANALYTICS=$(anthropic_get "/v1/organizations/usage_report/claude_code?starting_at=${REPORT_DATE}&limit=100") || {
  fail "7.4 Failed to fetch Claude Code analytics"
  summary; exit 0
}

RECORD_COUNT=$(echo "${ANALYTICS}" | jq '.data | length')
info "Found ${RECORD_COUNT} user records for ${REPORT_DATE}"

# Per-user summary
echo "${ANALYTICS}" | jq -r '.data[] | [
  (.actor.email_address // .actor.api_key_name // "unknown"),
  (.terminal_type // "n/a"),
  (.core_metrics.num_sessions // 0),
  (.core_metrics.commits_by_claude_code // 0),
  (.core_metrics.pull_requests_by_claude_code // 0),
  (.core_metrics.lines_of_code.added // 0),
  (.core_metrics.lines_of_code.removed // 0)
] | @tsv' | column -t -s $'\t' -N "USER,TERMINAL,SESSIONS,COMMITS,PRS,LOC_ADD,LOC_DEL"

pass "7.4 Claude Code analytics retrieved"
# HTH Guide Excerpt: end api-claude-code-analytics

# HTH Guide Excerpt: begin api-tool-acceptance
# Analyze tool acceptance rates — low acceptance may indicate
# overly permissive settings or developer friction
info "Analyzing tool acceptance rates..."
echo "${ANALYTICS}" | jq -r '.data[] |
  .actor.email_address as $user |
  .tool_actions // {} | to_entries[] |
  [$user, .key, (.value.accepted // 0), (.value.rejected // 0),
   (if ((.value.accepted // 0) + (.value.rejected // 0)) > 0
    then ((.value.accepted // 0) * 100 / ((.value.accepted // 0) + (.value.rejected // 0)) | floor | tostring) + "%"
    else "n/a" end)] | @tsv' | column -t -s $'\t' -N "USER,TOOL,ACCEPTED,REJECTED,RATE"

# Flag users with low acceptance rates (below 70%)
LOW_ACCEPTANCE=$(echo "${ANALYTICS}" | jq '[.data[] |
  .actor.email_address as $user |
  .tool_actions // {} | to_entries[] |
  {user: $user, tool: .key, accepted: (.value.accepted // 0), rejected: (.value.rejected // 0)} |
  select((.accepted + .rejected) > 5) |
  select((.accepted / (.accepted + .rejected)) < 0.7)]')

LOW_COUNT=$(echo "${LOW_ACCEPTANCE}" | jq 'length')
if [[ "${LOW_COUNT}" -gt 0 ]]; then
  warn "7.4 ${LOW_COUNT} user/tool combinations have <70% acceptance rate — review permission configuration"
else
  pass "7.4 All tool acceptance rates are healthy (>=70%)"
fi
# HTH Guide Excerpt: end api-tool-acceptance

# HTH Guide Excerpt: begin api-cost-by-model
# Cost breakdown by model across all Claude Code users
info "Cost breakdown by model:"
echo "${ANALYTICS}" | jq -r '[.data[].model_breakdown[]? |
  {model: .model, cost: ((.estimated_cost.amount // 0) / 100)}] |
  group_by(.model) | .[] |
  {model: .[0].model, total_cost: ([.[].cost] | add | . * 100 | round / 100)} |
  "  \(.model): $\(.total_cost)"'

# Total cost for the day
TOTAL_COST=$(echo "${ANALYTICS}" | jq '[.data[].model_breakdown[]?.estimated_cost.amount // 0] | add // 0 | . / 100 | . * 100 | round / 100')
info "Total Claude Code cost for ${REPORT_DATE}: \$${TOTAL_COST}"
pass "7.4 Cost analysis complete"
# HTH Guide Excerpt: end api-cost-by-model

summary
