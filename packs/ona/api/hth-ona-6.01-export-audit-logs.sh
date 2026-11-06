#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-6.1
#   guide:   https://howtoharden.com/guides/ona/#61-enable-audit-logging-and-siem-streaming
#   profile: L1
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional); HTH_PROFILE_LEVEL >= 1; sibling common.sh
# =============================================================================
# HTH Ona Control 6.1: Enable Audit Logging and SIEM Streaming
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 8.2, 8.9
# Source: https://howtoharden.com/guides/ona/#61-enable-audit-logging-and-siem-streaming
# Dependencies: Bash, curl, jq; sibling common.sh; HTH_PROFILE_LEVEL >= 1
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
# OUTPUT CONTRACT: one JSON object per line (NDJSON) on stdout after ALL pages
# complete. No partial feed is published on failure. Diagnostics go to stderr.
# Use a caller-side umask 077 and private destination: audit records are sensitive.
#
# Tunables: ONA_AUDIT_FROM / ONA_AUDIT_TO (RFC 3339). Default window: last 24h.
# Exit codes: 0 exported | 2 precondition (Enterprise-only, auth, transport)
# =============================================================================

set +x
set -euo pipefail
# Download the complete api directory; common.sh is required.
# Use same-domain tokens. Custom HTTPS bases also require matching
# ONA_REVIEWED_API_BASE. Stdout is staged until completion; keep it private.
# shellcheck source=packs/ona/api/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
ona_init 1
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
  local from to emitted=0
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

  # Keep the historical 500-page exporter ceiling, but fail if a cursor remains.
  paginate 'EventService/ListAuditLogs' \
    "$(jq -nc --arg f "$from" --arg t "$to" '{filter:{from:$f,to:$t}}')" 'entries' "${ONA_EXPORT_MAX_PAGES:-500}"
  local selected="$PAGE_ITEMS"
  if [ "$VETO_ONLY" -eq 1 ]; then
    selected=$(jq -c '[.[] | select((.kind // "") == "AUDIT_LOG_ENTRY_KIND_ENVIRONMENT_VETO")]' <<< "$selected")
  fi
  emitted=$(jq 'length' <<< "$selected")
  jq -c '.[]' <<< "$selected"
  echo "exported ${emitted} entries; all observed pages completed" >&2
  echo "next run: ONA_AUDIT_FROM='${to}'   # verbatim, no rounding (TRAP 2)" >&2
  ona_complete
}
# HTH Guide Excerpt: end audit-log-ndjson-export

export_logs
