#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-bot-4.3
#   guide:   https://howtoharden.com/guides/grok-bot/#43-audit-group-grok-bot-tabs-for-widening-overrides
#   profile: L2
#   mode:    read-only
#   requires: CURSOR_ADMIN_API_KEY(Team API key; Enterprise audit logs), HTH_LOOKBACK_DAYS(optional, default 30), HTH_AUDIT_SCOPE(optional team|org), CURSOR_ORG_API_KEY(when HTH_AUDIT_SCOPE=org), CURSOR_TEAM_ID(required with org: the team CURSOR_ADMIN_API_KEY belongs to), curl, jq
# =============================================================================
# HTH Grok Bot Control 4.3: Audit Group Grok Bot Tabs for Widening Overrides
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls v8 4.1, 8.11; NIST 800-53 CM-3, CM-6, AU-6; SOC 2 CC7.2, CC8.1;
#             ISO 27001:2022 A.8.9
# Sources (transcribed from, fetched 2026-10-08):
#   https://cursor.com/docs/account/teams/admin-api#get-grok-bot-network-policy
#   https://cursor.com/docs/account/teams/admin-api#get-audit-logs
#   https://cursor.com/docs/enterprise/compliance-and-monitoring#event-types
#   https://cursor.com/docs/enterprise/compliance-and-monitoring#accessing-audit-logs
# Dependencies: curl, jq, ./common.sh
#
# WHY READ-ONLY, AND WHY THIS IS THE ONLY PROOF THERE IS. All 17 Grok Bot routes
# are team-level, the directory-group routes carry no Grok Bot fields, and the
# Organization API has only computer operations — no API reads or writes a
# group's Grok Bot tab. Two things are provable: whether the team network policy
# is locked (locked=true means "group policies cannot override the team
# policy"), and which group settings, Group Rules and Group Setup Scripts
# CHANGED in the window, from the audit log.
#
# ── TRAP 1: change, not state ───────────────────────────────────────────────
# Audit logs default to 7 days, allow at most 30 days per request, return at
# most 500 events per page, and document no retention period. An override set
# before the window is invisible to every API. HTH_LOOKBACK_DAYS walks
# consecutive 30-day windows; a dashboard review of every group's Grok Bot tab
# is still the only proof of current state.
#
# ── TRAP 2: setting_name is not enumerated ──────────────────────────────────
# grok_bot_group_settings carries group_id, group_name, setting_name, old_value
# and new_value, but the docs list no setting_name values. Whether group network
# policy, Cloud Agents, local egress, the local-execution ceiling or "Don't
# enforce" Auto-review edits all land here is undocumented. This pack therefore
# reports EVERY group-settings change and never filters on setting_name.
#
# ── TRAP 3: payloads never carry text ───────────────────────────────────────
# "Grok Bot payloads carry identifiers and changed field names, never content
# such as ... Group Rule or Setup Script text." grok_bot_group_resource tells you
# a Group Rule or Group Setup Script changed (resource rule|setup_manifest), not
# what it now says; read it in the dashboard.
#
# ── TRAP 4: one team at a time ──────────────────────────────────────────────
# With HTH_AUDIT_SCOPE=org, GET /organizations/audit-logs "returns events for
# every linked team plus organization-level events, or one team when you pass
# teamId". The network-lock check covers only the team behind
# CURSOR_ADMIN_API_KEY, so org scope requires CURSOR_TEAM_ID (that same team)
# and the pull is narrowed to it.
#
# Exit codes: 0 network locked and no group change in the window — NOT a
# compliance verdict: group tab state is dashboard-only, and the RESULT line says
# so (TRAP 1) | 1 findings (review each) | 2 precondition (missing key, plan
# without audit logs, bad shape, org scope without CURSOR_TEAM_ID)
# =============================================================================

set -euo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# HTH Guide Excerpt: begin audit-group-overrides
verify() {
  local days events
  echo "Grok Bot 4.3 — group Grok Bot tab overrides"

  # State: the one group override an API can neutralize is network policy.
  gb_get team /grok-bot/network
  gb_require "GET /grok-bot/network" 200
  gb_shape '.locked | type == "boolean"' "GET /grok-bot/network"
  echo "  team network policy locked=$(jq -r '.locked' "${GB_BODY_FILE}")"
  if [ "$(jq -r '.locked' "${GB_BODY_FILE}")" != "true" ]; then
    gb_finding "network policy is not locked: a group's own network policy replaces the team's for its members (fix with the 3.1 pack)"
  fi

  # Change: every group setting, Group Rule and Group Setup Script edit (TRAP 2, TRAP 3).
  days=$(gb_lookback_days 30)
  events="$(gb_tmp events)"
  gb_audit_pull "grok_bot_group_settings,grok_bot_group_resource" "${days}" "${events}"
  echo "  group changes in the last ${days} day(s): $(wc -l < "${events}" | tr -d ' ')"
  jq -r '"    \(.timestamp)  by \(.user_email // "unknown")  group=\(.event_data.group_name // .event_data.group_id // "?")  " +
    (if .event_type == "grok_bot_group_settings" then
       "setting \(.event_data.setting_name // "?"): \(.event_data.old_value | tojson) -> \(.event_data.new_value | tojson)"
     else
       "\(.event_data.resource // "?") \(.event_data.action // "?"): \(.event_data.resource_name // .event_data.resource_id // "?")"
     end)' "${events}"
  if [ -s "${events}" ]; then
    gb_finding "$(wc -l < "${events}" | tr -d ' ') group Grok Bot tab change(s) — each needs a recorded exception, or a revert in the dashboard"
  fi
  echo "  NOT VERIFIABLE BY API: overrides set before the window (TRAP 1) — review every group's Grok Bot tab"
  GB_UNPROVEN="current group Grok Bot tab state (overrides set before the ${days}-day window) — review every group's tab in the dashboard"
}
# HTH Guide Excerpt: end audit-group-overrides

gb_parse_readonly "$@"
gb_require_key "${HTH_AUDIT_SCOPE:-team}"
if [ "${HTH_AUDIT_SCOPE:-team}" = "org" ]; then
  if [ -z "${CURSOR_TEAM_ID:-}" ]; then
    echo "PRECONDITION: HTH_AUDIT_SCOPE=org needs CURSOR_TEAM_ID (the team CURSOR_ADMIN_API_KEY belongs to), so other teams' group changes are not mixed into this team's findings (TRAP 4)" >&2
    exit 2
  fi
  gb_require_team_id
fi
gb_main verify
