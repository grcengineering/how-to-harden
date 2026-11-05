#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-dots-6.1
#   guide: https://howtoharden.com/guides/chatgpt-dots/#61-ingest-the-compliance-logs-platform-records-that-cover-dots-and-prove-coverage-with-a-test-task
#   profile: L2
#   mode: read-only
#   requires: bash, curl, jq; CHATGPT_ADMIN_KEY, CHATGPT_WORKSPACE_ID, HTH_LOG_DIR, HTH_AFTER; HTH_EVENT_TYPES optional
# Current official list/download contract fetched 2026-11-05:
# https://developers.openai.com/downloads/compliance-api/download_compliance_files.sh
# Event family support: https://learn.chatgpt.com/docs/enterprise/dots-admin-guide
# Reads workspace logs and writes private LOCAL evidence/checkpoints only.
# No live policy checks, lifecycle inference, writes to OpenAI or automatic SIEM send.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
hth_require
[[ -n "${HTH_LOG_DIR:-}" && "$HTH_LOG_DIR" = /* ]] || hth_die 'set HTH_LOG_DIR to a private absolute output directory'
[[ ! -L "$HTH_LOG_DIR" ]] || hth_die 'output directory must not be a symlink'
[[ "${HTH_AFTER:-}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]] || hth_die 'set HTH_AFTER to UTC ISO8601 (YYYY-MM-DDTHH:MM:SSZ)'
jq -en --arg t "$HTH_AFTER" '$t | fromdateiso8601' >/dev/null || hth_die 'invalid start timestamp'
mkdir -p "$HTH_LOG_DIR"
chmod 700 "$HTH_LOG_DIR"
work="$(mktemp -d "$HTH_LOG_DIR/.pull.XXXXXX")"
trap 'rm -rf "$work"' EXIT
# HTH Guide Excerpt: begin export-workspace-logs
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"
[[ "$HTH_PROFILE_LEVEL" =~ ^[1234]$ && "$HTH_PROFILE_LEVEL" -ge 2 ]] || { echo 'This pack requires profile 2 or higher (1-4)' >&2; exit 2; }
# Explicit authorized log families only. No invented agent.run/connector.* enums.
IFS=',' read -r -a families <<< "${HTH_EVENT_TYPES:-CODEX_LOG}"
[[ "${#families[@]}" -gt 0 ]] || hth_die 'at least one event family required'
for family in "${families[@]}"; do
  [[ "$family" =~ ^[A-Z][A-Z0-9_]+$ ]] || hth_die 'event families must be comma-separated uppercase names'
  checkpoint="$HTH_LOG_DIR/${family}.checkpoint"
  [[ ! -L "$checkpoint" ]] || hth_die 'checkpoint must not be a symlink'
  after="$HTH_AFTER"
  if [[ -f "$checkpoint" ]]; then
    after="$(cat "$checkpoint")"
    jq -en --arg t "$after" '$t | fromdateiso8601' >/dev/null || hth_die 'invalid checkpoint'
  fi
  pages=0
  while :; do
    hth_get "/compliance/workspaces/$CHATGPT_WORKSPACE_ID/logs" "$work/page.json" \
      --data-urlencode "event_type=$family" --data-urlencode 'limit=100' --data-urlencode "after=$after"
    jq -e '(.data|type)=="array" and (.has_more|type)=="boolean" and all(.data[]; (.id|type)=="string")' "$work/page.json" >/dev/null || hth_die 'malformed page; checkpoint unchanged'
    jq -r '.data[].id' "$work/page.json" > "$work/ids"
    while IFS= read -r log_id; do
      hth_safe_id "$log_id"
      target="$HTH_LOG_DIR/${family}-${log_id}.jsonl"
      [[ ! -L "$target" ]] || hth_die 'log target must not be a symlink'
      if [[ -f "$target" ]]; then
        jq -ne 'reduce inputs as $line (0; if ($line|type)=="object" then .+1 else error("expected JSONL object") end) | .>0' "$target" >/dev/null || hth_die 'existing log is invalid; checkpoint unchanged'
        continue
      fi
      hth_get "/compliance/workspaces/$CHATGPT_WORKSPACE_ID/logs/$log_id" "$work/download"
      jq -ne 'reduce inputs as $line (0; if ($line|type)=="object" then .+1 else error("expected JSONL object") end) | .>0' "$work/download" >/dev/null || hth_die 'invalid JSONL download; checkpoint unchanged'
      chmod 600 "$work/download"
      mv "$work/download" "$target"
    done < "$work/ids"
    next="$(jq -r '.last_end_time // empty' "$work/page.json")"
    more="$(jq -r '.has_more' "$work/page.json")"
    if [[ -z "$next" ]]; then
      [[ "$more" = false && ! -s "$work/ids" ]] || hth_die 'missing pagination timestamp; checkpoint unchanged'
      break
    fi
    jq -en --arg t "$next" '$t | fromdateiso8601' >/dev/null || hth_die 'invalid pagination timestamp'
    jq -en --arg a "$after" --arg n "$next" '($n|fromdateiso8601) > ($a|fromdateiso8601)' >/dev/null || hth_die 'nonadvancing pagination timestamp'
    # Commit a page only after all its files are validated and atomically saved.
    printf '%s\n' "$next" > "$work/checkpoint"
    mv "$work/checkpoint" "$checkpoint"
    after="$next"
    pages=$((pages + 1))
    [[ "$more" = true ]] || break
    [[ "$pages" -lt 10000 ]] || hth_die 'pagination limit reached; rerun to continue'
  done
  echo "Export finished for $family; verify freshness/coverage and SIEM ingestion separately." >&2
done
# HTH Guide Excerpt: end export-workspace-logs
