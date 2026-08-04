#!/usr/bin/env bash
# HTH ChatGPT Enterprise Control 6.3: Continuously Stream Compliance Logs to SIEM
# Profile: L2 | NIST: AU-6, AU-12 | SOC 2: CC7.2, CC7.3
# https://howtoharden.com/guides/chatgpt-enterprise/#63-stream-compliance-api-logs-to-siem
#
# Compliance Logs Platform retains 30 days. Continuous export is mandatory
# for SOX/HIPAA/PCI scope and for any retention beyond 30 days. This script
# walks every documented event_type, persists each log file as JSONL, and
# advances a checkpoint so re-runs resume from last_end_time.
#
# Forward the OUT_DIR to Splunk via the universal forwarder, to Microsoft
# Sentinel via the Custom Logs DCR, or to any SIEM that ingests JSONL.

source "$(dirname "$0")/common.sh"

banner "6.3: Stream Compliance Logs to SIEM"
require_compliance_key

OUT_DIR="${OUT_DIR:-./compliance-export}"
CHECKPOINT_DIR="${CHECKPOINT_DIR:-./compliance-checkpoints}"
mkdir -p "${OUT_DIR}" "${CHECKPOINT_DIR}"

# Event types documented in OpenAI's Workspace Agents Security Overview
# (April 29, 2026): "agent lifecycle events, run creation/completion/failure,
# agent-authored messages, connector call requested/completed events,
# connector OAuth resolution, skill use, trigger create/update/delete, and
# memory read/write/delete." Plus the general Compliance Logs Platform
# event families documented in the cookbook.
# Sources:
#   https://cdn.openai.com/business/workspace-agents-security-overview.pdf
#   https://developers.openai.com/cookbook/examples/chatgpt/compliance_api/logs_platform
EVENT_TYPES=(
  AUTH_LOG
  CONVERSATION_LOG
  FILE_LOG
  GPT_LOG
  MEMORY_LOG
  USER_LOG
  agent.lifecycle
  agent.run
  agent.message
  connector.call.requested
  connector.call.completed
  connector.oauth.resolved
  skill.used
  trigger.created
  trigger.updated
  trigger.deleted
  memory.read
  memory.write
  memory.delete
)

# HTH Guide Excerpt: begin api-stream-siem
# For each event type, resume from the last checkpoint (or 30 days back on
# first run, the platform retention boundary), pull all available log files,
# download each, then advance the checkpoint to last_end_time.
DEFAULT_START="$(date -u -v-30d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '30 days ago' +%Y-%m-%dT%H:%M:%SZ)"

for event_type in "${EVENT_TYPES[@]}"; do
  cp_file="${CHECKPOINT_DIR}/${event_type}.cursor"
  cursor="${DEFAULT_START}"
  [[ -f "${cp_file}" ]] && cursor="$(cat "${cp_file}")"

  info "Pulling ${event_type} since ${cursor}"
  while :; do
    resp=$(compliance_list_logs "${event_type}" "${cursor}" 100) || {
      fail "6.3 ${event_type} list failed at cursor=${cursor}"
      break
    }

    ids=$(echo "${resp}" | jq -r '.data[].id')
    while IFS= read -r log_id; do
      [[ -z "${log_id}" ]] && continue
      out_file="${OUT_DIR}/${event_type}-${log_id}.jsonl"
      compliance_download_log "${log_id}" > "${out_file}" \
        || warn "6.3 ${event_type} download failed for ${log_id}"
    done <<< "${ids}"

    has_more=$(echo "${resp}" | jq -r '.has_more // false')
    next=$(echo "${resp}" | jq -r '.last_end_time // empty')
    if [[ -n "${next}" ]]; then
      echo "${next}" > "${cp_file}"
      cursor="${next}"
    fi
    [[ "${has_more}" == "true" ]] || break
  done
done

pass "6.3 Continuous export pass complete — schedule via cron every 15 minutes"
# HTH Guide Excerpt: end api-stream-siem

echo ""
info "Recommended cron entry (every 15 minutes):"
info "  */15 * * * * /path/to/hth-chatgpt-enterprise-6.03-stream-to-siem.sh"
info ""
info "OpenAI quote: 'Conversations involving agent tasks will appear in"
info "Compliance API logs, but individual agent actions (such as virtual"
info "computer usage, app requests, chain of thought) will not.'"

summary
