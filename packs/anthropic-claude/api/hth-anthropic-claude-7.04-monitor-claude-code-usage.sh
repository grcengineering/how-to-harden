#!/usr/bin/env bash
# HTH Anthropic Claude Control 7.4: Monitor Claude Code Developer Metrics
# Profile: L1 | NIST: AU-6, SI-4 | SOC 2: CC7.2
# https://howtoharden.com/guides/anthropic-claude/#74-monitor-claude-code-developer-metrics
#
# Reads the Claude Code Analytics API (read-only) for one UTC day.
# Reference: platform.claude.com/docs/en/build-with-claude/claude-code-analytics-api
# Exit code: 0 when the full day was retrieved and analysed, 1 on any API failure or when the day
# returned zero records (nothing was monitored, so nothing may be reported as healthy).
source "$(dirname "$0")/common.sh"

banner "7.4: Monitor Claude Code Developer Metrics"
require_admin_key

# HTH Guide Excerpt: begin api-claude-code-analytics
# Fetch per-user Claude Code analytics for a given day
# Usage: set REPORT_DATE (or ANTHROPIC_REPORT_DATE) to YYYY-MM-DD; defaults to yesterday (UTC)
REPORT_DATE="${REPORT_DATE:-${ANTHROPIC_REPORT_DATE:-$(date -u -d 'yesterday' '+%Y-%m-%d' 2>/dev/null || \
                                                       date -u -v-1d '+%Y-%m-%d' 2>/dev/null)}}"
