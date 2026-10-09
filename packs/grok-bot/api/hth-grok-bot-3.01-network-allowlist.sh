#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-bot-3.1
#   guide:   https://howtoharden.com/guides/grok-bot/#31-enforce-a-destination-allowlist-with-network-controls
#   profile: L2
#   mode:    mutating
#   requires: CURSOR_ADMIN_API_KEY(Team API key; read:* to verify, admin:* to enforce; the PUT is Enterprise only), HTH_ALLOWLIST_FILE(optional for verify, required for enforce), HTH_EGRESS_MODE(optional: default_with_network_settings = L2 | network_settings_only = L3; when unset, enforce keeps the live restrictive mode, else sends L2), curl, jq
# =============================================================================
# HTH Grok Bot Control 3.1: Enforce a Destination Allowlist with Network Controls
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls v8 9.3, 13.4; NIST 800-53 SC-7, SC-7(5), AC-4; SOC 2 CC6.6;
#             ISO 27001:2022 A.8.20, A.8.22; OWASP Agentic 2026 ASI01
# Sources (transcribed from, fetched 2026-10-08):
#   https://cursor.com/docs/account/teams/admin-api#get-grok-bot-network-policy
#   https://cursor.com/docs/account/teams/admin-api#replace-grok-bot-network-policy
#   https://docs.x.ai/grok-bot/security (Network Controls)
# Dependencies: curl, jq, ./common.sh
#
# Usage: bash hth-grok-bot-3.01-network-allowlist.sh [verify | enforce [--apply]]
#   HTH_ALLOWLIST_FILE is a reviewed, version-controlled file with one
#   destination per line (domains, wildcard domains, IP addresses, CIDR ranges,
#   or host-or-CIDR:port such as 54.85.223.0/24:3306); `#` starts a comment.
#   enforce --apply sends PUT /grok-bot/network with that list, "locked": true
#   and an egressMode chosen in this order: the explicit HTH_EGRESS_MODE, else
#   the live restrictive mode, else default_with_network_settings (L2,
#   "Cursor defaults plus the allowlist"). Set
#   HTH_EGRESS_MODE=network_settings_only for L3 ("The allowlist and
#   destinations required to run Grok Bot"); the pack never picks L3 on its own.
#
# ── TRAP 1: the PUT is a FULL REPLACE ───────────────────────────────────────
# "Replace the team's Grok Bot network policy." egressMode, allowlist and
# locked are all Required; "Partial bodies, unknown modes, and invalid allowlist
# entries return 400". Every enforce run therefore sends the WHOLE reviewed
# file — an entry missing from the file is removed from the live policy.
#
# ── TRAP 2: the entry cap is documented two ways ────────────────────────────
# The Admin API says "Up to 500 destinations, 1 to 253 characters each"; the
# security page says destinations come "with no cap on the number of entries".
# This pack enforces the API's documented limit and refuses a larger file.
#
# ── TRAP 3: unset is allow-all; locked decides whether groups can widen it ──
# egressMode `unset` is "Apply no policy" (the docs' "No Policy (Allow All)",
# the default for teams without a policy) and `allow_all` allows every
# destination. Only default_with_network_settings and network_settings_only
# restrict anything. "When locked is true, group policies cannot override the
# team policy" — without it a group's own network policy "replaces the team's
# for their members".
#
# ── TRAP 4: readable everywhere, writable on Enterprise only ────────────────
# GET /grok-bot/network returns "the effective policy on every plan", so a Teams
# admin can prove the policy is unset. The PUT "Returns 403 on Teams plans".
#
# ── TRAP 5: a restrictive mode can still allow everything ───────────────────
# The allowlist accepts "IP addresses, CIDR ranges, or host-or-CIDR:port". A
# catch-all entry (0.0.0.0/0, ::/0 or a bare *, with or without a port) makes a
# restrictive mode allow-all for those destinations in practice, so verify
# flags it whether or not HTH_ALLOWLIST_FILE is set.
#
# ── TRAP 6: every PUT replaces the mode too ─────────────────────────────────
# Because egressMode is Required on every PUT, a run triggered only by
# allowlist drift would otherwise switch the mode as a side effect. Enforce
# therefore never defaults to the L3 mode, and never loosens a live L3 policy.
#
# Exit codes: 0 compliant | 1 finding, dry run with changes, or a write refused
# after a finding | 2 precondition
# =============================================================================

set -euo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Reviewed file -> JSON array of destinations (comments and blanks dropped, de-duplicated).
reviewed_allowlist() {
  if [ ! -r "${HTH_ALLOWLIST_FILE:-}" ]; then
    echo "PRECONDITION: HTH_ALLOWLIST_FILE is not a readable file" >&2
    exit 2
  fi
  sed -e 's/#.*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "${HTH_ALLOWLIST_FILE}" \
    | jq -R -s -c 'split("\n") | map(select(length > 0)) | unique'
}

