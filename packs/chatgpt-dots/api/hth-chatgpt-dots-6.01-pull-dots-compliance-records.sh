#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-dots-6.1
#   guide:   https://howtoharden.com/guides/chatgpt-dots/#61-ingest-the-compliance-logs-platform-records-that-cover-dots-and-prove-coverage-with-a-test-task
#   profile: L2
#   mode:    read-only
#   requires: CHATGPT_ADMIN_KEY(workspace Admin key, Custom: one fine-grained read scope per event type pulled, e.g. chatgpt.enterprise.compliance_logs_platform.conversation_message.read), CHATGPT_WORKSPACE_ID(UUID), HTH_CLP_AFTER(optional ISO 8601), HTH_CLP_BEFORE(optional), HTH_CLP_EVENT_TYPES(optional), HTH_CLP_OUT(optional NDJSON path), HTH_CLP_ACTOR_EMAIL(optional, --coverage filter), curl, jq
# =============================================================================
# HTH ChatGPT Dots Control 6.1: Ingest the Compliance Logs Platform records that
#   cover dots, and prove coverage with a test task
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls v8 8.2, 8.9, 8.11; NIST 800-53 AU-2, AU-6, AU-11,
#   AU-12; SOC 2 CC7.2; no benchmark equivalent yet
#
# Sources (fetched 2026-10-08):
#   https://chatgpt.com/public/admin/api-reference   (Admin API v2.5.37, tags
#     Compliance Logs Platform, Conversation Messages, Apps, Apps Auth, Codex:
#     GET /compliance/workspaces/{workspace_id}/logs                List Files
#     GET /compliance/workspaces/{workspace_id}/logs/{log_file_id}  Download File (307)
#     GET /compliance/workspaces/{workspace_id}/max_event_time      Get Freshness)
#   https://developers.openai.com/downloads/compliance-api/download_compliance_files.sh
#   https://learn.chatgpt.com/docs/enterprise/dots-admin-guide
#   https://learn.chatgpt.com/docs/enterprise/compliance-api
#   https://learn.chatgpt.com/docs/enterprise/cloud-local-access
#   https://help.openai.com/en/articles/20001407
#
# The dots admin guide's own instruction: "Use supported Compliance API records
# to investigate user messages and dots' replies. Confirm record coverage before
# relying on it for an audit." This pack is both halves: an ingester (deduped
# NDJSON for your SIEM) and, with --coverage, the evidence table you hold
# against the actions a representative dot task actually performed.
#
# TRAPS
#  1. NO DOTS DISCRIMINATOR. There is no dots event_type, actor type or
#     conversation mode. conversation.mode is documented as "chat" or "work"
#     "when available"; actor.type is ACCOUNT_USER, API_KEY or
#     EXTERNAL_COLLABORATION_USER; message.author.client_type lists no dots
#     value. Attribution to the dot rather than its owner must be an explicit
#     objective of the test task — --coverage prints every field that could
#     carry it, and none of them is guaranteed to.
#  2. APP_LOG conversation_id "may be null for background or system initiated
#     calls" — exactly the calls a proactive dot makes. --coverage counts them.
#  3. CODEX_LOG `agent` is "Optional agent attribution ... with type, optional
#     id ... and optional name"; its values are not enumerated anywhere.
#  4. AT-LEAST-ONCE. "duplicates may appear across files. Always de-duplicate
#     using the stable event_id." Done here before anything is emitted.
#  5. `after` IS EXCLUSIVE on end_time ("strictly later"). Carry each type's
#     printed checkpoint verbatim into the next run's HTH_CLP_AFTER; files are
#     per type, so checkpoints are too.
#  6. RETENTION AND LATENCY. Files expire after 30 days; p99 under 30 minutes
#     from event to file; "Late events (within SLA) may appear in a later file".
#     Run on a schedule well inside 30 days, with overlap.
#  7. FRESHNESS IS NOT COMPLETENESS. max_event_time "does not guarantee that all
#     earlier events have arrived", and an old value can simply mean no
#     activity. It is reported, never scored.
#  8. SIGNED URLs. Download File answers 307 to "a short-lived signed URL";
#     common.sh follows it immediately, without the bearer header, and checks
#     file_sha256 before a byte is emitted.
#  9. OTel BLIND SPOT. "Cloud orchestration events do not reach your existing
#     OpenTelemetry collector" (learn cloud-local-access) — this feed is the only
#     admin record of a dot's cloud work.
# 10. PLAN. Enterprise, Edu and Healthcare only (Admin keys "are available for
#     eligible managed ChatGPT workspaces, including ChatGPT Enterprise, ChatGPT
#     Edu, and ChatGPT for Healthcare workspaces", help 20001407); Business (incl. Business Premium) and Pro
#     have no Compliance API, so their dots have no exportable admin record.
# 11. CONTENT. CONVERSATION_MESSAGE carries message text. The NDJSON is created
#     0600 (common.sh umask); treat it as the most sensitive file you hold.
#
# Feed for the Sigma packs, one type and one fine-grained key each (neither scope
# carries conversation content):
#   HTH_CLP_EVENT_TYPES=AUTH_LOG  HTH_CLP_OUT=<path>   -> the 1.02 rule
#     (chatgpt.enterprise.compliance_logs_platform.auth_log.read)
#   HTH_CLP_EVENT_TYPES=AUDIT_LOG HTH_CLP_OUT=<path>   -> the 2.01 / 4.02 / 6.02 rules
#     (chatgpt.enterprise.compliance_logs_platform.audit_log.read)
# Carry each printed checkpoint into the next run's HTH_CLP_AFTER. AUDIT_LOG also
# carries the 7.01 revocation evidence (DELETE_WORKSPACE_DIRECTORY_GROUP_USER for
# an Admin API removal, GROUP_REMOVE_USER for a console removal).
# Download File is retried on 429 (common.sh): the spec allows 100 requests per
# minute per workspace per route, and a 24h four-type pull makes hundreds of calls.
#
# Usage:
#   hth-chatgpt-dots-6.01-pull-dots-compliance-records.sh               # pull → NDJSON
#   hth-chatgpt-dots-6.01-pull-dots-compliance-records.sh --coverage    # + coverage table
#   hth-chatgpt-dots-6.01-pull-dots-compliance-records.sh --freshness   # freshness only
# Exit codes: 0 ran | 2 precondition (incl. a file failing its sha256 check)
# =============================================================================

