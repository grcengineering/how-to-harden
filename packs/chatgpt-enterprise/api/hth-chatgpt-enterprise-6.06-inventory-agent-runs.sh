#!/usr/bin/env bash
# HTH ChatGPT Enterprise Control 6.2: Inventory Workspace Agent Runs
# Profile: L1 | NIST: AU-2, AU-12 | SOC 2: CC7.2
# https://howtoharden.com/guides/chatgpt-enterprise/#62-minimize-connector-scopes-and-default-to-read-only
#
# OpenAI's Workspace Agents Security Overview (April 29, 2026):
#   "Workspace agent compliance logs include agent lifecycle events, run
#    creation/completion/failure, agent-authored messages, connector call
#    requested/completed events, connector OAuth resolution, skill use,
#    trigger create/update/delete, and memory read/write/delete."
# Source: https://cdn.openai.com/business/workspace-agents-security-overview.pdf
#
# This script pulls the agent run lifecycle events for an inventory window.
# The Compliance API additionally exposes the full configuration of every
# agent and traces for every run — combine both surfaces for a complete
# audit posture.

source "$(dirname "$0")/common.sh"

banner "6.2: Inventory Workspace Agent Runs"
require_compliance_key

AFTER="${AFTER:-$(date -u -v-7d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ)}"
OUT_DIR="${OUT_DIR:-./compliance-conversation-logs}"
mkdir -p "${OUT_DIR}"

# HTH Guide Excerpt: begin api-inventory-runs
# Pull every agent.run lifecycle file since AFTER. These cover run
# creation, completion, and failure per the OpenAI security overview.
info "Listing agent.run events since ${AFTER}..."
LOG_IDS=$(compliance_paginate_log_ids "agent.run" "${AFTER}" 100) || {
  fail "6.2 Failed to list agent.run events"
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
  pass "6.2 Downloaded ${DOWNLOADED} agent.run log file(s) to ${OUT_DIR}"
else
  warn "6.2 No agent.run logs downloaded for window starting ${AFTER}"
fi
# HTH Guide Excerpt: end api-inventory-runs

echo ""
info "Compliance Logs Platform emits ~10-minute windows with p99 < 30 min"
info "event-to-log latency and at-least-once delivery. Deduplicate on"
info "event_id at the consumer. See control 6.6 for the continuous puller."

summary
