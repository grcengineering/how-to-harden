#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-6.1
#   guide:   https://howtoharden.com/guides/ona/#61-enable-audit-logging-and-siem-streaming
#   profile: L1
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only; the identity must be an Organization Admin or hold the Audit Log Reader role)
# =============================================================================
# HTH Ona Control 6.1: Enable Audit Logging and SIEM Streaming — NDJSON export
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 8.2, 8.9 | NIST 800-53 AU-2, AU-6 | SOC 2 CC7.2
# Source: https://ona.com/docs/ona/audit-logs/overview.md
#
# WHY cli/: Ona publishes NO named SIEM connector — no Splunk app, no Sentinel
# data connector, no Datadog integration, no S3/GCS log-export destination. The
# vendor's own words are "For programmatic access and SIEM integration, use the
# REST API". Ingestion is therefore a customer-built pull, and `ona audit-logs`
# is the documented pull. This pack emits NDJSON, the shape every SIEM ingests.
#
# PULL, NOT STREAM. The WatchEvents streaming API looks like the obvious feed and
# is the wrong one: it returns `{operation, resourceType, resourceId}` with NO
# actor, NO action text and NO timestamp, and it is open to any user with read
# access to the resource. ListAuditLogs (this command) is the actor-attributed
# record and is restricted to Admins / Audit Log Readers. Ship this, not that.
#
# -----------------------------------------------------------------------------
# ACCESS AND ENTITLEMENT
# -----------------------------------------------------------------------------
# Audit logs are Enterprise-plan only. "Organization admins and members with the
# Audit Log Reader role can access audit logs. Regular members cannot access
# audit logs, even for resources they own." On a non-Enterprise org the API
# answers HTTP 400 failed_precondition ("feature is only available for
# enterprise customers") — this pack surfaces that as exit 2, not as a finding.
#
# -----------------------------------------------------------------------------
# TRAPS
# -----------------------------------------------------------------------------
# T1  THE FLAG IS `--format=json`, NOT `-o json`. Every other `ona` command takes
#     the global `-o json|yaml`; `ona audit-logs` documents `--format=json|yaml`.
#     Both spellings are real, on different commands.
# T2  VETO EXEC ENTRIES ARE PREVIEW-GATED. "Veto Exec enforcement entries are in
#     preview and only appear for organizations where this preview is enabled."
#     An empty `--veto` result does NOT prove the policy is not enforcing.
# T3  `--subject-type=environment` IS THE ONLY SERVER-SIDE FILTER FOR VETO. There
#     is no `--kind` flag, so the kind test below is a client-side jq select on
#     AUDIT_LOG_ENTRY_KIND_ENVIRONMENT_VETO.
# T4  HISTORICAL ENTRIES CARRY DEPRECATED KINDS. Older Veto entries retain
#     `…_AGENT_SECURITY_EXEC_BLOCKED` / `…_AGENT_SECURITY_EXEC_AUDITED`, and
#     entries with a missing or unrecognised stored kind come back as
#     `…_UNSPECIFIED`. The --veto filter matches all four so history is not lost.
# T5  `action` IS FREE TEXT. Never key a detection on it alone; the closed enums
#     are `kind`, `subjectType` and `actorPrincipal`. The one documented exception
#     is the Veto Exec grammar: "Veto Exec blocked|audited: <filename> (<hash>)".
# T6  THE LIST RESPONSE HAS NO `details`. Veto's typed payload
#     (details.vetoExec.filename / .executable / .action / .process) only comes
#     back from GetAuditLog on a single entry id. Enrich in the SIEM, or fetch
#     per id.
# T7  PAGINATION CAPS AT 100 PER PAGE. `--limit` above 100 is served by the CLI
#     paging internally; the API itself will not return more than 100 at a time.
# T8  RETENTION IS UNPUBLISHED ("according to your organization's data retention
#     policy"), which is precisely why a periodic export to external storage is
#     the control and not a nice-to-have.
#
# OUTPUT: one JSON object per line on STDOUT (redirect it — it contains actor and
# subject identifiers by design). Progress and counts go to STDERR.
# EXIT CODES: 0 exported (an empty window is a legitimate result, not a finding);
#             2 precondition (no CLI, not authenticated, not Enterprise, or the
#             identity lacks Admin / Audit Log Reader).
#
# Requires: `ona` on PATH and authenticated, jq.
# Install:  brew install gitpod-io/tap/ona
# =============================================================================

set -euo pipefail

: "${ONA_TOKEN:?export ONA_TOKEN with a personal access token, then run: ona login}"

ONA_BIN="${ONA_BIN:-ona}"
LIMIT="${LIMIT:-1000}"

command -v "${ONA_BIN}" >/dev/null 2>&1 || {
  echo "PRECONDITION: '${ONA_BIN}' not on PATH. brew install gitpod-io/tap/ona" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "PRECONDITION: jq required." >&2; exit 2; }