set -euo pipefail
HTH_PACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=common.sh
. "${HTH_PACK_DIR}/common.sh"

MODE="pull"
case "${1:-}" in
  "") ;;
  --coverage)  MODE="coverage" ;;
  --freshness) MODE="freshness" ;;
  *) echo "usage: $(basename "$0") [--coverage|--freshness]" >&2; exit 2 ;;
esac

cgpt_require
CGPT_SCOPE_HINT="chatgpt.enterprise.compliance_logs_platform.<type>.read for every requested event type"

IFS=',' read -r -a EVENT_TYPES <<<"${HTH_CLP_EVENT_TYPES:-CONVERSATION_MESSAGE,APP_LOG,APP_AUTH_LOG,CODEX_LOG}"
[ "${#EVENT_TYPES[@]}" -gt 0 ] || cgpt_die "HTH_CLP_EVENT_TYPES is empty"
for ET in "${EVENT_TYPES[@]}"; do
  [[ "${ET}" =~ ^[A-Z_]+$ ]] || cgpt_die "event type '${ET}' is not an upper-case Logs Platform type"
done
AFTER="${HTH_CLP_AFTER:-$(hth_iso_hours_ago 24)}"
BEFORE="${HTH_CLP_BEFORE:-}"
hth_iso_to_epoch "${AFTER}" >/dev/null
[ -z "${BEFORE}" ] || hth_iso_to_epoch "${BEFORE}" >/dev/null

# HTH Guide Excerpt: begin clp-freshness
# Newest retained event per type, and its age. Reported, never scored (TRAP 7).
clp_freshness "${EVENT_TYPES[@]}"
NOW="$(hth_now_epoch)"
echo "=== Freshness (p99 SLA: under 30 minutes from event to file) ===" >&2
jq -r --argjson now "${NOW}" 'to_entries[]
  | if .value == null then "  \(.key): null — no retained file with a stored maximum event timestamp"
    else (try (.value | sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601) catch null) as $t
      | if $t == null then "  \(.key): \(.value)  (age not computed: unrecognised timestamp form)"
        else "  \(.key): \(.value)  (\((($now - $t) / 60) | floor) min old)" end
    end' <<<"${CLP_FRESHNESS}" >&2
