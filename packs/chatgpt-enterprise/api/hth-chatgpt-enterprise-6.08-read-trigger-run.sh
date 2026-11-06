#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-enterprise-6.8
#   guide: https://howtoharden.com/guides/chatgpt-enterprise/#68-govern-the-workspace-agents-trigger-api-and-personal-access-tokens
#   profile: L2
#   mode: read-only
#   requires: bash, curl, jq; AGENT_ACCESS_TOKEN, HTH_TRIGGER_ID, HTH_RUN_ID
# Source fetched 2026-11-05: https://developers.openai.com/workspace-agents/trigger-runs
# Beta status GET only. Does not trigger, cancel, retry or mutate a run.
set -euo pipefail
umask 077
command -v curl >/dev/null && command -v jq >/dev/null || { echo 'curl and jq required' >&2; exit 2; }
[[ "${HTH_TRIGGER_ID:-}" =~ ^agtch_[A-Za-z0-9_-]+$ && "${HTH_RUN_ID:-}" =~ ^apirun_[A-Za-z0-9_-]+$ ]] || { echo 'Set exact HTH_TRIGGER_ID and HTH_RUN_ID returned for the authorized trigger' >&2; exit 2; }
[[ -n "${AGENT_ACCESS_TOKEN:-}" && "$AGENT_ACCESS_TOKEN" != *$'\n'* && "$AGENT_ACCESS_TOKEN" != *$'\r'* && "$AGENT_ACCESS_TOKEN" != *'"'* && "$AGENT_ACCESS_TOKEN" != *'\'* ]] || { echo 'Set valid Workspace Agents AGENT_ACCESS_TOKEN' >&2; exit 2; }
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
# HTH Guide Excerpt: begin read-run-status
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"
[[ "$HTH_PROFILE_LEVEL" =~ ^[1234]$ && "$HTH_PROFILE_LEVEL" -ge 2 ]] || { echo 'This pack requires profile 2 or higher (1-4)' >&2; exit 2; }
code="$(printf 'header = "Authorization: Bearer %s"\n' "$AGENT_ACCESS_TOKEN" | \
  curl -q -sS --proto '=https' --path-as-is -K - --max-filesize 10485760 --connect-timeout 15 --max-time 45 \
    -o "$work/run.json" -w '%{http_code}' \
    "https://api.chatgpt.com/v1/workspace_agents/$HTH_TRIGGER_ID/runs/$HTH_RUN_ID")" || exit 2
[[ "$code" = 200 ]] || { echo "Status unavailable: HTTP $code (check token/scope/ID/beta support)" >&2; exit 2; }
jq -e --arg run "$HTH_RUN_ID" --arg trigger "$HTH_TRIGGER_ID" \
  '.object=="workspace_agent.trigger_run" and .id==$run and .api_trigger_id==$trigger and (.status as $s | ["queued","in_progress","suspended","completed","failed"] | index($s)!=null)' \
  "$work/run.json" >/dev/null || { echo 'Unexpected run schema/identity; no status evaluated' >&2; exit 2; }
jq '{id,api_trigger_id,status,created_at,conversation_url,error}' "$work/run.json"
echo 'Status only; response content is unavailable via this API. Verify external effects separately.' >&2
# HTH Guide Excerpt: end read-run-status
