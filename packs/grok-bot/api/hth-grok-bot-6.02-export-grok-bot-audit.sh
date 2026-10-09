#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-bot-6.2
#   guide:   https://howtoharden.com/guides/grok-bot/#62-monitor-grok-bot-control-plane-audit-events
#   profile: L2
#   mode:    read-only
#   requires: CURSOR_ADMIN_API_KEY(Team API key; Enterprise audit logs), HTH_LOOKBACK_DAYS(optional, default 1), HTH_AUDIT_OUT(optional JSONL path), HTH_FAIL_ON_FLAGGED(optional, 1 = exit 1 when posture changes are present), HTH_AUDIT_SCOPE(optional team|org), CURSOR_ORG_API_KEY(when HTH_AUDIT_SCOPE=org), CURSOR_TEAM_ID(optional with org), curl, jq
# =============================================================================
# HTH Grok Bot Control 6.2: Monitor Grok Bot Control-Plane Audit Events
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls v8 8.2, 8.9, 8.11; NIST 800-53 AU-2, AU-6, SI-4; SOC 2 CC7.2;
#             ISO 27001:2022 A.8.15, A.8.16
# Sources (transcribed from, fetched 2026-10-08):
#   https://cursor.com/docs/account/teams/admin-api#get-audit-logs
#   https://cursor.com/docs/account/organizations/organization-admin-api#get-audit-logs
#   https://cursor.com/docs/enterprise/compliance-and-monitoring (Log format, Event types, Streaming)
# Dependencies: curl, jq, ./common.sh
#
# Run on a schedule and ship HTH_AUDIT_OUT to the SIEM. This pulls ONLY the
# Grok Bot event set. The generic, all-events export is the Cursor guide's audit
# pack (https://howtoharden.com/guides/cursor/#101-enable-cursor-usage-logging,
# packs/cursor/api/hth-cursor-10.01-export-audit-logs.sh); do not run both
# into the same index without de-duplicating on event_id.
#
# Event set: every row of the docs' Grok Bot table — sand_onboarding,
# grok_bot_created, grok_bot_lifecycle, grok_bot_access_changed,
# grok_bot_team_setup_manifest, grok_bot_group_settings, grok_bot_group_resource,
# grok_bot_resource, grok_bot_skill, grok_bot_machine, grok_bot_vm,
# grok_bot_vm_bulk, grok_bot_routine — plus mcp_authentication and
# slack_account_link. From the docs' "Telemetry export and LLM Gateway" table it
# adds customer_telemetry_destination and customer_telemetry_content_opt_in,
# because the OpenTelemetry destination is the only path for Action Recording
# (6.1) and these rows are the only API-side record of someone deleting,
# disabling or narrowing it. It also pulls team_settings for review (TRAP 3).
#
# ── TRAP 1: select on event_type, never on application_type ─────────────────
# application_type names the ACTING SURFACE: "grok_bot for Grok Bot; cursor for
# Cursor desktop, iOS, CLI, the Agent SDK, cursor.com, and the Admin API", empty
# when unknown. An admin turning Grok Bot on in the dashboard is a
# sand_onboarding row with application_type=cursor. This pack filters by
# event_type and only COUNTS application_type for context.
#
# ── TRAP 2: field paths differ between pull and stream ──────────────────────
# Admin API pulls put event fields under event_data; streamed events (contact
# hi@cursor.com to set up streaming) use the raw shape, with the id and time
# under metadata.id / metadata.timestamp and fields under a key named after the
# event type (for example sand_onboarding.new_completed). Detections written for
# one shape do not match the other.
#
# ── TRAP 3: what is NOT here, and what may be in team_settings ──────────────
# Bot actions (shell commands, browsing, file transfers, connector calls) are
# Action Recording events over OpenTelemetry, not audit rows (6.1). No
# Grok-Bot-specific audit event or documented setting_name covers team
# network-policy changes, the Enforce Auto-review toggle, the PATCH
# /grok-bot/capabilities fields (including actionRecording), Team Secrets,
# Terminate Inactive Computers, or Team Bot managers/secrets/plugins/files/Slack
# apps. The generic team_settings event fires when "A team-wide setting changes,
# including changes made through the Admin API", and its setting_name list is
# "Common names, not an exhaustive list"
# (https://cursor.com/docs/enterprise/compliance-and-monitoring); the Admin API
# docs also say model-access writes log as team_settings under names that list
# does not include. So team-level Grok Bot toggles may land there — unverified
# until a live run. This pack therefore lists every team_settings row whose
# setting_name is NOT one of the documented common names, unflagged and outside
# the HTH_FAIL_ON_FLAGGED count, because no Grok Bot setting_name is documented
# and a keyword guess would be invented.
#
# ── TRAP 4: limits ──────────────────────────────────────────────────────────
# 30-day maximum per request, 500 events per page, 20 requests/minute, oldest
# first, no documented retention. grok_bot_routine trigger_type values are not
# enumerated, so routine create, update and enable are flagged regardless of
# trigger. A routine is edited in place ("open it and choose Edit"), so an
# update can repoint a benign routine at a broad trigger.
#
# ── TRAP 5: telemetry family values are not enumerated ──────────────────────
# customer_telemetry_destination documents enabled_families and
# disabled_families as fields but not their values, so the pack prints them
# verbatim and flags EVERY destination change rather than string-matching a
# family name; a delete and enabled=false are called out by name.
#
# Exit codes: 0 exported (flagged changes are printed for review; the RESULT
# line names what stays unproven) | 1 flagged changes present and
# HTH_FAIL_ON_FLAGGED=1 | 2 precondition
# =============================================================================