# HTH Guide Excerpt: begin verify-network-policy
verify() {
  gb_get team /grok-bot/network
  gb_require "GET /grok-bot/network" 200
  gb_shape '(.egressMode | IN("unset","allow_all","default_with_network_settings","network_settings_only"))
            and (.allowlist | type == "array") and (.locked | type == "boolean")' "GET /grok-bot/network"
  local live mode locked want drift catchall
  live="${GB_TMP_DIR}/network.json"
  cp "${GB_BODY_FILE}" "${live}"
  mode=$(jq -r '.egressMode' "${live}")
  locked=$(jq -r '.locked' "${live}")
  echo "Grok Bot 3.1 — egressMode=${mode} locked=${locked} allowlist=$(jq '.allowlist | length' "${live}") entr(ies)"
  jq -r '.allowlist[] | "    - \(.)"' "${live}"

  case "${mode}" in
    default_with_network_settings|network_settings_only) ;;
    *) gb_finding "egressMode=${mode}: Bots can reach any destination (TRAP 3)" ;;
  esac
  if [ "${locked}" != "true" ]; then
    gb_finding "locked=false: a group's own network policy replaces the team policy for its members"
  fi
  if [ -n "${HTH_EGRESS_MODE:-}" ] && [ "${mode}" != "${HTH_EGRESS_MODE}" ]; then
    gb_finding "egressMode=${mode}, expected ${HTH_EGRESS_MODE}"
  fi
  # Catch-all entries defeat a restrictive mode (TRAP 5).
  catchall=$(jq -r '.allowlist[] | select(test("^(0\\.0\\.0\\.0/0|::/0|\\*)(:[0-9]+)?$")) | "    catch-all: \(.)"' "${live}")
  if [ -n "${catchall}" ]; then
    echo "${catchall}"
    gb_finding "the allowlist holds catch-all entries, which allow every destination they match (TRAP 5)"
  fi

  # Drift against the reviewed file, when one is supplied.
  if [ -n "${HTH_ALLOWLIST_FILE:-}" ]; then
    want=$(reviewed_allowlist)
    drift=$(jq -r --argjson want "${want}" '
      ((.allowlist - $want) | map("    + live, not reviewed: \(.)")) +
      (($want - .allowlist) | map("    - reviewed, not live: \(.)")) | .[]' "${live}")
    if [ -n "${drift}" ]; then
      echo "${drift}"
      gb_finding "the live allowlist differs from ${HTH_ALLOWLIST_FILE}"
    fi
  fi
}
# HTH Guide Excerpt: end verify-network-policy

# HTH Guide Excerpt: begin enforce-network-policy
enforce() {
  local want mode live_mode body n bad
  want=$(reviewed_allowlist)
  # TRAP 6: explicit choice, else keep the live restrictive mode, else L2.
  live_mode=$(jq -r '.egressMode' "${GB_TMP_DIR}/network.json")
  if [ -n "${HTH_EGRESS_MODE:-}" ]; then
    mode="${HTH_EGRESS_MODE}"
  else
    case "${live_mode}" in
      default_with_network_settings|network_settings_only) mode="${live_mode}" ;;
      *) mode="default_with_network_settings" ;;
    esac
    echo "  egressMode: ${mode} (HTH_EGRESS_MODE unset; live mode is ${live_mode}$(if [ "${mode}" != "network_settings_only" ]; then echo "; set HTH_EGRESS_MODE=network_settings_only for L3"; fi))"
  fi
  n=$(jq 'length' <<<"${want}")
  if [ "${n}" -gt 500 ]; then
    echo "PRECONDITION: ${n} destinations exceed the Admin API's documented 500 (TRAP 2)" >&2
    exit 2
  fi
  bad=$(jq -r '.[] | select(length > 253 or test("\\s") or test("^(0\\.0\\.0\\.0/0|::/0|\\*)(:[0-9]+)?$")) | "    \(.)"' <<<"${want}")
  if [ -n "${bad}" ]; then
    echo "PRECONDITION: entries longer than 253 characters, containing whitespace, or catch-all (TRAP 5):" >&2
    echo "${bad}" >&2
    exit 2
  fi
  if [ "${n}" -eq 0 ]; then
    echo "  WARNING: the reviewed file holds zero destinations"
  fi

  # TRAP 1: always the whole policy, always locked.
  body=$(jq -nc --arg m "${mode}" --argjson a "${want}" '{egressMode: $m, allowlist: $a, locked: true}')
  if [ "${GB_APPLY}" -ne 1 ]; then
    gb_plan PUT /grok-bot/network "${body}"
    return 0
  fi
  gb_put team /grok-bot/network "${body}"
  gb_require_2xx "PUT /grok-bot/network"
  echo "  PUT /grok-bot/network -> egressMode=$(jq -r '.egressMode' "${GB_BODY_FILE}") locked=$(jq -r '.locked' "${GB_BODY_FILE}") allowlist=$(jq '.allowlist | length' "${GB_BODY_FILE}")"
}
# HTH Guide Excerpt: end enforce-network-policy

gb_parse_mode "$@"
case "${HTH_EGRESS_MODE:-}" in
  ''|default_with_network_settings|network_settings_only) ;;
  *) echo "PRECONDITION: HTH_EGRESS_MODE must be default_with_network_settings (L2) or network_settings_only (L3), or unset" >&2; exit 2 ;;
esac
gb_main verify enforce
