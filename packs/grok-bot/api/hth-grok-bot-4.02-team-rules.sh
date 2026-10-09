#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-bot-4.2
#   guide:   https://howtoharden.com/guides/grok-bot/#42-set-required-team-rules-for-grok-bot
#   profile: L1
#   mode:    mutating
#   requires: CURSOR_ADMIN_API_KEY(Team API key; read:* to verify, admin:* to enforce), HTH_RULES_FILE(optional for verify, required for enforce), curl, jq
# =============================================================================
# HTH Grok Bot Control 4.2: Set Required Team Rules for Grok Bot
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls v8 4.1; NIST 800-53 PL-4, AC-6; SOC 2 CC2.2, CC6.1;
#             ISO 27001:2022 A.5.10
# Sources (transcribed from, fetched 2026-10-08):
#   https://cursor.com/docs/account/teams/admin-api#list-grok-bot-team-rules
#   https://cursor.com/docs/account/teams/admin-api#create-grok-bot-team-rule
#   https://cursor.com/docs/account/teams/admin-api#update-grok-bot-team-rule
# Dependencies: curl, jq, ./common.sh
#
# Usage: bash hth-grok-bot-4.02-team-rules.sh [verify | enforce [--apply]]
#   HTH_RULES_FILE is a reviewed JSON array: [{"name": "...", "content": "..."}]
#   verify            list every rule; flag disabled rules, reviewed rules that
#                     are missing or whose content drifted, and live rules the
#                     file does not name
#   enforce --apply   POST each missing reviewed rule (enabled=true) and PATCH
#                     {"enabled": true} only onto disabled rules whose content
#                     matches the reviewed file. A disabled rule whose content
#                     drifted stays disabled and is reported: "Rules applied to
#                     Grok Bot are always required, so members can't turn them
#                     off" (cursor.com/docs/grok-bot/teams), so switching it on
#                     would make unreviewed text binding on every member.
#                     Content drift and unexpected rules are reported, never
#                     overwritten or deleted — those are review decisions.
#
# ── TRAP 1: API-created rules are Grok-Bot-only ─────────────────────────────
# POST takes name, content and enabled and has no scope parameter; API-created
# rules come back with scope `grokBot`, so the API cannot create a rule scoped to
# both Cursor and Grok Bot. How a rule with both scopes appears in the list is
# not documented, so this pack keeps every rule it is given and never filters on
# scope.
#
# ── TRAP 2: limits the API enforces ─────────────────────────────────────────
# "A team can store up to 50 Grok Bot rules"; name 1-255 characters; content
# 1-30,000 characters; PATCH needs at least one field and returns 404 for a
# missing rule. The pack validates the file against these before writing.
#
# ── TRAP 3: Teams-plan reach is unconfirmed ─────────────────────────────────
# Enterprise is confirmed; the API overview lists the Admin API as "Enterprise
# teams" (common.sh TRAP D). A 401/403 is a precondition.
#
# ── TRAP 4: the audit trail is inferred ─────────────────────────────────────
# Changes land in the generic `team_rule` audit event (create/update/delete,
# is_active), which the docs list under team settings, not in the Grok Bot
# table; its payload has no scope field. Group Rules log separately as
# grok_bot_group_resource with resource=rule (see the 4.3 pack).
#
# Exit codes: 0 compliant | 1 finding, dry run with changes, or a write refused
# after a finding | 2 precondition
# =============================================================================

set -euo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

LIVE_RULES=""   # JSON array, filled by verify

list_rules() { # all pages of GET /grok-bot/team-rules -> JSON array
  local out cursor="" next q pages=0
  out="$(gb_tmp rules)"
  while :; do
    # A team stores at most 50 Grok Bot rules, so a few pages at limit=100 (TRAP G).
    pages=$((pages + 1))
    if [ "${pages}" -gt 10 ]; then
      echo "PRECONDITION: more than 10 pages of team rules (a team stores at most 50)" >&2
      exit 2
    fi
    q="limit=100"
    if [ -n "${cursor}" ]; then q="${q}&cursor=$(jq -rn --arg c "${cursor}" '$c|@uri')"; fi
    gb_get team "/grok-bot/team-rules?${q}"
    gb_require "GET /grok-bot/team-rules" 200
    gb_shape '(.teamRules | type == "array")
              and all(.teamRules[]; (.id | type == "string") and (.name | type == "string")
                                    and (.content | type == "string") and (.enabled | type == "boolean"))' "GET /grok-bot/team-rules"
    jq -c '.teamRules[]' "${GB_BODY_FILE}" >> "${out}"
    next=$(jq -r '.nextCursor // ""' "${GB_BODY_FILE}")
    if [ -z "${next}" ]; then break; fi
    if [ "${next}" = "${cursor}" ]; then
      echo "PRECONDITION: GET /grok-bot/team-rules returned the same nextCursor twice" >&2
      exit 2
    fi
    cursor="${next}"
  done
  jq -s -c '.' "${out}"
}

