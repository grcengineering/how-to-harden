#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: asana-2.7
#   guide:   https://howtoharden.com/guides/asana/#27-govern-service-accounts-as-non-human-identities
#   profile: L2
#   mode:    read-only
#   requires: ASANA_SERVICE_ACCOUNT_PAT(service account with Scoped permissions > Audit logs; Enterprise+ or Legacy Enterprise), ASANA_WORKSPACE_GID, ASANA_SERVICE_ACCOUNT_INVENTORY(comma-separated actor gids), ASANA_LOOKBACK_DAYS(optional, default 7, max 90)
# =============================================================================
# HTH Asana Control 2.7: Govern Service Accounts as Non-Human Identities
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 5.4, 6.2 | NIST 800-53 AC-2, IA-5, AC-6
# Source: https://howtoharden.com/guides/asana/#27-govern-service-accounts-as-non-human-identities
# Dependencies: bash, curl (7.55+ for -H @file), jq, date
# API (verified against Asana's OpenAPI spec asana_oas.yaml and
#      https://developers.asana.com/docs/audit-log-events, 2026-09-24):
#   GET /workspaces/{workspace_gid}/audit_log_events   getAuditLogEvents
#   query: start_at, end_at, event_type, actor_type, actor_gid, resource_gid, limit (1-100), offset
#   AuditLogEventContext.api_authentication_method: cookie | oauth | personal_access_token | service_account
#   Event types used: service_account_created, service_account_deleted,
#   service_account_name_changed, workspace_service_account_token_expiry_changed
#
# ── TRAP 1: there is no "service_account" actor type ────────────────────────
# The actor_type filter accepts user, asana, asana_support, anonymous and
# external_administrator only. A call made with a service account's token is
# identified by context.api_authentication_method == "service_account", so the
# activity half of this pack pages the window and filters on that field.
#
# ── TRAP 2: the audit stream never ends on its own ──────────────────────────
# Asana keeps returning next_page for a filter that has matched events, "even
# when there are no more events", so a stream can be polled forever. A page with
# an empty data array is the end of the current events; the loop stops there.
#
# ── TRAP 3: 90 days, then gone ──────────────────────────────────────────────
# Audit events are "permanently deleted from our systems after 90 days". A
# lookback longer than 90 days would silently report less than it claims, so the
# pack refuses one.
#
# ── TRAP 4: nothing to reconcile against, no verdict ────────────────────────
# ASANA_SERVICE_ACCOUNT_INVENTORY is required. An unexplained caller is a
# finding only relative to an inventory; without one this pack would pass every
# tenant. Seed it from the resource gid of each service_account_created event.
#
# ── TRAP 5: an empty window reconciles nothing ──────────────────────────────
# If the unfiltered window returns no events at all, there are no callers to
# check against the inventory, and "every caller is on the inventory" would be
# true of nothing. The pack exits 2 instead of reporting compliant.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition (auth, tier, network, bad input, empty window, unexpected error)
# =============================================================================

set -eEuo pipefail
trap 'echo "PRECONDITION: unexpected failure at line ${LINENO}" >&2; exit 2' ERR

# A missing input is a precondition (exit 2), never a finding (exit 1).
need() { if [ -z "${!1:-}" ]; then echo "PRECONDITION: set $1 — $2" >&2; exit 2; fi; }
need ASANA_SERVICE_ACCOUNT_PAT "service account token scoped to Audit logs"
need ASANA_WORKSPACE_GID "the workspace gid of the organization"
need ASANA_SERVICE_ACCOUNT_INVENTORY "comma-separated actor gids of inventoried service accounts"
ASANA_API_BASE="${ASANA_API_BASE:-https://app.asana.com/api/1.0}"
LOOKBACK_DAYS="${ASANA_LOOKBACK_DAYS:-7}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }
case "${LOOKBACK_DAYS}" in ''|*[!0-9]*) echo "PRECONDITION: ASANA_LOOKBACK_DAYS must be a whole number" >&2; exit 2 ;; esac
if [ "${LOOKBACK_DAYS}" -lt 1 ] || [ "${LOOKBACK_DAYS}" -gt 90 ]; then
  echo "PRECONDITION: ASANA_LOOKBACK_DAYS must be 1-90; events older than 90 days no longer exist (TRAP 3)" >&2; exit 2
fi
# BSD date (macOS) first, GNU date second.
START_AT=$(date -u -v-"${LOOKBACK_DAYS}"d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "${LOOKBACK_DAYS} days ago" +%Y-%m-%dT%H:%M:%SZ)

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-asana-207.XXXXXX")"
ITEMS_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-asana-207i.XXXXXX")"
trap 'rm -f "${BODY_FILE}" "${ITEMS_FILE}"' EXIT
FINDINGS=0

