#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-bot-4.1
#   guide:   https://howtoharden.com/guides/grok-bot/#41-enforce-auto-review-with-team-ask-first-rules
#   profile: L1
#   mode:    mutating
#   requires: CURSOR_ADMIN_API_KEY(Team API key; read:* to verify, admin:* to enforce; the PUT is Enterprise only), curl, jq
# =============================================================================
# HTH Grok Bot Control 4.1: Enforce Auto-review with Team Ask-First Rules
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls v8 4.1; NIST 800-53 AC-3, AC-6, SI-4; SOC 2 CC6.1, CC8.1;
#             ISO 27001:2022 A.5.15, A.8.9; OWASP Agentic 2026 ASI01, ASI09; OWASP LLM06:2025
# Sources (transcribed from, fetched 2026-10-08):
#   https://cursor.com/docs/account/teams/admin-api#get-enforce-auto-review
#   https://cursor.com/docs/account/teams/admin-api#replace-enforce-auto-review
#   https://cursor.com/docs/grok-bot/teams (Enforce Auto-review)
# Dependencies: curl, jq, ./common.sh
#
# Usage: bash hth-grok-bot-4.01-enforce-auto-review.sh [verify | enforce [--apply]]
#   enforce --apply reads the stored rules, then sends
#   PUT /grok-bot/auto-review {"enforced": true, "rules": {<the same allow/block>}}
#
# ── TRAP 1: the PUT replaces, and empty lists are only safe sometimes ───────
# The PUT is "Replace the team's Enforce Auto-Review policy" with enforced and
# rules both Required. The doc's "Lock Enforce Auto-Review without changing
# instructions" example sends empty lists, but the stated rule is narrower:
# "Empty allow and block lists keep stored instructions if your team can't set
# Auto-Review rules." For a team that CAN set rules, what empty lists do is
# undocumented. So this pack GETs first and re-sends the stored lists — a
# precaution, not a documented requirement.
#
# ── TRAP 2: a 403 on this PUT has two documented causes ─────────────────────
# "Returns 403 when Enforce Auto-Review is not available to the team", and
# "Non-empty lists return 403" when the team cannot set Auto-Review rules. The
# pack does not retry with empty lists on your behalf (TRAP 1); it stops and
# names both causes.
#
# ── TRAP 3: the pack never authors rules ────────────────────────────────────
# The API's `allow` / `block` lists correspond to the UI's "Allow
# automatically" / "Ask first" only by inference; the mapping is undocumented.
# Rule content stays a dashboard decision until a live run confirms it. Up to 20
# instructions per list, 1,000 characters each, "Trimmed and deduped".
#
# ── TRAP 4: groups can opt out; Team Bots depend on this switch ─────────────
# GET returns the TEAM policy only. A group tab's "Don't enforce for this
# group" is invisible here; it shows as a grok_bot_group_settings audit event
# (run the 4.3 pack). Enforcement also decides Team Bots: it covers "Team Bots
# in chats where nobody can answer an approval, such as teammates' chats and
# Slack, which otherwise run without Auto-review" (cursor.com/docs/grok-bot/teams).
# There, an Ask-first action is expected not to run at all rather than raise a
# card — test that in a Slack thread on a pilot team.
#
# ── TRAP 5: enforcement with no team rules is still a finding ───────────────
# The API says the lists are the "Team allow and block instruction lists that
# feed Auto Review". If both are empty, no team instructions feed Auto Review
# under either reading of the allow/block mapping (TRAP 3), so verify flags it.
# An empty `block` list alone is NOT flagged: which list is "Ask first" is only
# inferred.
#
# Exit codes: 0 team lock on with team rules (the RESULT line names group
# opt-outs as not proven, TRAP 4) | 1 finding, dry run with changes, or a write
# refused after a finding | 2 precondition
# =============================================================================

set -euo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

read_auto_review() {
  gb_get team /grok-bot/auto-review
  gb_require "GET /grok-bot/auto-review" 200
  gb_shape '(.enforced | type == "boolean")
            and (.rules.allow | type == "array") and all(.rules.allow[]; type == "string")
            and (.rules.block | type == "array") and all(.rules.block[]; type == "string")' "GET /grok-bot/auto-review"
}

# HTH Guide Excerpt: begin verify-enforce-auto-review
verify() {
  read_auto_review
  echo "Grok Bot 4.1 — enforced=$(jq -r '.enforced' "${GB_BODY_FILE}")" \
       "allow=$(jq '.rules.allow | length' "${GB_BODY_FILE}") block=$(jq '.rules.block | length' "${GB_BODY_FILE}")"
  jq -r '(.rules.block[] | "    block: \(.)"), (.rules.allow[] | "    allow: \(.)")' "${GB_BODY_FILE}"
  if [ "$(jq -r '.enforced' "${GB_BODY_FILE}")" != "true" ]; then
    gb_finding "Enforce Auto-Review is off: members can switch Auto-review off, and Team Bots in Slack and teammates' chats run without it (TRAP 4)"
  fi
  if [ "$(jq '(.rules.allow | length) + (.rules.block | length)' "${GB_BODY_FILE}")" -eq 0 ]; then
    gb_finding "no team Auto-review rules: rules.allow and rules.block are both empty, so no team instructions feed Auto Review. Add 'Ask first' rules with Configure Rules on the Grok Bot page (TRAP 5)"
  fi
  echo "  (team policy only — a group can set \"Don't enforce for this group\"; see the 4.3 pack)"
  GB_UNPROVEN="group opt-outs ('Don't enforce for this group' is not readable by any API — check each group's Grok Bot tab, see 4.3)"
}
# HTH Guide Excerpt: end verify-enforce-auto-review

# HTH Guide Excerpt: begin enforce-auto-review-lock
enforce() {
  local body
  # TRAP 1: re-read right before the PUT and send the stored lists back unchanged.
  read_auto_review
  if [ "$(jq -r '.enforced' "${GB_BODY_FILE}")" = "true" ]; then
    echo "  enforced is already true; team rules are authored in the dashboard (Configure Rules, TRAP 3), so there is nothing to send"
    return 0
  fi
  body=$(jq -c '{enforced: true, rules: {allow: .rules.allow, block: .rules.block}}' "${GB_BODY_FILE}")
  if [ "${GB_APPLY}" -ne 1 ]; then
    gb_plan PUT /grok-bot/auto-review "${body}"
    return 0
  fi
  gb_put team /grok-bot/auto-review "${body}"
  if [ "${GB_CODE}" = "403" ]; then
    echo "PRECONDITION: PUT /grok-bot/auto-review returned 403 — Enforce Auto-Review is not available to this team, or the team cannot set Auto-Review rules and the stored lists are non-empty (TRAP 2)" >&2
    exit 2
  fi
  gb_require_2xx "PUT /grok-bot/auto-review"
  # The response echoes the policy: the instructions must come back as sent.
  if [ "$(jq -S -c '.rules' "${GB_BODY_FILE}")" != "$(jq -S -c '.rules' <<<"${body}")" ]; then
    gb_fail "the PUT changed the stored instructions — compare the dashboard's rules with: $(jq -c '.rules' "${GB_BODY_FILE}")"
  fi
  echo "  PUT /grok-bot/auto-review -> enforced=$(jq -r '.enforced' "${GB_BODY_FILE}"), instructions unchanged"
}
# HTH Guide Excerpt: end enforce-auto-review-lock

gb_parse_mode "$@"
gb_main verify enforce