reviewed_rules() { # HTH_RULES_FILE, validated against TRAP 2
  local f="${HTH_RULES_FILE:-}"
  if [ ! -r "${f}" ]; then echo "PRECONDITION: HTH_RULES_FILE is not a readable file" >&2; exit 2; fi
  if ! jq -e 'type == "array" and length <= 50
      and all(.[]; (.name | type == "string" and length >= 1 and length <= 255)
                   and (.content | type == "string" and length >= 1 and length <= 30000))
      and (map(.name) | length == (unique | length))' "${f}" >/dev/null 2>&1; then
    echo "PRECONDITION: ${f} must be a JSON array of at most 50 {\"name\" (1-255 chars, unique), \"content\" (1-30,000 chars)}" >&2
    exit 2
  fi
  jq -c 'map({name, content})' "${f}"
}

# HTH Guide Excerpt: begin verify-team-rules
verify() {
  local want report
  LIVE_RULES=$(list_rules)
  echo "Grok Bot 4.2 — team rules: $(jq 'length' <<<"${LIVE_RULES}")"
  jq -r '.[] | "    - [\(if .enabled then "on " else "OFF" end)] \(.name)  (scope=\(.scope // "?"))"' <<<"${LIVE_RULES}"

  if [ "$(jq 'length' <<<"${LIVE_RULES}")" -eq 0 ]; then
    gb_finding "no Grok Bot team rules exist"
  fi
  if [ "$(jq '[.[] | select(.enabled == false)] | length' <<<"${LIVE_RULES}")" -gt 0 ]; then
    gb_finding "disabled team rules: $(jq -r '[.[] | select(.enabled == false) | .name] | join("; ")' <<<"${LIVE_RULES}")"
  fi
  if [ "$(jq '[.[].name] | length != (unique | length)' <<<"${LIVE_RULES}")" = "true" ]; then
    gb_finding "two or more live rules share a name — the reviewed-file diff below is ambiguous"
  fi

  if [ -n "${HTH_RULES_FILE:-}" ]; then
    want=$(reviewed_rules)
    report=$(jq -r --argjson want "${want}" '
      . as $live
      | ($want[] | . as $w | ($live | map(select(.name == $w.name)) | first) as $l
         | if $l == null then "MISSING: \($w.name)"
           elif $l.content != $w.content then "DRIFT:   \($w.name) (content differs from the reviewed file)"
           else empty end),
        ($live[] | select(.name as $n | ($want | map(.name) | index($n)) == null) | "UNEXPECTED: \(.name)")' <<<"${LIVE_RULES}")
    if [ -n "${report}" ]; then
      sed 's/^/    /' <<<"${report}"
      gb_finding "team rules differ from ${HTH_RULES_FILE}"
    fi
  fi
}
# HTH Guide Excerpt: end verify-team-rules

# HTH Guide Excerpt: begin enforce-team-rules
enforce() {
  local want missing disabled held total body id name
  want=$(reviewed_rules)
  missing=$(jq -c --argjson live "${LIVE_RULES}" '[.[] | select(.name as $n | ($live | map(.name) | index($n)) == null)]' <<<"${want}")
  # Re-enable only a disabled rule whose name AND content match a reviewed rule.
  disabled=$(jq -c --argjson want "${want}" '[.[] | . as $l | select(.enabled == false and any($want[]; .name == $l.name and .content == $l.content))]' <<<"${LIVE_RULES}")
  held=$(jq -r --argjson want "${want}" '.[] | . as $l | select(.enabled == false and any($want[]; .name == $l.name and .content != $l.content)) | .name' <<<"${LIVE_RULES}")
  while IFS= read -r name; do
    [ -n "${name}" ] || continue
    echo "  not re-enabled (content differs from the reviewed file — review first): ${name}"
  done <<<"${held}"
  total=$(( $(jq 'length' <<<"${LIVE_RULES}") + $(jq 'length' <<<"${missing}") ))
  if [ "${total}" -gt 50 ]; then
    echo "PRECONDITION: creating $(jq 'length' <<<"${missing}") rule(s) would exceed the team's 50-rule limit" >&2
    exit 2
  fi

  while IFS= read -r body; do
    [ -n "${body}" ] || continue
    if [ "${GB_APPLY}" -ne 1 ]; then gb_plan POST /grok-bot/team-rules "${body}"; continue; fi
    gb_post team /grok-bot/team-rules "${body}"
    gb_require "POST /grok-bot/team-rules" 201
    echo "  created: $(jq -r '.teamRule.name' "${GB_BODY_FILE}") ($(jq -r '.teamRule.id' "${GB_BODY_FILE}"))"
  done < <(jq -c '.[] | {name, content, enabled: true}' <<<"${missing}")

  while IFS=$'\t' read -r id name; do
    [ -n "${id}" ] || continue
    if [ "${GB_APPLY}" -ne 1 ]; then gb_plan PATCH "/grok-bot/team-rules/${id}" '{"enabled": true}'; continue; fi
    gb_patch team "/grok-bot/team-rules/$(jq -rn --arg i "${id}" '$i|@uri')" '{"enabled": true}'
    gb_require_2xx "PATCH /grok-bot/team-rules/${id}"
    echo "  re-enabled: ${name}"
  done < <(jq -r '.[] | [.id, .name] | @tsv' <<<"${disabled}")
}
# HTH Guide Excerpt: end enforce-team-rules

gb_parse_mode "$@"
if [ "${GB_MODE}" = "enforce" ] && [ -z "${HTH_RULES_FILE:-}" ]; then
  echo "PRECONDITION: enforce needs HTH_RULES_FILE (the reviewed rule set)" >&2
  exit 2
fi
gb_main verify enforce
