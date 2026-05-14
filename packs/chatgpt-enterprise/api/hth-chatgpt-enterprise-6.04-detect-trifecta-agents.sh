#!/usr/bin/env bash
# HTH ChatGPT Enterprise Control 6.4: Detect Lethal-Trifecta Agents
# Profile: L2 | NIST: SI-4(2), SI-4(24) | SOC 2: CC7.2
# https://howtoharden.com/guides/chatgpt-enterprise/#64-detect-cross-connector-exfiltration-patterns
#
# The "lethal trifecta" (Simon Willison, June 2025) is the architectural
# pattern behind every confirmed workspace-agent exfiltration PoC to date —
# ShadowLeak, AgentFlayer, ZombieAgent, GeminiJack. It applies when a single
# agent can simultaneously:
#   (a) read private data (Drive / SharePoint / Gmail / Salesforce)
#   (b) ingest untrusted content (emails, web pages, Slack DMs)
#   (c) send data outbound (email, calendar invite, Slack post, web request)
#
# Source: https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/
#
# This script reads a CSV of agents and their connected apps (export from
# Global Admin Console → Agents) and flags any agent whose app set
# intersects all three trifecta categories. The CSV input is required
# because the Compliance API does not enumerate per-agent connector grants.

source "$(dirname "$0")/common.sh"

banner "6.4: Detect Lethal-Trifecta Agents"

INPUT="${1:-./agents-export.csv}"

if [[ ! -f "${INPUT}" ]]; then
  warn "6.4 No agents export at ${INPUT}"
  echo ""
  echo "Export the agent inventory from the Global Admin Console:"
  echo "  Global Admin Console → Agents → Export to CSV"
  echo ""
  echo "Expected columns: agent_id,agent_name,owner_email,connected_apps"
  echo "Where connected_apps is a semicolon-delimited list of app slugs."
  summary
  exit 0
fi

# HTH Guide Excerpt: begin api-detect-trifecta
# Classification of OpenAI apps into the lethal-trifecta dimensions.
# Apps named in OpenAI's Workspace Agents Security Overview (April 29, 2026):
# Slack, Google Drive, SharePoint, Gmail, Calendar, GitHub, Jira, Confluence.
# Additional apps documented in announcement and Help Center coverage:
# Salesforce, Notion, Outlook, OneDrive, Atlassian Rovo, GitLab, Box, Dropbox.
PRIVATE_DATA="gmail|google-drive|sharepoint|google-calendar|github|jira|confluence|outlook|onedrive|salesforce|notion|atlassian-rovo|gitlab|box|dropbox"
UNTRUSTED_INPUT="gmail|outlook|slack|google-calendar|web-search|browser|notion|confluence|jira"
EXTERNAL_SEND="gmail|outlook|slack|google-calendar|web-search|browser|github|gitlab|salesforce"

FLAGGED=0
while IFS=',' read -r agent_id agent_name owner connected_apps; do
  [[ "${agent_id}" == "agent_id" ]] && continue

  has_private=$(echo "${connected_apps}" | grep -cE "${PRIVATE_DATA}" || true)
  has_untrusted=$(echo "${connected_apps}" | grep -cE "${UNTRUSTED_INPUT}" || true)
  has_send=$(echo "${connected_apps}" | grep -cE "${EXTERNAL_SEND}" || true)

  if [[ "${has_private}" -gt 0 && "${has_untrusted}" -gt 0 && "${has_send}" -gt 0 ]]; then
    fail "6.4 TRIFECTA: agent=${agent_name} (${agent_id}) owner=${owner} apps=${connected_apps}"
    FLAGGED=$((FLAGGED+1))
  fi
done < "${INPUT}"

if [[ "${FLAGGED}" -eq 0 ]]; then
  pass "6.4 No trifecta-exposed agents detected"
else
  echo ""
  warn "6.4 ${FLAGGED} agent(s) exposed to the lethal trifecta — require human approval on every external-send action or restrict the connector set"
fi
# HTH Guide Excerpt: end api-detect-trifecta

summary
