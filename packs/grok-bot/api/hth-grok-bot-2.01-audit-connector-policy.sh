#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-bot-2.1
#   guide:   https://howtoharden.com/guides/grok-bot/#21-restrict-the-connectors-every-bot-inherits
#   profile: L1
#   mode:    read-only
#   requires: CURSOR_ADMIN_API_KEY(Team API key; Enterprise audit logs), HTH_LOOKBACK_DAYS(optional, default 30), HTH_AUDIT_SCOPE(optional team|org), CURSOR_ORG_API_KEY(when HTH_AUDIT_SCOPE=org), CURSOR_TEAM_ID(optional with org), curl, jq
# =============================================================================
# HTH Grok Bot Control 2.1: Restrict the Connectors Every Bot Inherits
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls v8 2.5, 4.8; NIST 800-53 CM-7, AC-6, SA-9; SOC 2 CC6.1, CC9.2;
#             ISO 27001:2022 A.5.19, A.5.23; OWASP Agentic 2026 ASI02
# Sources (transcribed from, fetched 2026-10-08):
#   https://cursor.com/docs/account/teams/admin-api#get-audit-logs
#   https://cursor.com/docs/account/organizations/organization-admin-api#get-audit-logs
#   https://cursor.com/docs/enterprise/compliance-and-monitoring#event-types
# Dependencies: curl, jq, ./common.sh
#
# WHY READ-ONLY. The Admin API documents no marketplace, plugin, MCP or
# connector route (https://cursor.com/docs/account/teams/admin-api#grok-bot), so
# connector policy is set in the dashboard (Team Marketplaces, the MCP
# allowlist). What the API CAN do is prove who changed that policy and when:
# every change since the last review should map to an approved request. The
# MCP-allowlist mechanics themselves are Cursor-wide; see
# https://howtoharden.com/guides/cursor/ (MCP allowlist control) rather than
# repeating them here.
#
# ── TRAP 1: MCP allowlist edits may land in the generic team_settings event ──
# The documented team_settings setting_name list includes `mcp_allowlist_import`
# and is explicitly "not an exhaustive list". This pack pulls team_settings and
# keeps every setting_name starting with `mcp_allowlist`, client-side, rather
# than trusting one exact name.
#
# ── TRAP 2: mcp_server_config covers user servers too ───────────────────────
# "A user or team MCP server is configured" — scope is `user` or `team`. Only
# team scope is policy that every Bot on the team inherits, so only team-scope
# rows count as findings; user-scope rows (a member configuring a personal
# server in the editor) print as context. With HTH_AUDIT_SCOPE=org and no
# CURSOR_TEAM_ID, rows from every linked team are pulled, so each line carries
# its team_id.
#
# ── TRAP 3: team_marketplace before/after field names are not documented ────
# The fields are documented only as "plus before and after values for the
# changed install mode, access groups, or source repository", without names.
# The pack prints that event_data verbatim instead of guessing keys.
#
# ── TRAP 4: this proves change, not state ───────────────────────────────────
# Audit logs default to 7 days, cap one request at 30 days, and document no
# retention period. A connector allowed before the window is invisible here;
# only the dashboard shows current state.
#
# Exit codes: 0 no connector-policy change in the window (the RESULT line says
# what stays unproven: policy set before the window and the current marketplace
# state) | 1 changes found (review each) | 2 precondition (missing key, plan
# without audit logs, bad shape)
# =============================================================================

set -euo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# HTH Guide Excerpt: begin audit-connector-policy-changes
verify() {
  local days events changes user_cfg auths
  days=$(gb_lookback_days 30)
  events="$(gb_tmp events)"
  gb_audit_pull "team_marketplace,mcp_server_config,mcp_authentication,team_settings" "${days}" "${events}"
  GB_UNPROVEN="connector policy set before the ${days}-day window, and the current Team Marketplace and MCP allowlist state (dashboard only, TRAP 4)"

  # Team policy changes: marketplace edits, TEAM-scope MCP server configs,
  # MCP-allowlist settings (TRAP 1, TRAP 2).
  changes=$(jq -c 'select(
      .event_type == "team_marketplace"
      or (.event_type == "mcp_server_config" and (.event_data.scope // "") == "team")
      or (.event_type == "team_settings"
          and ((.event_data.setting_name // "") | startswith("mcp_allowlist"))))' "${events}")
  user_cfg=$(jq -c 'select(.event_type == "mcp_server_config" and (.event_data.scope // "") != "team")' "${events}")
  auths=$(jq -c 'select(.event_type == "mcp_authentication")' "${events}")

  echo "Grok Bot 2.1 — connector-policy changes in the last ${days} day(s)"
  if [ -n "${changes}" ]; then
    jq -r '"  \(.timestamp)  team=\(.team_id // "-")  \(.event_type)  by \(.user_email // "unknown")  " +
      (if .event_type == "mcp_server_config" then
         "\(.event_data.action // "?") server=\(.event_data.server_name // "?") type=\(.event_data.server_type // "?") scope=\(.event_data.scope // "?")"
       elif .event_type == "team_settings" then
         "\(.event_data.setting_name): \(.event_data.old_value | tojson) -> \(.event_data.new_value | tojson)"
       else
         (.event_data | tojson)
       end)' <<<"${changes}"
    gb_finding "$(wc -l <<<"${changes}" | tr -d ' ') connector-policy change(s) — map each to an approved request"
  else
    echo "  none"
  fi

  # Context, not findings: personal MCP servers members configured (TRAP 2),
  # and which members connected their accounts to which MCP servers.
  echo "  user-scope MCP server configs in the window: $(if [ -n "${user_cfg}" ]; then wc -l <<<"${user_cfg}" | tr -d ' '; else echo 0; fi)"
  if [ -n "${user_cfg}" ]; then
    jq -r '"    \(.timestamp)  team=\(.team_id // "-")  \(.user_email // "unknown")  \(.event_data.action // "?") server=\(.event_data.server_name // "?") scope=\(.event_data.scope // "?")"' <<<"${user_cfg}"
  fi
  echo "  MCP authentications in the window: $(if [ -n "${auths}" ]; then wc -l <<<"${auths}" | tr -d ' '; else echo 0; fi)"
  if [ -n "${auths}" ]; then
    jq -r '"    \(.timestamp)  team=\(.team_id // "-")  \(.user_email // "unknown")  \(if (.event_data.action // "") == "" then "authenticate" else .event_data.action end)  server=\(.event_data.server_name // "?")  scope=\(.event_data.scope // "?")"' <<<"${auths}"
  fi
}
# HTH Guide Excerpt: end audit-connector-policy-changes

gb_parse_readonly "$@"
gb_require_key "${HTH_AUDIT_SCOPE:-team}"
gb_main verify
