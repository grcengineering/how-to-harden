#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-bot-2.3
#   guide:   https://howtoharden.com/guides/grok-bot/#23-disable-cloud-agent-delegation-unless-needed
#   profile: L1
#   mode:    mutating
#   requires: CURSOR_ADMIN_API_KEY(Team API key; read:* to verify, admin:* to enforce), curl, jq
# =============================================================================
# HTH Grok Bot Control 2.3: Disable Cloud Agent Delegation Unless Needed
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls v8 4.8; NIST 800-53 CM-7, AC-6; SOC 2 CC6.1;
#             ISO 27001:2022 A.8.9; OWASP Agentic 2026 ASI02
# Sources (transcribed from, fetched 2026-10-08):
#   https://cursor.com/docs/account/teams/admin-api#get-grok-bot-capabilities
#   https://cursor.com/docs/account/teams/admin-api#update-grok-bot-capabilities
# Dependencies: curl, jq, ./common.sh
#
# Usage: bash hth-grok-bot-2.03-disable-cloud-agents.sh [verify | enforce [--apply]]
#   enforce --apply sends PATCH /grok-bot/capabilities {"cloudAgents": false}
#
# Cloud Agent settings themselves (what a delegated agent may do) are a
# Cursor-wide control: https://howtoharden.com/guides/cursor/ (Cloud Agents).
#
# ── TRAP 1: this reads the TEAM baseline only ───────────────────────────────
# No route returns a group Grok Bot tab's capability overrides, so a group that
# re-allows Cloud Agents is invisible here. Run the 4.3 pack
# (hth-grok-bot-4.03-audit-group-overrides.sh) for grok_bot_group_settings
# events, and review the group tabs in the dashboard.
#
# ── TRAP 2: Teams-plan reach is unconfirmed ─────────────────────────────────
# /capabilities is not in the documented every-plan read list, and the PATCH
# "Returns 403 when a field is not available to the team". Enterprise is
# confirmed; on Teams, a 401/403 is reported as a precondition.
#
# ── TRAP 3: PATCH semantics ─────────────────────────────────────────────────
# "Omitted fields stay unchanged", `enabled` is read-only (sending it returns
# 400), and an empty PATCH returns 400. The body carries exactly one field.
#
# Exit codes: 0 team baseline off (the RESULT line names the group tabs as not
# proven, TRAP 1) | 1 finding, dry run with changes, or a write refused after a
# finding | 2 precondition
# =============================================================================

set -euo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# HTH Guide Excerpt: begin verify-cloud-agent-delegation
verify() {
  gb_read_capabilities
  local caps="${GB_TMP_DIR}/capabilities.json"
  if ! jq -e '.cloudAgents | type == "boolean"' "${caps}" >/dev/null; then
    echo "PRECONDITION: GET /grok-bot/capabilities has no boolean cloudAgents — nothing was judged" >&2
    exit 2
  fi
  echo "Grok Bot 2.3 — team baseline cloudAgents=$(jq -r '.cloudAgents' "${caps}")"
  if [ "$(jq -r '.cloudAgents' "${caps}")" != "false" ]; then
    gb_finding "members can delegate Grok Bot work to Cloud Agents (cloudAgents=true)"
  fi
  echo "  (team baseline only — group tabs can re-allow it; see the 4.3 pack)"
  GB_UNPROVEN="group Grok Bot tabs that re-allow Cloud Agents (no API reads them; TRAP 1)"
}
# HTH Guide Excerpt: end verify-cloud-agent-delegation

# HTH Guide Excerpt: begin enforce-cloud-agent-delegation
enforce() {
  local body='{"cloudAgents": false}'
  if [ "${GB_APPLY}" -ne 1 ]; then
    gb_plan PATCH /grok-bot/capabilities "${body}"
    return 0
  fi
  gb_patch team /grok-bot/capabilities "${body}"
  gb_require_2xx "PATCH /grok-bot/capabilities"
  echo "  PATCH /grok-bot/capabilities -> cloudAgents=$(jq -r '.cloudAgents' "${GB_BODY_FILE}")"
}
# HTH Guide Excerpt: end enforce-cloud-agent-delegation

gb_parse_mode "$@"
gb_main verify enforce
