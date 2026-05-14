#!/usr/bin/env bash
# HTH ChatGPT Enterprise Control 6.5: Suspend a Workspace Agent
# Profile: L1 | NIST: IR-4(1), CM-3 | SOC 2: CC7.4
# https://howtoharden.com/guides/chatgpt-enterprise/#65-incident-response-suspend-and-investigate
#
# OpenAI documents agent suspension as an admin action in the Global Admin
# Console → Agents and via the Compliance API. As of 2026-05, the public
# Compliance API surface confirms the *capability* but does not enumerate
# the exact REST path in the Compliance Logs Platform cookbook. The
# authoritative reference is the logged-in Enterprise admin's API reference
# at https://chatgpt.com/admin/api-reference — confirm the path there before
# wiring this into automation.
#
# This script performs a defensive precheck — it lists the agent in the
# inventory CSV and prompts the operator to suspend via the admin console
# UI. Replace the placeholder with the verified REST call when available.

source "$(dirname "$0")/common.sh"

banner "6.5: Suspend a Workspace Agent (Incident Response)"

AGENT_ID="${1:-}"
INPUT="${2:-./agents-export.csv}"

if [[ -z "${AGENT_ID}" ]]; then
  echo "Usage: $0 <agent_id> [agents-export.csv]"
  echo "Export agents-export.csv from Global Admin Console → Agents."
  exit 1
fi

# HTH Guide Excerpt: begin api-suspend-agent
if [[ -f "${INPUT}" ]]; then
  match=$(awk -F',' -v id="${AGENT_ID}" '$1 == id { print $0 }' "${INPUT}")
  if [[ -n "${match}" ]]; then
    info "Found agent in inventory:"
    echo "  ${match}"
  else
    warn "6.5 Agent ${AGENT_ID} not found in ${INPUT} — refresh the export"
  fi
fi

cat <<EOF

ACTION REQUIRED (admin console):
  1. Sign in to https://chatgpt.com/admin
  2. Global Admin Console → Agents
  3. Locate agent ID: ${AGENT_ID}
  4. Click Suspend
  5. Record the suspension in your incident ticket

Once the Compliance API suspension endpoint is published in your tenant's
admin API reference, replace this script's manual step with the REST call.

EOF

pass "6.5 Suspension instructions issued for ${AGENT_ID}"
# HTH Guide Excerpt: end api-suspend-agent

summary
