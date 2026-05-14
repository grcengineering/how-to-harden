#!/usr/bin/env bash
# HTH ChatGPT Enterprise Control 6.2: Inventory Workspace Agent Runs
# Profile: L1 | NIST: AU-2, AU-12 | SOC 2: CC7.2
# https://howtoharden.com/guides/chatgpt-enterprise/#62-stream-compliance-api-logs-to-siem
#
# OpenAI quote: "Conversations involving agent tasks will appear in
# Compliance API logs, but individual agent actions (such as virtual computer
# usage, app requests, chain of thought) will not."
# Source: https://help.openai.com/en/articles/9261474-compliance-apis-for-enterprise-customers
#
# CONVERSATION_LOG is therefore the primary surface for agent run inventory.
# Per-step app actions must be reviewed in the Global Admin Console → Agents
# page on a per-agent basis.

source "$(dirname "$0")/common.sh"

banner "6.2: Inventory Workspace Agent Runs"
require_compliance_key

AFTER="${AFTER:-$(date -u -v-7d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ)}"
OUT_DIR="${OUT_DIR:-./compliance-conversation-logs}"
mkdir -p "${OUT_DIR}"

# HTH Guide Excerpt: begin api-inventory-runs
# Pull every CONVERSATION_LOG file since AFTER. Agent-triggered conversations
# appear in this stream alongside human-driven conversations; downstream
# parsers can filter by agent metadata once OpenAI documents the field names.
info "Listing CONVERSATION_LOG events since ${AFTER}..."
LOG_IDS=$(compliance_paginate_log_ids "CONVERSATION_LOG" "${AFTER}" 100) || {
  fail "6.2 Failed to list CONVERSATION_LOG events"
  summary; exit 0
}

DOWNLOADED=0
while IFS= read -r log_id; do
  [[ -z "${log_id}" ]] && continue
  out_file="${OUT_DIR}/${log_id}.jsonl"
  if compliance_download_log "${log_id}" > "${out_file}"; then
    DOWNLOADED=$((DOWNLOADED+1))
  else
    warn "6.2 Failed to download ${log_id}"
  fi
done <<< "${LOG_IDS}"

if [[ "${DOWNLOADED}" -gt 0 ]]; then
  pass "6.2 Downloaded ${DOWNLOADED} conversation log file(s) to ${OUT_DIR}"
else
  warn "6.2 No conversation logs downloaded for window starting ${AFTER}"
fi
# HTH Guide Excerpt: end api-inventory-runs

echo ""
info "Compliance Logs Platform retains 30 days. Forward to your SIEM for"
info "longer retention. See control 6.2 in the guide for a continuous pull."

summary
