#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-bot-2.4
#   guide:   https://howtoharden.com/guides/grok-bot/#24-set-the-team-execution-on-local-computer-ceiling-to-never-allow
#   profile: L1
#   mode:    mutating
#   requires: CURSOR_ADMIN_API_KEY(Team API key; read:* to verify, admin:* to enforce), curl, jq
# =============================================================================
# HTH Grok Bot Control 2.4: Set the Team Execution on Local Computer Ceiling to Never Allow
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls v8 4.1, 4.8; NIST 800-53 AC-6, CM-7, AC-17; SOC 2 CC6.1, CC6.8;
#             ISO 27001:2022 A.8.1, A.8.9; OWASP Agentic 2026 ASI02, ASI05
# Sources (transcribed from, fetched 2026-10-08):
#   https://cursor.com/docs/account/teams/admin-api#get-grok-bot-capabilities
#   https://cursor.com/docs/account/teams/admin-api#update-grok-bot-capabilities
#   https://x.ai/changelog/bot (V0.37.0, September 3, 2026; read in a real browser, Cloudflare blocks curl)
# Dependencies: curl, jq, ./common.sh
#
# Usage: bash hth-grok-bot-2.04-local-execution-never.sh [verify | enforce [--apply]]
#   enforce --apply sends PATCH /grok-bot/capabilities {"localExecution": "never"}
#
# ── TRAP 1: null is NOT a safe value ────────────────────────────────────────
# localExecution is "Team ceiling for Bots on a member's machine: never, ask,
# always, or null for no ceiling". null means members decide for themselves, so
# verify passes on exactly "never" and nothing else.
#
# ── TRAP 2: "Allow once" versus the ceiling is untested ─────────────────────
# Grok Bot changelog V0.37.0 says "Allow once works even when Execution on this
# computer is set to Never allow". That sentence is about the MEMBER setting;
# whether Allow once also bypasses the TEAM ceiling this pack sets is not
# documented. Test it live on a pilot member before treating "never" as a hard
# stop, and use the 2.4 Sigma rules (shell_command / file_transfer with target
# user_machine) as the detective check either way.
#
# ── TRAP 3: team baseline only; Teams-plan write unconfirmed ────────────────
# No route returns a group tab's ceiling (see the 4.3 pack). The PATCH "Returns
# 403 when a field is not available to the team"; Enterprise is confirmed and
# Teams is not (common.sh TRAP D).
#
# Exit codes: 0 team ceiling is never (the RESULT line names the group tabs as
# not proven, TRAP 3) | 1 finding, dry run with changes, or a write refused
# after a finding | 2 precondition
# =============================================================================

set -euo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# HTH Guide Excerpt: begin verify-local-execution-ceiling
verify() {
  gb_read_capabilities
  local caps="${GB_TMP_DIR}/capabilities.json" value
  if ! jq -e 'has("localExecution") and ((.localExecution == null) or (.localExecution | IN("never","ask","always")))' "${caps}" >/dev/null; then
    echo "PRECONDITION: GET /grok-bot/capabilities has no documented localExecution value — nothing was judged" >&2
    exit 2
  fi
  value=$(jq -r '.localExecution // "null"' "${caps}")
  echo "Grok Bot 2.4 — team localExecution ceiling: ${value}"
  case "${value}" in
    never) ;;
    null)  gb_finding "no team ceiling (localExecution=null): each member decides whether Bots run commands on their own machine" ;;
    *)     gb_finding "team ceiling is '${value}', not 'never': Bots can execute on members' machines" ;;
  esac
  GB_UNPROVEN="group Grok Bot tabs that raise the ceiling (no API reads them; TRAP 3)"
}
# HTH Guide Excerpt: end verify-local-execution-ceiling

# HTH Guide Excerpt: begin enforce-local-execution-ceiling
enforce() {
  local body='{"localExecution": "never"}'
  if [ "${GB_APPLY}" -ne 1 ]; then
    gb_plan PATCH /grok-bot/capabilities "${body}"
    return 0
  fi
  gb_patch team /grok-bot/capabilities "${body}"
  gb_require_2xx "PATCH /grok-bot/capabilities"
  echo "  PATCH /grok-bot/capabilities -> localExecution=$(jq -r '.localExecution // "null"' "${GB_BODY_FILE}")"
}
# HTH Guide Excerpt: end enforce-local-execution-ceiling

gb_parse_mode "$@"
gb_main verify enforce
