#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-bot-5.1
#   guide:   https://howtoharden.com/guides/grok-bot/#51-keep-public-template-sharing-off
#   profile: L1
#   mode:    mutating
#   requires: CURSOR_ADMIN_API_KEY(Team API key; read:* to verify, admin:* to enforce), curl, jq
# =============================================================================
# HTH Grok Bot Control 5.1: Keep Public Template Sharing Off
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls v8 3.3; NIST 800-53 AC-21, AC-3; SOC 2 CC6.1, C1.1;
#             ISO 27001:2022 A.5.14
# Sources (transcribed from, fetched 2026-10-08):
#   https://cursor.com/docs/account/teams/admin-api#get-grok-bot-capabilities
#   https://cursor.com/docs/account/teams/admin-api#update-grok-bot-capabilities
#   https://cursor.com/docs/grok-bot/teams (Public template sharing)
# Dependencies: curl, jq, ./common.sh
#
# Usage: bash hth-grok-bot-5.01-template-sharing.sh [verify | enforce [--apply]]
#   enforce --apply sends PATCH /grok-bot/capabilities {"templateSharing": "team_only"}
#
# ── TRAP 1: null fails ──────────────────────────────────────────────────────
# templateSharing is "all, team_only, none, or null for the team default", and
# the default depends on the plan: "Enterprise teams start with public sharing
# off; other teams start with it allowed." null proves nothing about which one
# applies, so verify treats null as non-compliant.
#
# ── TRAP 2: `none` and the dashboard's Off are not defined ──────────────────
# The API lists `none` but never says what it does, or which value the
# dashboard's Off maps to. The docs say "Off keeps sharing team-only", so the
# pack enforces `team_only`. A live `none` is reported as not judged (exit 2)
# rather than passed, because treating an undocumented value as compliant is an
# unproven verdict; and it is never overwritten, because `none` may be stricter
# than `team_only`. Confirm live that `none` blocks public links, then accept it.
#
# ── TRAP 3: Teams-plan reach is undocumented ────────────────────────────────
# No page says /capabilities works on Teams (common.sh TRAP D). A 401/403 is a
# precondition; verify live on a Teams tenant.
#
# Exit codes: 0 compliant | 1 finding, dry run with changes, or a write refused
# after a finding | 2 precondition (including templateSharing=none, TRAP 2)
# =============================================================================

set -euo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# HTH Guide Excerpt: begin verify-template-sharing
verify() {
  gb_read_capabilities
  local caps="${GB_TMP_DIR}/capabilities.json" value
  if ! jq -e 'has("templateSharing") and ((.templateSharing == null) or (.templateSharing | IN("all","team_only","none")))' "${caps}" >/dev/null; then
    echo "PRECONDITION: GET /grok-bot/capabilities has no documented templateSharing value — nothing was judged" >&2
    exit 2
  fi
  value=$(jq -r '.templateSharing // "null"' "${caps}")
  echo "Grok Bot 5.1 — templateSharing: ${value}"
  case "${value}" in
    team_only) ;;
    none)
      echo "PRECONDITION: templateSharing=none is an undocumented value — confirm live that it blocks public template links before accepting it; not judged, and not overwritten (TRAP 2)" >&2
      exit 2 ;;
    all)  gb_finding "members can publish Bot templates outside the team (templateSharing=all)" ;;
    null) gb_finding "templateSharing=null follows the team default, which is 'allowed' on non-Enterprise teams — set team_only explicitly" ;;
  esac
}
# HTH Guide Excerpt: end verify-template-sharing

# HTH Guide Excerpt: begin enforce-template-sharing
enforce() {
  local body='{"templateSharing": "team_only"}'
  if [ "${GB_APPLY}" -ne 1 ]; then
    gb_plan PATCH /grok-bot/capabilities "${body}"
    return 0
  fi
  gb_patch team /grok-bot/capabilities "${body}"
  gb_require_2xx "PATCH /grok-bot/capabilities"
  echo "  PATCH /grok-bot/capabilities -> templateSharing=$(jq -r '.templateSharing // "null"' "${GB_BODY_FILE}")"
}
# HTH Guide Excerpt: end enforce-template-sharing

gb_parse_mode "$@"
gb_main verify enforce
