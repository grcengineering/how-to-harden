#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-6.1
#   guide:   https://howtoharden.com/guides/ona/#61-enable-audit-logging-and-siem-streaming
#   profile: L1
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional)
# =============================================================================
# HTH Ona Control 6.1: Enable Audit Logging and SIEM Streaming
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 8.2, 8.9
# Source: https://howtoharden.com/guides/ona/#61-enable-audit-logging-and-siem-streaming
# Dependencies: curl, jq
#
# WHY THIS IS AN api/ PACK, AND WHY IT IS AN EXPORTER RATHER THAN A CHECK.
# There is NO method to enable audit logging, set a retention period, or
# configure a log-forwarding destination — verified across all four event/*
# pages, all 45 organization/* pages, and the notification/*, webhook/* and
# workflow/* families. Audit logging is always-on and PULL-ONLY, and the
# Terraform provider has no audit-log resource because there is nothing to
# declare. "SIEM streaming" on Ona therefore means one thing: something polls
# ListAuditLogs and forwards the entries. This pack IS that poller — the
# primitive a cron job, a Lambda or a log-shipper wraps.
#
# ── TRAP 1: WatchEvents IS NOT AN AUDIT FEED ───────────────────────────────
# `EventService/WatchEvents` is a server-streaming method that returns only
# `{operation, resourceType, resourceId}`. It carries NO ACTOR, no action string
# and no timestamp — it is a change-notification channel. Building a SIEM
# integration on it produces a feed that can never answer "who did this", which
# is the entire purpose of an audit log. Poll ListAuditLogs instead.
#
# ── TRAP 2: the time window is HALF-OPEN, [from, to) ───────────────────────
# Verbatim: `from` — "filters audit logs created at or AFTER this timestamp
# (INCLUSIVE)"; `to` — "filters audit logs created BEFORE this timestamp
# (EXCLUSIVE)". A rolling exporter must therefore use the previous run's `to` as
# the next run's `from` VERBATIM. Adding a second to avoid "duplicates" drops
# every entry inside that second; subtracting one re-emits them.
#
# ── TRAP 3: Enterprise gating is a PRECONDITION, never a finding ───────────
# On a non-Enterprise organization ListAuditLogs answers HTTP 400
# `failed_precondition` "feature is only available for enterprise customers".
# That is a plan boundary. Reporting it as a control failure would tell an
# operator to fix something they cannot fix, so this pack exits 2 with a message
# that names the cause.
#
# ── TRAP 4: every repeated filter field is capped at 25 items ──────────────
# actorIds, actorPrincipals, subjectIds and subjectTypes all carry
# `repeated.max_items=25`. `--veto-only` therefore filters CLIENT-SIDE on
# `kind == AUDIT_LOG_ENTRY_KIND_ENVIRONMENT_VETO`, because `kind` is not a filter
# field at all — only actor, subject and time are.
#
# OUTPUT CONTRACT: one JSON object per line (NDJSON) on stdout — that is the feed.
# Every diagnostic goes to stderr, so `… > audit.ndjson` is always a clean file.
#
# Tunables: ONA_AUDIT_FROM / ONA_AUDIT_TO (RFC 3339). Default window: last 24h.
# Exit codes: 0 exported | 2 precondition (Enterprise-only, auth, transport)
# =============================================================================

set -euo pipefail

: "${ONA_TOKEN:?set ONA_TOKEN — an Ona personal access token (Read-only is enough) or service account token}"

# TRAP (base URL). The documented base is https://app.ona.com/api. That host
# answers 308 to app.gitpod.io, and `curl -L` DROPS the Authorization header
# across the cross-host hop, so a valid token comes back 401. Default to the
# host that actually answers; override only for a custom management-plane
# domain (tokens must be minted on that same domain).
ONA_API_BASE="${ONA_API_BASE:-https://app.gitpod.io/api}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

RPC_BODY=""; RPC_CODE=""; ORG_ID=""; ORG_TIER=""; PAGE_ITEMS="[]"
BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-ona.XXXXXX")"
trap 'rm -f "${BODY_FILE}"' EXIT

