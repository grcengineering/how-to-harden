#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: asana-3.4
#   guide:   https://howtoharden.com/guides/asana/#34-govern-ai-studio-and-ai-features
#   profile: L2
#   mode:    read-only
#   requires: ASANA_SERVICE_ACCOUNT_PAT(service account with Scoped permissions > AI Studio Usage API; org licensed for AI Studio), ASANA_WORKSPACE_GID, ASANA_AI_STUDIO_APPROVED_USERS(comma-separated user gids; empty = no paid seats approved), ASANA_DIVISION_GID(optional)
# =============================================================================
# HTH Asana Control 3.4: Govern AI Studio and AI Features
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 3.3, 14.1 | NIST 800-53 AC-3, SA-9, SC-7
# Source: https://howtoharden.com/guides/asana/#34-govern-ai-studio-and-ai-features
# Dependencies: bash, curl (7.55+ for -H @file), jq
# API (verified against Asana's OpenAPI spec asana_oas.yaml, 2026-09-24):
#   GET /workspaces/{workspace_gid}/ai_studio/seats   getAiStudioSeats
#   query: state (active | revoked), division_gid, limit (1-100), offset
#   "This endpoint is restricted to service accounts in organizations licensed for AI Studio."
#   AiStudioSeat: user{gid,name,email}, license (ai_studio_plus | ai_studio_pro | ai_studio_max),
#   state (active | revoked | expired), assigned_at, assigned_by
#
# ── TRAP 1: paid seats only ─────────────────────────────────────────────────
# "/seats returns only paid seats, so the free tier is not included." A clean
# result proves no UNAPPROVED PAID seat exists; it says nothing about the free
# tier or about the org-wide "Enable Asana AI" setting, which has no API and is
# verified in the console (Admin Console > Settings > Asana AI).
#
# ── TRAP 2: an empty approved list is a decision ────────────────────────────
# ASANA_AI_STUDIO_APPROVED_USERS must be SET. Set to an empty string it means
# "no paid seats are approved", and every active seat becomes a finding. Unset,
# the pack refuses to run rather than approving whatever it finds.
#
# ── TRAP 3: default division ────────────────────────────────────────────────
# Without division_gid the endpoint answers for "the org's first licensed
# division". Organizations with divisions run the pack once per division.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition (auth, licensing, network, bad input, unexpected error)
# =============================================================================

set -eEuo pipefail
trap 'echo "PRECONDITION: unexpected failure at line ${LINENO}" >&2; exit 2' ERR

# A missing input is a precondition (exit 2), never a finding (exit 1).
need() { if [ -z "${!1:-}" ]; then echo "PRECONDITION: set $1 — $2" >&2; exit 2; fi; }
need_set() { if [ -z "${!1+x}" ]; then echo "PRECONDITION: set $1 — $2" >&2; exit 2; fi; }
need ASANA_SERVICE_ACCOUNT_PAT "service account token scoped to the AI Studio Usage API"
need ASANA_WORKSPACE_GID "the workspace gid of the organization"
need_set ASANA_AI_STUDIO_APPROVED_USERS "comma-separated approved user gids, or empty for none"
ASANA_API_BASE="${ASANA_API_BASE:-https://app.asana.com/api/1.0}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-asana-304.XXXXXX")"
ITEMS_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-asana-304i.XXXXXX")"
trap 'rm -f "${BODY_FILE}" "${ITEMS_FILE}"' EXIT

# One GET. Fails closed: anything but HTTP 200 with a JSON object body exits 2.
# The token reaches curl through a process-substitution header file, never argv.
asana_get() {
  local code rc=0
  code=$(curl -sS --max-time 60 -o "${BODY_FILE}" -w '%{http_code}' \
    -H @<(printf 'Authorization: Bearer %s\n' "${ASANA_SERVICE_ACCOUNT_PAT}") \
    -H 'Accept: application/json' "${ASANA_API_BASE}$1" 2>/dev/null) || rc=$?
  if [ "${rc}" -ne 0 ]; then
    echo "PRECONDITION: GET ${1%%\?*} got no HTTP response (curl exit ${rc})" >&2; exit 2
  fi
  if [ "${code}" != "200" ]; then
    echo "PRECONDITION: GET ${1%%\?*} returned HTTP ${code}: $(jq -r '[.errors[]?.message] | join("; ")' "${BODY_FILE}" 2>/dev/null || true)" >&2
    echo "  The seats endpoint needs a service account (AI Studio Usage API scope) in an org licensed for AI Studio." >&2
    exit 2
  fi
  if ! jq -e 'type == "object" and (.data | type == "array")' "${BODY_FILE}" >/dev/null 2>&1; then
    echo "PRECONDITION: GET ${1%%\?*} returned no data array" >&2; exit 2
  fi
}

# HTH Guide Excerpt: begin ai-studio-seat-audit
query="state=active&limit=100"
[ -z "${ASANA_DIVISION_GID:-}" ] || query="${query}&division_gid=${ASANA_DIVISION_GID}"
offset=""; pages=0
: > "${ITEMS_FILE}"
while :; do
  if [ -n "${offset}" ]; then
    asana_get "/workspaces/${ASANA_WORKSPACE_GID}/ai_studio/seats?${query}&offset=${offset}"
  else
    asana_get "/workspaces/${ASANA_WORKSPACE_GID}/ai_studio/seats?${query}"
  fi
  jq -c '.data[]' "${BODY_FILE}" >> "${ITEMS_FILE}"
  offset=$(jq -r '.next_page.offset // "" | @uri' "${BODY_FILE}")
  pages=$((pages + 1))
  [ -n "${offset}" ] || break
  if [ "${pages}" -ge 1000 ]; then echo "PRECONDITION: seat paging exceeded 1000 pages" >&2; exit 2; fi
done

approved=$(jq -nc --arg a "${ASANA_AI_STUDIO_APPROVED_USERS}" \
  '[$a | split(",")[] | gsub("^\\s+|\\s+$"; "") | select(length > 0)] | unique')
echo "Asana 3.4 — AI Studio paid seats (active; free tier not reported, TRAP 1)"
echo "  division: ${ASANA_DIVISION_GID:-first licensed division (TRAP 3)}"
echo "  active paid seats: $(jq -s 'length' "${ITEMS_FILE}") across ${pages} page(s); approved holders: $(jq -n --argjson a "${approved}" '$a | length')"
jq -s -c --argjson a "${approved}" '[.[] | select((.user.gid // "") as $g | ($a | index($g)) == null)]' "${ITEMS_FILE}" > "${BODY_FILE}"
unapproved=$(jq 'length' "${BODY_FILE}")
jq -r '.[] | "FINDING: unapproved AI Studio seat \(.license // "unknown") held by \(.user.name // "(no name)") …\((.user.gid // "") | .[-6:]) since \(.assigned_at // "unknown")"' "${BODY_FILE}"
# HTH Guide Excerpt: end ai-studio-seat-audit

if [ "${unapproved}" -gt 0 ]; then
  exit 1
fi
echo "COMPLIANT: every active paid AI Studio seat is held by an approved user."
exit 0
