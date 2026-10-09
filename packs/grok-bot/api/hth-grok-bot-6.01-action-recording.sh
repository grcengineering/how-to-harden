#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-bot-6.1
#   guide:   https://howtoharden.com/guides/grok-bot/#61-turn-on-action-recording-and-export-it-over-opentelemetry
#   profile: L2
#   mode:    mutating
#   requires: CURSOR_ADMIN_API_KEY(Team API key; read:* to verify, admin:* to enforce; Enterprise), curl, jq
# =============================================================================
# HTH Grok Bot Control 6.1: Turn On Action Recording and Export It over OpenTelemetry
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls v8 8.2, 8.5, 8.9; NIST 800-53 AU-2, AU-3, AU-12, SI-4;
#             SOC 2 CC7.2, CC7.3; ISO 27001:2022 A.8.15, A.8.16; OWASP Agentic 2026 ASI10
# Sources (transcribed from, fetched 2026-10-08):
#   https://cursor.com/docs/account/teams/admin-api#get-grok-bot-capabilities
#   https://cursor.com/docs/account/teams/admin-api#update-grok-bot-capabilities
#   https://cursor.com/docs/enterprise/opentelemetry-export
#   https://cursor.com/docs/enterprise/opentelemetry-export/wire
#   https://cursor.com/docs/enterprise/compliance-and-monitoring (What is not logged; Telemetry export and LLM Gateway events)
# Dependencies: curl, jq, ./common.sh
#
# Usage: bash hth-grok-bot-6.01-action-recording.sh [verify | enforce [--apply]]
#   enforce --apply sends PATCH /grok-bot/capabilities {"actionRecording": true}
#
# ── TRAP 1: half of this control has no API ─────────────────────────────────
# Action Recording is a capability field. Where the records GO is not: the
# OpenTelemetry destination is configured in "Team Settings > OpenTelemetry
# Export" (Enterprise), and neither the team Admin API, the Organization API nor
# the API overview documents an OpenTelemetry route. With actionRecording=true
# and no destination, nothing leaves Cursor. The pack says so on every run, and
# its RESULT line reads "NOT proven: the OpenTelemetry destination" instead of
# "compliant". The only API-side drift signal is the audit log:
# customer_telemetry_destination (created, updated or deleted, with enabled,
# enabled_families and disabled_families) and customer_telemetry_content_opt_in,
# which the 6.2 pack pulls and flags. A destination deleted or misconfigured
# before that pack's window is not visible that way.
#
# ── TRAP 2: recorded actions are NOT in the audit log ───────────────────────
# Changelog V0.30.0 said Action Recording "records members' Grok Bot actions to
# your team's audit log". The current docs say the opposite: shell commands and
# browser navigation are "Action Recording events, delivered over OpenTelemetry
# Export", listed under "What is not logged". The current docs win; do not look
# for these events in GET /teams/audit-logs.
#
# ── TRAP 3: route on the log event name, not the body ───────────────────────
# Family grok_bot_agent_actions is "On (needs Action Recording)". A shell
# command arrives as event cursor.grok_bot.shell_command whose body is the
# constant `grok_bot_shell_command`; the collector receives these with
# cursor.surface=grok_bot. Validate with one test command from a pilot Bot.
#
# Exit codes: 0 Action Recording on (the RESULT line names the OpenTelemetry
# destination as not proven, TRAP 1) | 1 finding, dry run with changes, or a
# write refused after a finding | 2 precondition
# =============================================================================

set -euo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# HTH Guide Excerpt: begin verify-action-recording
verify() {
  gb_read_capabilities
  local caps="${GB_TMP_DIR}/capabilities.json"
  if ! jq -e '.actionRecording | type == "boolean"' "${caps}" >/dev/null; then
    echo "PRECONDITION: GET /grok-bot/capabilities has no boolean actionRecording — nothing was judged" >&2
    exit 2
  fi
  echo "Grok Bot 6.1 — actionRecording=$(jq -r '.actionRecording' "${caps}")"
  if [ "$(jq -r '.actionRecording' "${caps}")" != "true" ]; then
    gb_finding "Action Recording is off: no record exists of the commands, browsing, file transfers or connector calls Bots make"
  fi
  echo "  NOT VERIFIABLE BY API: the OpenTelemetry destination (Team Settings > OpenTelemetry Export)."
  echo "  Confirm a destination exists with the grok_bot_agent_actions family on, and that your"
  echo "  collector receives cursor.grok_bot.* log events with cursor.surface=grok_bot (TRAP 1, TRAP 3)."
  echo "  Drift signal: customer_telemetry_destination / customer_telemetry_content_opt_in audit rows (6.2 pack)."
  GB_UNPROVEN="the OpenTelemetry destination and its grok_bot_agent_actions family (Team Settings only; watch customer_telemetry_* in the 6.2 pack)"
}
# HTH Guide Excerpt: end verify-action-recording

# HTH Guide Excerpt: begin enforce-action-recording
enforce() {
  local body='{"actionRecording": true}'
  if [ "${GB_APPLY}" -ne 1 ]; then
    gb_plan PATCH /grok-bot/capabilities "${body}"
    return 0
  fi
  gb_patch team /grok-bot/capabilities "${body}"
  gb_require_2xx "PATCH /grok-bot/capabilities"
  echo "  PATCH /grok-bot/capabilities -> actionRecording=$(jq -r '.actionRecording' "${GB_BODY_FILE}")"
}
# HTH Guide Excerpt: end enforce-action-recording

gb_parse_mode "$@"
gb_main verify enforce