set -euo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

GROK_BOT_EVENTS="sand_onboarding,grok_bot_created,grok_bot_lifecycle,grok_bot_access_changed,grok_bot_team_setup_manifest,grok_bot_group_settings,grok_bot_group_resource,grok_bot_resource,grok_bot_skill,grok_bot_machine,grok_bot_vm,grok_bot_vm_bulk,grok_bot_routine,mcp_authentication,slack_account_link,customer_telemetry_destination,customer_telemetry_content_opt_in,team_settings"

# The team_settings setting_name values the docs list as "Common names" (TRAP 3).
DOCUMENTED_TEAM_SETTINGS='["team_hard_limit_dollars","team_hard_limit_per_user_dollars","per_user_monthly_limit_dollars","admin_only_usage_pricing","team_admin_settings","team_name","default_member_billing_tier","scim_require_user_directory","domain_join","require_private_workers","dashboard_analytics_requires_admin","mcp_allowlist_import","no_zdr_model_consent","origin_disabled","origin_allow_public_repos","slack_default_repo","slack_default_branch","slack_default_model","slack_share_summary","slack_share_summary_in_external_channel"]'

# HTH Guide Excerpt: begin export-grok-bot-audit
verify() {
  local days events flagged review count
  days=$(gb_lookback_days 1)
  events="$(gb_tmp events)"
  gb_audit_pull "${GROK_BOT_EVENTS}" "${days}" "${events}"
  count=$(wc -l < "${events}" | tr -d ' ')

  echo "Grok Bot 6.2 — ${count} Grok Bot audit event(s) in the last ${days} day(s)"
  jq -s -r 'group_by(.event_type) | map("    \(.[0].event_type): \(length)") | .[]' "${events}"
  echo "  by acting surface (context only — TRAP 1):"
  jq -s -r 'group_by(.application_type // "") | map("    \(if .[0].application_type == "" or .[0].application_type == null then "(unknown)" else .[0].application_type end): \(length)") | .[]' "${events}"

  # Posture-changing rows, selected by event_type and documented field values only.
  flagged=$(jq -r '
    (if .event_type == "sand_onboarding" then
        "Grok Bot \(if .event_data.new_completed == true then "ENABLED" else "DISABLED" end) for the team"
     elif .event_type == "grok_bot_access_changed" then
        "access \(.event_data.old_mode // "?") -> \(.event_data.new_mode // "?")\(if .event_data.new_mode == "all" then " (WIDENED to every member)" else "" end)"
     elif .event_type == "grok_bot_team_setup_manifest" then
        "team setup manifest \(.event_data.action // "?"): \(.event_data.manifest_id // "?") (\(.event_data.entry_count // "?") entries)"
     elif .event_type == "grok_bot_group_settings" then
        "group \(.event_data.group_name // "?") setting \(.event_data.setting_name // "?") changed"
     elif .event_type == "grok_bot_group_resource" then
        "group \(.event_data.group_name // "?") \(.event_data.resource // "?") \(.event_data.action // "?")"
     elif .event_type == "grok_bot_resource" and .event_data.visibility == "PUBLIC" then
        "\(.event_data.resource_type // "?") \(.event_data.resource_id // "?") is PUBLIC (\(.event_data.action // "?"))"
     elif .event_type == "grok_bot_lifecycle" and .event_data.action == "published" then
        "Bot \(.event_data.agent_id // "?") published to the team"
     elif .event_type == "grok_bot_routine" and (.event_data.action | IN("create","update","enable")) then
        "routine \(.event_data.action) \"\(.event_data.name // "?")\" on Bot \(.event_data.sand_agent_id // "?") trigger=\(.event_data.trigger_type // "?")"
     elif .event_type == "customer_telemetry_destination" then
        "OpenTelemetry destination \(.event_data.action // "?") \(.event_data.destination_id // "?")"
        + (if .event_data.action == "delete" then " — 6.1 export path REMOVED" else "" end)
        + (if .event_data.enabled == false then " — destination DISABLED" else "" end)
        + " enabled_families=\(.event_data.enabled_families | tojson) disabled_families=\(.event_data.disabled_families | tojson)"
     elif .event_type == "customer_telemetry_content_opt_in" then
        (if .event_data.enabled == true then "conversation-content export turned ON (prompts, responses and tool I/O may now leave Cursor; L3 decision)"
         else "conversation-content export turned OFF" end)
     elif .event_type == "grok_bot_machine" and .event_data.action == "register" then
        "local computer registered: \(.event_data.machine_id // "?")"
     elif .event_type == "grok_bot_vm_bulk" then
        "bulk computer operation \(.event_data.action // "?"): target=\(.event_data.target_count // "?") failed=\(.event_data.failed_count // "?")"
     else empty end) as $why
    | "    \(.timestamp)  by \(.user_email // "unknown")  \($why)"' "${events}")

  echo "  posture-changing events (review each):"
  if [ -n "${flagged}" ]; then echo "${flagged}"; else echo "    none"; fi

  # Unflagged review block: team_settings names the docs do not list (TRAP 3).
  review=$(jq -r --argjson known "${DOCUMENTED_TEAM_SETTINGS}" '
    select(.event_type == "team_settings" and ((.event_data.setting_name // "") as $n | $known | index($n) | not))
    | "    \(.timestamp)  by \(.user_email // "unknown")  \(.event_data.setting_name // "?"): \(.event_data.old_value | tojson) -> \(.event_data.new_value | tojson)"' "${events}")
  echo "  undocumented team_settings changes (may include Grok Bot team toggles; unverified, review each):"
  if [ -n "${review}" ]; then echo "${review}"; else echo "    none"; fi

  if [ -n "${HTH_AUDIT_OUT:-}" ]; then
    cp "${events}" "${HTH_AUDIT_OUT}"
    echo "  exported ${count} event(s) as JSONL to ${HTH_AUDIT_OUT}"
  fi
  if [ "${count}" -eq 0 ]; then
    echo "  NOTE: zero events — confirm the window, and that this key belongs to the Enterprise team"
  fi
  if [ -n "${flagged}" ] && [ "${HTH_FAIL_ON_FLAGGED:-0}" = "1" ]; then
    gb_finding "$(wc -l <<<"${flagged}" | tr -d ' ') posture-changing Grok Bot event(s) in the window"
  fi
  GB_UNPROVEN="changes before the ${days}-day window, and Grok Bot toggles that log only as team_settings under an undocumented setting_name (listed above for review, TRAP 3)"
}
# HTH Guide Excerpt: end export-grok-bot-audit

gb_parse_readonly "$@"
gb_require_key "${HTH_AUDIT_SCOPE:-team}"
gb_main verify
