#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-bot-3.2
#   guide:   https://howtoharden.com/guides/grok-bot/#32-turn-off-allow-local-egress
#   profile: L2
#   mode:    mutating
#   requires: CURSOR_ADMIN_API_KEY(Team API key; read:* to verify, admin:* to enforce; Enterprise), curl, jq
# =============================================================================
# HTH Grok Bot Control 3.2: Turn Off Allow Local Egress
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls v8 12.2, 13.4; NIST 800-53 SC-7, AC-4, AC-17; SOC 2 CC6.6;
#             ISO 27001:2022 A.8.20, A.8.22
# Sources (transcribed from, fetched 2026-10-08):
#   https://cursor.com/docs/account/teams/admin-api#get-grok-bot-capabilities
#   https://cursor.com/docs/account/teams/admin-api#update-grok-bot-capabilities
#   https://docs.x.ai/grok-bot/settings-and-notifications (what the route changes; re-checked 2026-10-09)
#   https://docs.x.ai/grok-bot/private-networks ("a separate layer that still applies")
# Dependencies: curl, jq, ./common.sh
#
# Usage: bash hth-grok-bot-3.02-disable-local-egress.sh [verify | enforce [--apply]]
#   enforce --apply sends PATCH /grok-bot/capabilities {"localEgressAllowed": false}
#
# ── TRAP 1: Enterprise only, and the field may be refused outright ──────────
# localEgressAllowed is "Whether members can route Grok Bot's web traffic
# through their own computer (Allow Local Egress Routing; Enterprise only)", and
# the PATCH "Returns 403 when local egress routing controls are not enabled for
# the team". A missing field or a 403 is reported as a precondition.
#
# ── TRAP 2: groups can turn it back on, invisibly to this read ──────────────
# No route returns group-level capabilities. A group Grok Bot tab that re-enables
# Allow Local Egress shows only as a grok_bot_group_settings audit event, whose
# setting_name values are not enumerated — run the 4.3 pack and review the group
# tabs in the dashboard.
#
# ── TRAP 3: no audit event names the team toggle ────────────────────────────
# No documented setting_name covers this PATCH. The generic team_settings event
# ("including changes made through the Admin API") may carry it; that is
# unverified, so re-run this pack rather than relying on the audit log.
#
# ── TRAP 4: this is about reach and source identity, not a bypass ───────────
# The settings page says of the desktop route: "Destinations see your desktop's
# IP address, and the Bot can reach networks available from that device." The
# private-networks page says the network policy "is a separate layer that still
# applies". No page says local egress escapes the 3.1 allowlist, so the finding
# text states only what the vendor documents.
#
# Exit codes: 0 team baseline off (the RESULT line names the group tabs as not
# proven, TRAP 2) | 1 finding, dry run with changes, or a write refused after a
# finding | 2 precondition
# =============================================================================

set -euo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# HTH Guide Excerpt: begin verify-local-egress
verify() {
  gb_read_capabilities
  local caps="${GB_TMP_DIR}/capabilities.json"
  if ! jq -e '.localEgressAllowed | type == "boolean"' "${caps}" >/dev/null; then
    echo "PRECONDITION: GET /grok-bot/capabilities has no boolean localEgressAllowed — Allow Local Egress Routing is Enterprise only; nothing was judged" >&2
    exit 2
  fi
  echo "Grok Bot 3.2 — team baseline localEgressAllowed=$(jq -r '.localEgressAllowed' "${caps}")"
  if [ "$(jq -r '.localEgressAllowed' "${caps}")" != "false" ]; then
    gb_finding "members can route Grok Bot's web traffic through their own computer, so destinations see that device's IP address and the Bot can reach networks available from it"
  fi
  echo "  (team baseline only — group tabs can re-enable it; see the 4.3 pack)"
  GB_UNPROVEN="group Grok Bot tabs that re-enable Allow Local Egress (no API reads them; TRAP 2)"
}
# HTH Guide Excerpt: end verify-local-egress

# HTH Guide Excerpt: begin enforce-local-egress
enforce() {
  local body='{"localEgressAllowed": false}'
  if [ "${GB_APPLY}" -ne 1 ]; then
    gb_plan PATCH /grok-bot/capabilities "${body}"
    return 0
  fi
  gb_patch team /grok-bot/capabilities "${body}"
  gb_require_2xx "PATCH /grok-bot/capabilities"
  echo "  PATCH /grok-bot/capabilities -> localEgressAllowed=$(jq -r '.localEgressAllowed' "${GB_BODY_FILE}")"
}
# HTH Guide Excerpt: end enforce-local-egress

gb_parse_mode "$@"
gb_main verify enforce