# Connect-RPC unary call. Every Ona method is a POST, but no -X flag is written:
# curl already implies POST when a body is supplied, which keeps this pack
# honestly read-only under scripts/validate-packs.sh check 14.
api() {
  set +e
  RPC_CODE=$(curl -sS -o "${BODY_FILE}" -w '%{http_code}' \
    "${ONA_API_BASE}/gitpod.v1.$1" \
    -H "Authorization: Bearer ${ONA_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$2" 2>/dev/null)
  local rc=$?
  set -e
  [ "${rc}" -eq 0 ] || RPC_CODE="000"
  RPC_BODY=$(cat "${BODY_FILE}" 2>/dev/null || echo '{}')
}

rpc_err() { printf '%s' "${RPC_BODY}" | jq -r '.code // "unknown"' 2>/dev/null || echo unknown; }
rpc_msg() { printf '%s' "${RPC_BODY}" | jq -r '.message // "no message"' 2>/dev/null || echo "no message"; }

# Fatal classifier. Connect errors carry {"code": "...", "message": "..."}.
# Plan gating, auth failure and transport failure are all preconditions (exit 2),
# never findings — a control cannot be judged non-compliant on evidence that was
# never returned.
api_strict() {
  api "$1" "$2"
  if [ "${RPC_CODE}" = "200" ]; then return 0; fi
  case "${RPC_CODE}:$(rpc_err)" in
    400:failed_precondition)
      echo "PRECONDITION: $1 — $(rpc_msg)" >&2 ;;
    401:*|403:*)
      echo "PRECONDITION: $1 returned HTTP ${RPC_CODE} ($(rpc_err)) — $(rpc_msg)" >&2
      echo "  The token is invalid, expired, or lacks the permission this method requires." >&2 ;;
    000:*)
      echo "PRECONDITION: $1 — no HTTP response (network, DNS, or TLS failure)." >&2 ;;
    *)
      echo "PRECONDITION: $1 returned HTTP ${RPC_CODE} ($(rpc_err)) — $(rpc_msg)" >&2 ;;
  esac
  exit 2
}

# Follows pagination.nextToken to exhaustion. pageSize is capped at 100 by the
# API (int32.lte=100); the 200-page ceiling is a runaway guard, not a limit.
paginate() { # paginate <Service/Method> <base-json> <response-array-field>
  local method="$1" base="$2" field="$3" token="" req pages=0 tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/hth-ona-page.XXXXXX")"
  while :; do
    req=$(jq -nc --argjson base "${base}" --arg t "${token}" \
      '$base + {pagination: ({pageSize: 100} + (if $t == "" then {} else {token: $t} end))}')
    api_strict "${method}" "${req}"
    printf '%s' "${RPC_BODY}" | jq -c --arg f "${field}" '.[$f][]?' >> "${tmp}"
    token=$(printf '%s' "${RPC_BODY}" | jq -r '.pagination.nextToken // ""')
    pages=$((pages + 1))
    [ -n "${token}" ] && [ "${pages}" -lt 200 ] || break
  done
  PAGE_ITEMS=$(jq -s '.' "${tmp}")
  rm -f "${tmp}"
}

# Organization id: explicit override, else derived from the token's own identity.
resolve_org() {
  if [ -n "${ONA_ORGANIZATION_ID:-}" ]; then ORG_ID="${ONA_ORGANIZATION_ID}"; ORG_TIER="(not read)"; return 0; fi
  api_strict "IdentityService/GetAuthenticatedIdentity" '{}'
  ORG_ID=$(printf '%s' "${RPC_BODY}" | jq -r '.organizationId // ""')
  ORG_TIER=$(printf '%s' "${RPC_BODY}" | jq -r '.organizationTier // "(unset)"')
  [ -n "${ORG_ID}" ] || { echo "PRECONDITION: GetAuthenticatedIdentity returned no organizationId" >&2; exit 2; }
}

