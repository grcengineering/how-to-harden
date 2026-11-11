#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: claude-tag-1.1
#   guide: https://howtoharden.com/guides/claude-tag/#11-inventory-effective-access-before-enabling-tools
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq, organization-scoped claude.ai read:claude_tag key
# HTH 1.01: Audit Claude Tag effective access and explicit Bundle targets
# Claude Enterprise only: Team plans cannot use these scoped Admin API endpoints.
# Profile: L1 | NIST CSF PR.AA-05 | https://howtoharden.com/guides/claude-tag/
# Beta source: https://platform.claude.com/docs/en/manage-claude/claude-tag-api
# Requires bash, curl, jq; read:claude_tag. Optional HTH_GRID_IDS='E0123 E4567'.
# Optional HTH_APPROVED_CHANNEL_IDS='slch_ABC slch_DEF' is an exact reviewed allowlist.
# No tenant writes. Report omits instructions/Bundle descriptions. Protect report IDs.
# HTH Guide Excerpt: begin audit
set +x
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
for id in ${HTH_GRID_IDS:-}; do [[ "$id" =~ ^E[A-Z0-9]{1,31}$ ]] || exit 2; done
for id in ${HTH_APPROVED_CHANNEL_IDS:-}; do [[ "$id" =~ ^slch_[A-Za-z0-9]+$ ]] || exit 2; done
workspaces=$(anthropic_page_token_all "$TAG_ROOT/slack_workspaces?include_inherited=true&limit=100")
printf '%s' "$workspaces" | jq -e 'all(.[]; .type=="slack_workspace" and (.id|test("^slws_[A-Za-z0-9]+$")) and (.slack.workspace_id|test("^T[A-Z0-9]{1,31}$")) and (.settings.enabled|type)=="boolean" and (.settings.guest_policy.type|type)=="string")' >/dev/null
channels='[]'
workspace_ids=$(printf '%s' "$workspaces" | jq -r '.[].slack.workspace_id')
for id in $workspace_ids ${HTH_GRID_IDS:-}; do
  rows=$(anthropic_page_token_all "$TAG_ROOT/slack_channels?include_inherited=true&limit=100&slack_workspace_id=$id")
  printf '%s' "$rows" | jq -e 'all(.[]; .type=="slack_channel" and (.id|test("^slch_[A-Za-z0-9]+$")) and (.settings.enabled|type)=="boolean" and (.settings.guest_policy.type|type)=="string")' >/dev/null
  channels=$(printf '%s\n%s' "$channels" "$rows" | jq -cs 'add|unique_by(.id)')
done
bundles=$(anthropic_page_token_all "$TAG_ROOT/bundles?limit=100")
printf '%s' "$bundles" | jq -e 'all(.[]; .type=="bundle" and (.id|test("^capp_[A-Za-z0-9]+$")))' >/dev/null
targets='[]'
for id in $(printf '%s' "$bundles" | jq -r '.[].id'); do
  rows=$(anthropic_page_token_all "$TAG_ROOT/bundles/$id/targets?limit=100")
  rows=$(printf '%s' "$rows" | jq -ce --arg bundle "$id" 'map(if (.id|type)=="string" and (.type|type)=="string" then {bundle_id:$bundle,id,type,slack_channel_id,slack_workspace_id} else error("invalid target") end)')
  targets=$(printf '%s\n%s' "$targets" "$rows" | jq -cs 'add')
done
# Emit nothing until every requested page succeeds. This is NOT full Slack inventory.
jq -n --argjson workspaces "$workspaces" --argjson channels "$channels" --argjson targets "$targets" --arg approved "${HTH_APPROVED_CHANNEL_IDS:-}" --arg grids "${HTH_GRID_IDS:-}" '
  def minimal: {id,slack,settings:(.settings|del(.instructions)),sources:(.sources|del(.instructions))};
  ($approved|split(" ")|map(select(length>0))) as $allow |
  {scope:"configured Claude Tag resources only", supplied_grid_ids:$grids,
   limitations:["Grid IDs must be supplied separately; omitted Grids are not inventoried", "Not all Slack channels are configured", "Bundle contents, Default Slack access and rule-derived grants require claude.ai review", "No atomic inventory snapshot; reconcile changes during audit"],
   workspaces:($workspaces|map(minimal)), channels:($channels|map(minimal)), explicit_bundle_targets:$targets,
   findings:[$channels[] | . as $c | if (.settings.enabled and ($allow|index($c.id)|not)) then {id,reason:"enabled without supplied approval"} else empty end,
      if .settings.guest_policy.type=="allow" then {id,reason:"guest full access"} elif (.settings.guest_policy.type!="restrict" and .settings.guest_policy.type!="channel_only") then {id,reason:"unknown guest policy; review"} else empty end]}'
# HTH Guide Excerpt: end audit
