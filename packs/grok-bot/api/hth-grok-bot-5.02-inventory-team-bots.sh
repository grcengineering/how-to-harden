#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-bot-5.2
#   guide:   https://howtoharden.com/guides/grok-bot/#52-govern-team-bots-their-shared-credentials-and-their-slack-apps
#   profile: L2
#   mode:    read-only
#   requires: CURSOR_ADMIN_API_KEY(Team API key; Enterprise audit logs), HTH_APPROVED_AGENT_IDS(optional, comma-separated agent_id values approved for publishing), HTH_LOOKBACK_DAYS(optional, default 30), HTH_AUDIT_SCOPE(optional team|org), CURSOR_ORG_API_KEY(when HTH_AUDIT_SCOPE=org), CURSOR_TEAM_ID(optional with org), curl, jq
# =============================================================================
# HTH Grok Bot Control 5.2: Govern Team Bots, Their Shared Credentials, and Their Slack Apps
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls v8 3.3, 6.8; NIST 800-53 AC-6, AC-21, IA-5; SOC 2 CC6.1, CC6.3;
#             ISO 27001:2022 A.5.15, A.5.17; OWASP Agentic 2026 ASI01, ASI06, ASI07
# Sources (transcribed from, fetched 2026-10-08):
#   https://cursor.com/docs/account/teams/admin-api#get-audit-logs
#   https://cursor.com/docs/account/organizations/organization-admin-api#get-audit-logs
#   https://cursor.com/docs/enterprise/compliance-and-monitoring#event-types
# Dependencies: curl, jq, ./common.sh
#
# WHY READ-ONLY. The Admin API's Grok Bot section has no Team Bot route and no
# capabilities field that toggles Team Bots; Manage Team Bots and admin delete
# are dashboard-only. The audit log is the only programmatic record of which
# Bots were created, published to the team, given skills, or linked to Slack.
#
# ── TRAP 1: an inventory built from events covers only the window ───────────
# A Bot created and published before HTH_LOOKBACK_DAYS does not appear here. The
# dashboard's Manage Team Bots list is the only complete inventory; use this
# pack to prove every publish IN the window was approved.
#
# ── TRAP 2: the audit log misses half of Team Bot governance ────────────────
# No documented audit event covers Manage Team Bots default assignment, adding
# or removing managers, Team Bot secrets, plugins or files, or creating and
# removing a Team Bot's Slack app. Review those in the dashboard and in Slack's
# app list.
# DOC CONFLICT: changelog V0.57.0 (2026-09-18, x.ai/changelog/bot, read in a
# real browser) says "Audit Logs record more Grok Bot activity, including ...
# plugins ...". The compliance event table has no Grok Bot plugin event. The
# nearest documented events are mcp_authentication ("A member authenticates to,
# disconnects from, or removes an account for an MCP server") and
# mcp_server_config ("A user or team MCP server is configured"); neither is
# documented to fire when a Team Bot's owner or managers change its plugins.
# Current docs win. To confirm live, add and remove a plugin on a test Team Bot,
# then pull those event types.
#
# ── TRAP 3: actor strings ───────────────────────────────────────────────────
# user_email is the actor: a member's email, "Bot: <owner email>" when a Bot
# acted during its owner's turn, "System" when Grok Bot events have no
# identified actor. Field paths here are the Admin API pull's event_data; a
# streamed event nests the same fields under a key named after the event type.
#
# Exit codes: 0 no unapproved publish in the window (the RESULT line names what
# stays unproven, TRAP 1 and TRAP 2) | 1 publishes to review | 2 precondition
# (missing key, plan without audit logs, bad shape)
# =============================================================================

set -euo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# HTH Guide Excerpt: begin inventory-team-bots
verify() {
  local days events published unapproved
  days=$(gb_lookback_days 30)
  events="$(gb_tmp events)"
  gb_audit_pull "grok_bot_created,grok_bot_lifecycle,grok_bot_skill,slack_account_link" "${days}" "${events}"
  echo "Grok Bot 5.2 — Team Bot activity in the last ${days} day(s)"

  echo "  Bots created:"
  jq -r 'select(.event_type == "grok_bot_created")
    | "    \(.timestamp)  \(.event_data.agent_id // "?")  \"\(.event_data.name // "?")\"  source=\(.event_data.source // "?")  by \(.user_email // "unknown")"' "${events}"
  echo "  Publishing, visibility and deletion:"
  jq -r 'select(.event_type == "grok_bot_lifecycle"
                and (.event_data.action | IN("published","unpublished","visibility_changed","delete")))
    | "    \(.timestamp)  \(.event_data.agent_id // "?")  \(.event_data.action)\(if .event_data.new_visibility then " -> \(.event_data.new_visibility)" else "" end)  by \(.user_email // "unknown")"' "${events}"
  echo "  Skill changes:"
  jq -r 'select(.event_type == "grok_bot_skill")
    | "    \(.timestamp)  \(.event_data.agent_id // "?")  \(.event_data.action // "?") \(.event_data.skill_slug // "?")  by \(.user_email // "unknown")"' "${events}"
  echo "  Slack account links:"
  jq -r 'select(.event_type == "slack_account_link")
    | "    \(.timestamp)  \(.user_email // "unknown")  \(.event_data.action // "?")  slack_team=\(.event_data.slack_team_id // "?")  workspace_changed=\(.event_data.workspace_changed // "?")"' "${events}"

  echo "  NOT VERIFIABLE BY API: Manage Team Bots assignment, managers, Team Bot secrets, plugins, files and Slack apps (TRAP 2; see its V0.57.0 conflict)"
  GB_UNPROVEN="Team Bots published before the ${days}-day window, Manage Team Bots assignment, managers, and Team Bot secrets, plugins, files and Slack apps (dashboard and Slack only, TRAP 1 and TRAP 2)"

  # Every publish to the team must map to an approved Bot.
  published=$(jq -r 'select(.event_type == "grok_bot_lifecycle" and .event_data.action == "published") | .event_data.agent_id // "?"' "${events}" | sort -u)
  if [ -z "${published}" ]; then return 0; fi
  if [ -n "${HTH_APPROVED_AGENT_IDS:-}" ]; then
    unapproved=$(jq -rn --arg ok "${HTH_APPROVED_AGENT_IDS}" --arg got "${published}" \
      '($ok | split(",") | map(gsub("^\\s+|\\s+$"; ""))) as $a | $got | split("\n")[] | select(. as $g | $a | index($g) | not)')
  else
    unapproved="${published}"
  fi
  if [ -n "${unapproved}" ]; then
    gb_finding "Bots published to the team without a matching approval: $(echo "${unapproved}" | tr '\n' ' ')"
  fi
}
# HTH Guide Excerpt: end inventory-team-bots

gb_parse_readonly "$@"
gb_require_key "${HTH_AUDIT_SCOPE:-team}"
gb_main verify