if ! [[ "${REPORT_DATE}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  fail "7.4 REPORT_DATE must be YYYY-MM-DD (got: ${REPORT_DATE})"
  summary; exit 1
fi

# GET one page of the report. The admin key reaches curl as a header file
# (-H @<(...)), never as an argument, so it never appears in `ps` output.
# Returns non-zero on a transport error, a timeout, or any non-200 status.
cc_get() {
  local url="$1" resp code
  resp=$(curl -sS --max-time "${ANTHROPIC_HTTP_TIMEOUT:-30}" -w '\n%{http_code}' "${url}" \
    -H @<(printf 'x-api-key: %s\n' "${ANTHROPIC_ADMIN_KEY}") \
    -H "anthropic-version: ${ANTHROPIC_VERSION}") || return 1
  code="${resp##*$'\n'}"
  resp="${resp%$'\n'*}"
  if [[ "${code}" != "200" ]]; then
    echo "HTTP ${code}: $(printf '%s' "${resp}" | jq -r '.error.message? // empty' 2>/dev/null)" >&2
    return 1
  fi
  printf '%s' "${resp}"
}

# Follow has_more / next_page until the whole day is retrieved (limit max 1000)
info "Fetching Claude Code analytics for ${REPORT_DATE}..."
ALL='[]'; PAGE=""; PAGES=0
while :; do
  QUERY="starting_at=${REPORT_DATE}&limit=1000"
  if [[ -n "${PAGE}" ]]; then
    QUERY="${QUERY}&page=$(jq -rn --arg p "${PAGE}" '$p | @uri')"
  fi
  RESP=$(cc_get "${ANTHROPIC_API_BASE}/v1/organizations/usage_report/claude_code?${QUERY}") || {
    fail "7.4 Failed to fetch Claude Code analytics (page $((PAGES + 1)))"
    summary; exit 1
  }
  if ! printf '%s' "${RESP}" | jq -e '(.data | type) == "array"' >/dev/null 2>&1; then
    fail "7.4 Analytics response has no data array"
    summary; exit 1
  fi
  ALL=$(printf '%s\n%s\n' "${ALL}" "${RESP}" | jq -cs '.[0] + .[1].data')
  PAGES=$((PAGES + 1))
  [[ "$(printf '%s' "${RESP}" | jq -r '.has_more // false')" == "true" ]] || break
  PAGE=$(printf '%s' "${RESP}" | jq -r '.next_page // empty')
  if [[ -z "${PAGE}" ]] || [[ ${PAGES} -ge 1000 ]]; then
    fail "7.4 has_more=true without a usable next_page — refusing to report a partial day"
    summary; exit 1
  fi
done
ANALYTICS=$(printf '%s' "${ALL}" | jq -c '{data: .}')
an() { printf '%s' "${ANALYTICS}" | jq "$@"; }

RECORD_COUNT=$(an '.data | length')
info "Found ${RECORD_COUNT} user records for ${REPORT_DATE} (${PAGES} page(s))"
if [[ "${RECORD_COUNT}" -eq 0 ]]; then
  fail "7.4 0 Claude Code records for ${REPORT_DATE} — no activity was captured; confirm the day had Claude Code use and the key is for the right organization, then re-run with that date"
  summary; exit 1
fi

# Per-user summary (api_actor rows are identified by their API key name)
{
  printf 'USER\tTERMINAL\tSESSIONS\tCOMMITS\tPRS\tLOC_ADD\tLOC_DEL\n'
  an -r '.data[] | [
    (.actor.email_address // .actor.api_key_name // "unknown"),
    (.terminal_type // "n/a"),
    (.core_metrics.num_sessions // 0),
    (.core_metrics.commits_by_claude_code // 0),
    (.core_metrics.pull_requests_by_claude_code // 0),
    (.core_metrics.lines_of_code.added // 0),
    (.core_metrics.lines_of_code.removed // 0)
  ] | @tsv'
} | column -t -s $'\t'

pass "7.4 Claude Code analytics retrieved"
# HTH Guide Excerpt: end api-claude-code-analytics

# HTH Guide Excerpt: begin api-tool-acceptance
# Analyze tool acceptance rates — low acceptance may indicate
# overly permissive settings or developer friction
info "Analyzing tool acceptance rates..."
{
  printf 'USER\tTOOL\tACCEPTED\tREJECTED\tRATE\n'
  an -r '.data[] |
    (.actor.email_address // .actor.api_key_name // "unknown") as $user |
    .tool_actions // {} | to_entries[] |
    [$user, .key, (.value.accepted // 0), (.value.rejected // 0),
     (if ((.value.accepted // 0) + (.value.rejected // 0)) > 0
      then ((.value.accepted // 0) * 100 / ((.value.accepted // 0) + (.value.rejected // 0)) | floor | tostring) + "%"
      else "n/a" end)] | @tsv'
} | column -t -s $'\t'

# Flag users with low acceptance rates (below 70%); only combinations with >5 decisions are assessed
ASSESSED=$(an '[.data[] | .tool_actions // {} | to_entries[] |
  select(((.value.accepted // 0) + (.value.rejected // 0)) > 5)] | length')
LOW_ACCEPTANCE=$(an '[.data[] |
  (.actor.email_address // .actor.api_key_name // "unknown") as $user |
  .tool_actions // {} | to_entries[] |
  {user: $user, tool: .key, accepted: (.value.accepted // 0), rejected: (.value.rejected // 0)} |
  select((.accepted + .rejected) > 5) |
  select((.accepted / (.accepted + .rejected)) < 0.7)]')

LOW_COUNT=$(printf '%s' "${LOW_ACCEPTANCE}" | jq 'length')
if [[ "${ASSESSED}" -eq 0 ]]; then
  warn "7.4 No user/tool combination had more than 5 decisions — acceptance rates not assessed"
elif [[ "${LOW_COUNT}" -gt 0 ]]; then
  warn "7.4 ${LOW_COUNT} of ${ASSESSED} user/tool combinations have <70% acceptance rate — review permission configuration"
else
  pass "7.4 All ${ASSESSED} assessed user/tool combinations have >=70% acceptance"
fi
# HTH Guide Excerpt: end api-tool-acceptance

# HTH Guide Excerpt: begin api-cost-by-model
# Cost breakdown by model across all Claude Code users
info "Cost breakdown by model:"
an -r '[.data[].model_breakdown[]? |
  {model: .model, cost: ((.estimated_cost.amount // 0) / 100)}] |
  group_by(.model) | .[] |
  {model: .[0].model, total_cost: ([.[].cost] | add | . * 100 | round / 100)} |
  "  \(.model): $\(.total_cost)"'

# Total cost for the day
TOTAL_COST=$(an '[.data[].model_breakdown[]?.estimated_cost.amount // 0] | add // 0 | . / 100 | . * 100 | round / 100')
info "Total Claude Code cost for ${REPORT_DATE}: \$${TOTAL_COST}"
pass "7.4 Cost analysis complete"
# HTH Guide Excerpt: end api-cost-by-model

summary
[[ ${FAILED} -eq 0 ]]