# GetOrganizationPolicies is the single read anchor for every org-wide control.
# Proto3 JSON omits defaults, so callers must read every field with a `// false`,
# `// 0`, `// []` or `// "*_UNSPECIFIED"` fallback — absence is the default
# value, not an error and not compliance.
get_policies() {
  resolve_org
  api_strict "OrganizationService/GetOrganizationPolicies" \
    "$(jq -nc --arg o "${ORG_ID}" '{organizationId: $o}')"
  POLICIES=$(printf '%s' "${RPC_BODY}" | jq -c '.policies // {}')
}
VETO_ONLY=0
case "${1:-}" in
  ""|export) ;;
  --veto-only) VETO_ONLY=1 ;;
  *) echo "usage: $(basename "$0") [--veto-only]   # NDJSON to stdout, diagnostics to stderr" >&2; exit 2 ;;
esac

# HTH Guide Excerpt: begin audit-log-ndjson-export
# Portable RFC 3339. GNU and BSD date disagree on relative arithmetic and this
# repo runs on both, so try each in turn.
iso_now()        { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
iso_hours_ago()  {
  date -u -d "$1 hours ago" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null \
    || date -u -v-"$1"H     '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null \
    || { echo "PRECONDITION: neither GNU nor BSD date syntax worked — set ONA_AUDIT_FROM explicitly" >&2; exit 2; }
}

export_logs() {
  resolve_org
  local from to token pages=0 emitted=0
  # TRAP 2: [from, to). Carry `to` forward verbatim as the next run's `from`.
  to="${ONA_AUDIT_TO:-$(iso_now)}"
  from="${ONA_AUDIT_FROM:-$(iso_hours_ago 24)}"
  echo "window [from,to) = [${from}, ${to})  (half-open: reuse 'to' verbatim as the next 'from')" >&2

  # TRAP 3: probe once so the plan boundary is named, not swallowed.
  api "EventService/ListAuditLogs" \
      "$(jq -nc --arg f "${from}" --arg t "${to}" '{filter: {from: $f, to: $t}, pagination: {pageSize: 1}}')"
  if [ "${RPC_CODE}" = "400" ] && [ "$(rpc_err)" = "failed_precondition" ]; then
    echo "PRECONDITION: audit logs are Enterprise-only on this organization — $(rpc_msg)" >&2
    echo "  Nothing to remediate at the configuration layer: there is no method to enable audit" >&2
    echo "  logging, and no retention or SIEM-destination field anywhere in the API. The gate is" >&2
    echo "  the plan tier." >&2
    exit 2
  fi
  if [ "${RPC_CODE}" != "200" ]; then
    api_strict "EventService/ListAuditLogs" \
      "$(jq -nc --arg f "${from}" --arg t "${to}" '{filter: {from: $f, to: $t}, pagination: {pageSize: 1}}')"
  fi

  token=""
  while :; do
    api_strict "EventService/ListAuditLogs" \
      "$(jq -nc --arg f "${from}" --arg t "${to}" --arg tok "${token}" \
         '{filter: {from: $f, to: $t},
           pagination: ({pageSize: 100} + (if $tok == "" then {} else {token: $tok} end))}')"
    local page n
    if [ "${VETO_ONLY}" -eq 1 ]; then
      # TRAP 4: `kind` is not a server-side filter field, so this is client-side.
      page=$(printf '%s' "${RPC_BODY}" | jq -c '(.entries // [])[] | select((.kind // "") == "AUDIT_LOG_ENTRY_KIND_ENVIRONMENT_VETO")')
    else
      page=$(printf '%s' "${RPC_BODY}" | jq -c '(.entries // [])[]')
    fi
    if [ -n "${page}" ]; then
      printf '%s\n' "${page}"
      n=$(printf '%s\n' "${page}" | wc -l | tr -d ' ')
      emitted=$((emitted + n))
    fi
    token=$(printf '%s' "${RPC_BODY}" | jq -r '.pagination.nextToken // ""')
    pages=$((pages + 1))
    [ -n "${token}" ] && [ "${pages}" -lt 500 ] || break
  done

  echo "exported ${emitted} entr$( [ "${emitted}" -eq 1 ] && echo y || echo ies ) across ${pages} page(s)$( [ "${VETO_ONLY}" -eq 1 ] && echo ' (kind=AUDIT_LOG_ENTRY_KIND_ENVIRONMENT_VETO only)' )" >&2
  echo "next run: ONA_AUDIT_FROM='${to}'   # verbatim, no rounding (TRAP 2)" >&2
}
# HTH Guide Excerpt: end audit-log-ndjson-export

export_logs