"${ONA_BIN}" whoami >/dev/null 2>&1 || {
  echo "PRECONDITION: not authenticated. Run 'ona login' or 'ona login --token \"\$ONA_TOKEN\"'." >&2
  exit 2; }

# HTH Guide Excerpt: begin cli-audit-log-ndjson-export
# Export Ona audit logs as NDJSON for SIEM ingestion.
#
#   ./hth-ona-6.01-export-audit-logs.sh              > audit.ndjson
#   FROM=2026-08-01T00:00:00Z TO=2026-08-19T00:00:00Z ./…            > window.ndjson
#   SUBJECT_TYPE=personal_access_token ./…                           > pat.ndjson
#   ACTOR_PRINCIPAL=service_account ./…                              > sa.ndjson
#   ./hth-ona-6.01-export-audit-logs.sh --veto       > veto.ndjson
#
# Environment: LIMIT (default 1000), FROM, TO (RFC 3339), SUBJECT_TYPE,
# ACTOR_PRINCIPAL. Subject types: environment, project, secret, user_secret,
# organization_secret, sso_config, personal_access_token, group, runner,
# workflow_execution. Actor principals: user, service_account.

VETO_PRESET=0
[ "${1:-}" = "--veto" ] && VETO_PRESET=1

# T1: audit-logs takes --format, not -o.
args=(audit-logs --format=json "--limit=${LIMIT}")
[ -n "${FROM:-}" ] && args+=("--from=${FROM}")
[ -n "${TO:-}" ]   && args+=("--to=${TO}")
[ -n "${ACTOR_PRINCIPAL:-}" ] && args+=("--actor-principal=${ACTOR_PRINCIPAL}")

if [ "${VETO_PRESET}" -eq 1 ]; then
  # T3: environment is the only server-side narrowing available for Veto.
  args+=("--subject-type=environment")
elif [ -n "${SUBJECT_TYPE:-}" ]; then
  args+=("--subject-type=${SUBJECT_TYPE}")
fi

echo "==> ona ${args[*]}" >&2

raw=""
if ! raw="$("${ONA_BIN}" "${args[@]}" 2>&1)"; then
  case "${raw}" in
    *enterprise*|*failed_precondition*|*FailedPrecondition*)
      echo "PRECONDITION: audit logs are an Enterprise-plan feature and this org is not" >&2
      echo "  entitled — the management plane answered failed_precondition." >&2
      ;;
    *permission*|*Permission*|*forbidden*|*Forbidden*|*403*)
      echo "PRECONDITION: this identity cannot read audit logs. Grant Organization Admin" >&2
      echo "  or the Audit Log Reader role; regular members are refused even for their" >&2
      echo "  own resources." >&2
      ;;
    *)
      echo "PRECONDITION: 'ona audit-logs' failed." >&2
      ;;
  esac
  exit 2
fi

# The CLI's JSON envelope is not published: accept {"entries":[…]}, a bare array,
# or already-NDJSON, and normalise all three to one object per line.
entries="$(printf '%s' "${raw}" \
  | jq -c '(.entries? // .items? // .) | if type=="array" then .[] else . end' 2>/dev/null || true)"

if [ -z "${entries}" ]; then
  echo "0 entries returned for this window. An empty window is a legitimate result," >&2
  echo "not a finding — audit entries are only written for security-relevant and" >&2
  echo "human-meaningful activity." >&2
  exit 0
fi

if [ "${VETO_PRESET}" -eq 1 ]; then
  # T4: match the current Veto kind and both deprecated historical kinds, plus
  # entries whose kind was lost (UNSPECIFIED) but whose action still carries the
  # documented Veto Exec grammar (T5).
  filtered="$(printf '%s\n' "${entries}" | jq -c 'select(
      (.kind // "") == "AUDIT_LOG_ENTRY_KIND_ENVIRONMENT_VETO"
      or (.kind // "") == "AUDIT_LOG_ENTRY_KIND_AGENT_SECURITY_EXEC_BLOCKED"
      or (.kind // "") == "AUDIT_LOG_ENTRY_KIND_AGENT_SECURITY_EXEC_AUDITED"
      or ((.action // "") | startswith("Veto Exec"))
    )')"
  n="$(printf '%s' "${filtered}" | grep -c . || true)"
  echo "veto entries: ${n} (of $(printf '%s' "${entries}" | grep -c . || true) exported)" >&2
  if [ "${n}" -eq 0 ]; then
    echo "NOTE: zero Veto entries does NOT prove the policy is not enforcing — Veto Exec" >&2
    echo "      audit entries are preview-gated and only appear for orgs with the" >&2
    echo "      preview enabled." >&2
  fi
  printf '%s' "${filtered}"
  [ -n "${filtered}" ] && echo
  exit 0
fi

echo "entries: $(printf '%s' "${entries}" | grep -c . || true)" >&2
printf '%s\n' "${entries}"
exit 0
# HTH Guide Excerpt: end cli-audit-log-ndjson-export
