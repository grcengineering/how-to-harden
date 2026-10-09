#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-bot-1.1
#   guide:   https://howtoharden.com/guides/grok-bot/#11-limit-grok-bot-to-approved-groups
#   profile: L1
#   mode:    mutating
#   requires: CURSOR_ADMIN_API_KEY(Team API key; read:* to verify, admin:* to enforce), HTH_APPROVED_GROUP_IDS(required to judge a limited policy and to enforce; mode=all is a finding without it; comma-separated group_… billing-group ids), HTH_PLAN(optional: teams = report the expected mode=all as not judged by API), curl, jq
# =============================================================================
# HTH Grok Bot Control 1.1: Limit Grok Bot to Approved Groups
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls v8 6.1, 6.7; NIST 800-53 AC-2, AC-3; SOC 2 CC6.1, CC6.2;
#             ISO 27001:2022 A.5.15, A.5.18; OWASP Agentic 2026 ASI03
# Sources (transcribed from, fetched 2026-10-08):
#   https://cursor.com/docs/account/teams/admin-api#get-grok-bot-access
#   https://cursor.com/docs/account/teams/admin-api#update-grok-bot-access
#   https://cursor.com/docs/account/teams/admin-api#get-grok-bot-capabilities
#   https://cursor.com/docs/account/teams/admin-api#list-groups
#   https://cursor.com/docs/account/teams/admin-api#billing-groups (re-checked 2026-10-09)
# Dependencies: curl, jq, ./common.sh
#
# Usage: bash hth-grok-bot-1.01-limit-access.sh [verify | enforce [--apply]]
#   verify            read GET /grok-bot/access (+ /capabilities when readable)
#   enforce           dry run: validate HTH_APPROVED_GROUP_IDS against
#                     GET /teams/groups and print the PUT it would send
#   enforce --apply   PUT /grok-bot/access {"mode":"limited","groupIds":[…]},
#                     then verify again
#
# ── TRAP 1: the API's "groups" are BILLING groups ───────────────────────────
# PUT /grok-bot/access takes `limited` "for selected billing groups", with
# groupIds "from List Groups" (GET /teams/groups, group_… ids). Billing groups
# and Team directory groups (team_group_… ids) "do not accept each other's ids",
# a member "can only be in one billing group at a time", and billing groups are
# documented for Enterprise admins. The dashboard's Manage Group Access is
# documented as linking to Members > Groups. Which group type the dashboard
# picker lists is undocumented — confirm it live before relying on either path.
#
# ── TRAP 2: /access is readable on every plan, /capabilities is not ─────────
# The Grok Bot section lists only /access, /network and /auto-review as "Reads on
# every plan". This pack reads /capabilities (for `enabled`) opportunistically
# and carries on without it when the key or plan is refused.
#
# ── TRAP 3: on Cursor Teams there is no enable switch and no group limit ────
# A Teams admin limits Grok Bot through team membership and assignment of the
# Cursor app in the IdP (dashboard and IdP, no Grok Bot API). The vendor:
# "There is no switch to turn it off." mode=all is therefore expected on Teams
# and no API call can change it. With HTH_PLAN=teams the pack reports mode=all
# as not judged by API (exit 2) and points to the membership and IdP review;
# without it, mode=all is a finding. Whether a Teams key can call the PUT at all
# is contradictory in Cursor's docs (common.sh TRAP D).
#
# ── TRAP 4: 400s the API documents for this PUT ─────────────────────────────
# "Unknown or malformed IDs, an empty limited list, or group IDs with `all`
# return 400." groupIds must hold 1-100 ids. The pack checks all of that before
# sending anything.
#
# ── TRAP 5: a limited policy can still reach everyone ───────────────────────
# "Members can only be in one billing group at a time. Members not assigned to
# any group are placed in a reserved Unassigned group." Billing groups
# partition the team, so a limited list that names every billing group reaches
# every member outside Unassigned. A limited policy is judged only against
# HTH_APPROVED_GROUP_IDS; without that list verify exits 2 (nothing judged).
#
# Exit codes: 0 compliant | 1 finding, dry run with changes, or a write refused
# after a finding | 2 precondition (including a limited policy with no
# HTH_APPROVED_GROUP_IDS, and mode=all with HTH_PLAN=teams)
# =============================================================================

set -euo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

approved_ids_json() { # HTH_APPROVED_GROUP_IDS -> unique JSON array
  jq -nc --arg s "${HTH_APPROVED_GROUP_IDS:-}" \
    '$s | split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0)) | unique'
}

