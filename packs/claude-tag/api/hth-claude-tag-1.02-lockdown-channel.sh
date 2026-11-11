#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: claude-tag-1.2
#   guide: https://howtoharden.com/guides/claude-tag/#12-constrain-invocation-and-provide-a-tested-stop-control
#   profile: L1
#   mode: mutating (explicit HTH_APPLY=1 and exact target confirmation; preview default)
#   requires: bash, curl, jq, organization-scoped claude.ai read:claude_tag and write:claude_tag key for apply
# HTH 1.02: Disable an exact existing Claude Tag channel and restrict guests
# Claude Enterprise only: Team plans cannot use these scoped Admin API endpoints.
# Profile: L1 | NIST CSF PR.AA-05 | https://howtoharden.com/guides/claude-tag/
# Beta source: https://platform.claude.com/docs/en/manage-claude/claude-tag-api
# HTH_CHANNEL_ID=slch_...; HTH_SLACK_WORKSPACE_ID=T... (or E...); HTH_SLACK_CHANNEL_ID=C...
# Default: read/preview only. Write requires HTH_APPLY=1 AND HTH_CONFIRM_CHANNEL_ID=$HTH_CHANNEL_ID.
# Uses claude.ai org-scoped read:claude_tag + write:claude_tag, NOT a Console key.
# Guest policy updates may end running sessions asynchronously. Not a global kill switch.
# No automatic rollback or retry: API is last-write-wins, with no conditional writes.
# HTH Guide Excerpt: begin lockdown
set +x
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
id=${HTH_CHANNEL_ID:-}
[[ "$id" =~ ^slch_[A-Za-z0-9]+$ && "${HTH_SLACK_WORKSPACE_ID:-}" =~ ^[TE][A-Z0-9]{1,31}$ && "${HTH_SLACK_CHANNEL_ID:-}" =~ ^[CG][A-Z0-9]{1,31}$ ]] || { echo 'Supply exact API channel ID and Slack workspace/channel IDs.' >&2; exit 2; }
[[ "${HTH_APPLY:-0}" == 0 || ( "${HTH_APPLY}" == 1 && "${HTH_CONFIRM_CHANNEL_ID:-}" == "$id" ) ]] || exit 2
before=$(anthropic_get "$TAG_ROOT/slack_channels/$id")
printf '%s' "$before" | tag_channel_valid "$id"
printf '%s' "$before" | jq -e --arg w "$HTH_SLACK_WORKSPACE_ID" --arg c "$HTH_SLACK_CHANNEL_ID" '.slack.workspace_id==$w and .slack.channel_id==$c' >/dev/null
body='{"settings":{"enabled":false,"guest_policy":{"type":"restrict"}}}'
if [[ "${HTH_APPLY:-0}" != 1 ]]; then
  jq -n --arg id "$id" --argjson body "$body" '{mode:"preview; no writes",id,proposed: $body}'
  exit 0
fi
# Private snapshot for operator review, not automatic replay (which could restore unsafe access).
evidence=$(anthropic_evidence_dir)
printf '%s\n' "$before" > "$evidence/before.json"
printf 'Private before snapshot: %s\n' "$evidence/before.json" >&2
# Minimal partial update leaves instructions/model/environment untouched, including runner pools.
if ! anthropic_post "$TAG_ROOT/slack_channels/$id" "$body" >/dev/null; then
  echo 'Write outcome unresolved. Read current settings before any retry; do not assume failure means no write.' >&2; exit 1
fi
after=$(anthropic_get "$TAG_ROOT/slack_channels/$id")
printf '%s' "$after" > "$evidence/after.json"
printf '%s' "$after" | tag_channel_valid "$id"
printf '%s\n%s' "$before" "$after" | jq -se '.[1].settings.enabled==false and .[1].settings.guest_policy.type=="restrict" and .[0].slack==.[1].slack and (.[0].settings|del(.enabled,.guest_policy))==(.[1].settings|del(.enabled,.guest_policy))' >/dev/null || { echo 'Read-back mismatch or concurrent edit; inspect snapshots, do not automatically overwrite.' >&2; exit 1; }
effective=$(anthropic_get "$TAG_ROOT/slack_channels/$id?include_inherited=true")
printf '%s' "$effective" | tag_channel_valid "$id"
printf '%s' "$effective" | jq -e '.settings.enabled==false and .settings.guest_policy.type=="restrict"' >/dev/null
jq -n --arg id "$id" '{id,status:"stored and effective lockdown verified",limits:"Not confirmation that running sessions terminated; other channels and direct messages unchanged"}'
# HTH Guide Excerpt: end lockdown