# One GET. Fails closed: anything but HTTP 200 with a JSON object body exits 2.
# The token reaches curl through a process-substitution header file, never argv.
asana_get() {
  local code rc=0
  code=$(curl -sS --max-time 120 -o "${BODY_FILE}" -w '%{http_code}' \
    -H @<(printf 'Authorization: Bearer %s\n' "${ASANA_SERVICE_ACCOUNT_PAT}") \
    -H 'Accept: application/json' "${ASANA_API_BASE}$1" 2>/dev/null) || rc=$?
  if [ "${rc}" -ne 0 ]; then
    echo "PRECONDITION: GET ${1%%\?*} got no HTTP response (curl exit ${rc})" >&2; exit 2
  fi
  if [ "${code}" != "200" ]; then
    echo "PRECONDITION: GET ${1%%\?*} returned HTTP ${code}: $(jq -r '[.errors[]?.message] | join("; ")' "${BODY_FILE}" 2>/dev/null || true)" >&2
    echo "  The Audit Log API needs a service account token with the Audit logs scope (Enterprise+ or Legacy Enterprise)." >&2
    exit 2
  fi
  if ! jq -e 'type == "object" and (.data | type == "array")' "${BODY_FILE}" >/dev/null 2>&1; then
    echo "PRECONDITION: GET ${1%%\?*} returned no data array" >&2; exit 2
  fi
}

# Pages audit_log_events for one filter into ITEMS_FILE. Stops at an empty page
# or a null next_page (TRAP 2). Echoes the number of pages read.
audit_events() {  # audit_events <extra-query>
  local query="start_at=${START_AT}&limit=100$1" offset="" pages=0
  : > "${ITEMS_FILE}"
  while :; do
    if [ -n "${offset}" ]; then
      asana_get "/workspaces/${ASANA_WORKSPACE_GID}/audit_log_events?${query}&offset=${offset}"
    else
      asana_get "/workspaces/${ASANA_WORKSPACE_GID}/audit_log_events?${query}"
    fi
    pages=$((pages + 1))
    [ "$(jq '.data | length' "${BODY_FILE}")" -gt 0 ] || break
    jq -c '.data[]' "${BODY_FILE}" >> "${ITEMS_FILE}"
    offset=$(jq -r '.next_page.offset // "" | @uri' "${BODY_FILE}")
    [ -n "${offset}" ] || break
    if [ "${pages}" -ge 5000 ]; then echo "PRECONDITION: audit log paging exceeded 5000 pages" >&2; exit 2; fi
  done
  PAGES="${pages}"
}

echo "Asana 2.7 — service accounts as non-human identities (window: ${LOOKBACK_DAYS} days from ${START_AT})"

# HTH Guide Excerpt: begin service-account-lifecycle
for event_type in service_account_created service_account_deleted \
                  service_account_name_changed workspace_service_account_token_expiry_changed; do
  audit_events "&event_type=${event_type}"
  echo "  ${event_type}: $(jq -s 'length' "${ITEMS_FILE}")"
  jq -r '"    \(.created_at) actor=\(.actor.name // .actor.actor_type // "unknown") resource=\(.resource.name // "") …\((.resource.gid // "") | .[-6:])"
         + (if .details.new_value then " \(.details.old_value // "(unset)") -> \(.details.new_value)" else "" end)' "${ITEMS_FILE}"
done
# HTH Guide Excerpt: end service-account-lifecycle

# HTH Guide Excerpt: begin service-account-caller-reconciliation
audit_events ""
scanned=$(jq -s 'length' "${ITEMS_FILE}")
echo "  events scanned for API callers: ${scanned} across ${PAGES} page(s)"
# TRAP 5. A window with no events has no callers to reconcile, so it proves nothing.
if [ "${scanned}" -eq 0 ]; then
  echo "PRECONDITION: the audit feed returned 0 events for the window; no caller was reconciled (TRAP 5)." >&2
  echo "  Widen ASANA_LOOKBACK_DAYS, or check that the token belongs to this organization." >&2
  exit 2
fi
inventory=$(jq -nc --arg i "${ASANA_SERVICE_ACCOUNT_INVENTORY}" \
  '[$i | split(",")[] | gsub("^\\s+|\\s+$"; "") | select(length > 0)] | unique')
# TRAP 1. Callers authenticated with a service account token, grouped by actor gid.
jq -s -c '[.[] | select(.context.api_authentication_method == "service_account")]
          | group_by(.actor.gid // "unknown")
          | map({gid: (.[0].actor.gid // "unknown"), name: (.[0].actor.name // ""), events: length})' \
  "${ITEMS_FILE}" > "${BODY_FILE}"
echo "  service-account callers: $(jq 'length' "${BODY_FILE}")"
jq -r '.[] | "    - …\(.gid | .[-6:]) \(.name) events=\(.events)"' "${BODY_FILE}"
unknown=$(jq -c --argjson inv "${inventory}" '[.[] | select(.gid as $g | ($inv | index($g)) == null)]' "${BODY_FILE}")
if [ "$(jq -n --argjson u "${unknown}" '$u | length')" -gt 0 ]; then
  echo "FINDING: service-account callers missing from ASANA_SERVICE_ACCOUNT_INVENTORY (unmanaged credentials):"
  jq -nr --argjson u "${unknown}" '$u[] | "    - …\(.gid | .[-6:]) \(.name) events=\(.events)"'
  FINDINGS=$((FINDINGS + 1))
fi
# HTH Guide Excerpt: end service-account-caller-reconciliation

if [ "${FINDINGS}" -gt 0 ]; then
  exit 1
fi
echo "COMPLIANT: every service-account caller in the window is on the inventory."
exit 0