# HTH Guide Excerpt: begin verify-grok-bot-access
verify() {
  echo "Grok Bot 1.1 — who can use Grok Bot"

  # `enabled` lives on /capabilities, which is not an every-plan read (TRAP 2).
  gb_get team /grok-bot/capabilities
  if [ "${GB_CODE}" = "200" ] && jq -e '.enabled | type == "boolean"' "${GB_BODY_FILE}" >/dev/null; then
    echo "  enabled: $(jq -r '.enabled' "${GB_BODY_FILE}")"
    if [ "$(jq -r '.enabled' "${GB_BODY_FILE}")" = "false" ]; then
      echo "  Grok Bot is disabled for the team: no member has access, whatever the access mode says."
      return 0
    fi
  else
    echo "  enabled: not readable with this key/plan (HTTP ${GB_CODE}); judging on /access alone"
  fi

  gb_get team /grok-bot/access
  gb_require "GET /grok-bot/access" 200
  gb_shape '(.mode | IN("all","limited")) and (.groups | type == "array")' "GET /grok-bot/access"
  local mode
  mode=$(jq -r '.mode' "${GB_BODY_FILE}")
  echo "  mode: ${mode}"
  jq -r '.groups[] | "    - \(.id)  \(.name)"' "${GB_BODY_FILE}"

  if [ "${mode}" = "all" ]; then
    if [ "${HTH_PLAN:-}" = "teams" ]; then
      echo "PRECONDITION: mode=all is expected on self-serve Teams, which has no group limit and no switch (TRAP 3) — not judged by API; review the team member list and the IdP's Cursor app assignment instead" >&2
      exit 2
    fi
    gb_finding "Grok Bot access mode is 'all' — every team member can use it. On Enterprise, limit it to approved billing groups; on Teams, gate it through team membership and the IdP's Cursor app assignment, and re-run with HTH_PLAN=teams (TRAP 3)."
    return 0
  fi

  # A limited policy is judged only against the approved list (TRAP 5).
  if [ -z "${HTH_APPROVED_GROUP_IDS:-}" ]; then
    echo "PRECONDITION: mode is limited; set HTH_APPROVED_GROUP_IDS to judge whether only approved billing groups hold access (billing groups partition every member, so a list naming every billing group reaches everyone outside Unassigned)" >&2
    exit 2
  fi
  local extra
  extra=$(jq -r --argjson ok "$(approved_ids_json)" '[.groups[].id] - $ok | .[]' "${GB_BODY_FILE}")
  if [ -n "${extra}" ]; then
    gb_finding "groups outside HTH_APPROVED_GROUP_IDS have Grok Bot access: $(echo "${extra}" | tr '\n' ' ')"
  fi
}
# HTH Guide Excerpt: end verify-grok-bot-access

# HTH Guide Excerpt: begin enforce-grok-bot-access
enforce() {
  local ids n body unknown
  ids=$(approved_ids_json)
  n=$(jq 'length' <<<"${ids}")
  if [ "${n}" -lt 1 ] || [ "${n}" -gt 100 ]; then
    echo "PRECONDITION: HTH_APPROVED_GROUP_IDS must hold 1-100 group ids (it holds ${n}); an empty limited list returns 400" >&2
    exit 2
  fi

  # Every id must be a billing group from List Groups (TRAP 1, TRAP 4).
  gb_get team /teams/groups
  gb_require "GET /teams/groups" 200
  gb_shape '(.groups | type == "array") and all(.groups[]; (.id | type == "string"))' "GET /teams/groups"
  unknown=$(jq -r --argjson want "${ids}" '$want - [.groups[].id] | .[]' "${GB_BODY_FILE}")
  if [ -n "${unknown}" ]; then
    echo "PRECONDITION: not billing-group ids from GET /teams/groups: $(echo "${unknown}" | tr '\n' ' ')(team_group_… directory-group ids are rejected; this pack does not send the reserved unassignedGroup id, which List Groups returns separately)" >&2
    exit 2
  fi
  echo "  approved billing groups:"
  jq -r --argjson want "${ids}" '.groups[] | select(.id as $i | $want | index($i)) | "    - \(.id)  \(.name)  members=\(.memberCount)"' "${GB_BODY_FILE}"

  body=$(jq -nc --argjson g "${ids}" '{mode: "limited", groupIds: $g}')
  if [ "${GB_APPLY}" -ne 1 ]; then
    gb_plan PUT /grok-bot/access "${body}"
    return 0
  fi
  gb_put team /grok-bot/access "${body}"
  gb_require_2xx "PUT /grok-bot/access"
  echo "  PUT /grok-bot/access -> mode=$(jq -r '.mode // "?"' "${GB_BODY_FILE}") groups=$(jq -c '[.groups[]?.id]' "${GB_BODY_FILE}")"
}
# HTH Guide Excerpt: end enforce-grok-bot-access

gb_parse_mode "$@"
case "${HTH_PLAN:-}" in
  ''|teams|enterprise) ;;
  *) echo "PRECONDITION: HTH_PLAN must be teams or enterprise (or unset)" >&2; exit 2 ;;
esac
gb_main verify enforce