# HTH Guide Excerpt: end clp-freshness

[ "${MODE}" != "freshness" ] || exit 0

# HTH Guide Excerpt: begin clp-pull-dedupe
# Pull every file for each type in the window, verify, de-duplicate, emit NDJSON.
RAW="${CGPT_TMPDIR}/raw.jsonl"
DEDUPED="${CGPT_TMPDIR}/deduped.ndjson"
: > "${RAW}"
echo "=== Pull: after=${AFTER}${BEFORE:+ before=${BEFORE}} ===" >&2
for ET in "${EVENT_TYPES[@]}"; do
  clp_pull "${ET}" "${AFTER}" "${BEFORE}" "${RAW}"
  echo "  ${ET}: ${CLP_FILES} file(s) verified against file_sha256" >&2
  if [ -n "${CLP_LAST_END_TIME}" ]; then
    echo "  checkpoint: next run HTH_CLP_EVENT_TYPES=${ET} HTH_CLP_AFTER='${CLP_LAST_END_TIME}'  (exclusive — TRAP 5)" >&2
  fi
done
clp_dedupe "${RAW}" "${DEDUPED}"
RAW_N="$(jq -r '1' "${RAW}" | wc -l | tr -d ' ')"
OUT_N="$(wc -l < "${DEDUPED}" | tr -d ' ')"
echo "  ${RAW_N} record(s) pulled, ${OUT_N} after event_id de-duplication" >&2
if [ -n "${HTH_CLP_OUT:-}" ]; then
  cat "${DEDUPED}" >> "${HTH_CLP_OUT}"
  echo "  appended to ${HTH_CLP_OUT} (mode 0600 if newly created)" >&2
elif [ "${MODE}" = "pull" ]; then
  cat "${DEDUPED}"
fi
# HTH Guide Excerpt: end clp-pull-dedupe

[ "${MODE}" = "coverage" ] || exit 0

# HTH Guide Excerpt: begin clp-coverage-summary
# Evidence for the test-task diff: run a representative dot task (a message, an
# app read, an app write, a cloud-browser step, a schedule), pull a window that
# brackets it, then hold every row below against what the dot actually did.
# Optional HTH_CLP_ACTOR_EMAIL narrows to the dot owner's records.
EMAIL="$(printf '%s' "${HTH_CLP_ACTOR_EMAIL:-}" | tr '[:upper:]' '[:lower:]')"
jq -s -r --arg email "${EMAIL}" '
  def owner: $email == "" or ((.actor.user_email // "") | ascii_downcase) == $email;
  def table($rows): $rows | group_by(.) | map("    \(length)\t\(.[0])") | .[];
  [ .[] | select(owner) ] as $r
  | "=== Coverage\(if $email == "" then "" else " for actor " + $email end): \($r | length) record(s) ===",
    "  by type / actor.type:",
    table([ $r[] | "\(.type)  actor=\(.actor.type // "?")" ]),
    "  CONVERSATION_MESSAGE by author.type / conversation.mode / client_type (TRAP 1):",
    table([ $r[] | select(.type == "CONVERSATION_MESSAGE")
            | "author=\(.message.author.type // "?")  mode=\(.conversation.mode // "(absent)")  client=\(.message.author.client_type // "-")" ]),
    "  APP_LOG by app / log_type / conversation_id null (TRAP 2):",
    table([ $r[] | select(.type == "APP_LOG")
            | "\(.app_name // .app_id // "?")  \(.log_type // "?")  conversation_id_null=\(.conversation_id == null)" ]),
    "  APP_AUTH_LOG by action / app_id:",
    table([ $r[] | select(.type == "APP_AUTH_LOG") | "\(.action // "?")  app=\(.app_id // "(null)")" ]),
    "  CODEX_LOG by event_type / agent.type / client_id (TRAP 3):",
    table([ $r[] | select(.type == "CODEX_LOG")
            | "\(.event_type // "?")  agent=\(.agent.type // "(none)")  client=\(.client_id // "?")" ])
' "${DEDUPED}"
echo "Record, per test action: which row above (if any) shows it, and whether it is attributable to the dot."
# HTH Guide Excerpt: end clp-coverage-summary
