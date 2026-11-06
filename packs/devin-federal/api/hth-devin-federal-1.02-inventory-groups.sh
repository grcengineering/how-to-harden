#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-federal-1.2
#   guide: https://howtoharden.com/guides/devin-federal/#12-reconcile-group-model-access-and-acu-limits
#   profile: L2
#   mode: read-only
#   requires: common.sh; jq/bun/curl; scoped federal key; confirmed origin and new output
# Source: https://docs.devin.ai/federal/api/group-management (2026-11-05)
# HTH Guide Excerpt: begin inventory-groups
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"
hth_federal_init
cursor=''; pages=0
: > "$HTH_TEMP/groups.jsonl"; : > "$HTH_TEMP/cursors.jsonl"
while :; do
  # Credential enters jq through its environment, never command-line arguments.
  jq -n --arg cursor "$cursor" '{service_key:env.WINDSURF_SERVICE_KEY,page_size:100,page_token:$cursor}' > "$HTH_TEMP/request.json"
  hth_federal_post_read ListGroups "$HTH_TEMP/request.json" "$HTH_TEMP/page.json"
  # Group examples use camelCase; API overview says snake_case. Accept either,
  # but reject missing or contradictory cursors instead of silently truncating.
  jq -e '(.groups|type=="array") and
    ((has("nextPageToken") and (.nextPageToken|type=="string")) or
     (has("next_page_token") and (.next_page_token|type=="string"))) and
    (if has("nextPageToken") and has("next_page_token") then .nextPageToken==.next_page_token else true end) and
    all(.groups[]; (.groupId|type=="string") and (.groupId|length>0))' "$HTH_TEMP/page.json" >/dev/null || hth_unknown 'malformed or conflicting list/pagination envelope'
  jq -c '.groups[]' "$HTH_TEMP/page.json" >> "$HTH_TEMP/groups.jsonl"
  pages=$((pages+1)); cursor="$(jq -r '.nextPageToken // .next_page_token' "$HTH_TEMP/page.json")"
  [[ -n "$cursor" ]] || break
  (( pages < HTH_MAX_PAGES )) || hth_unknown 'pagination limit reached; partial evidence discarded'
  jq -se --arg c "$cursor" 'index($c)==null' "$HTH_TEMP/cursors.jsonl" >/dev/null || hth_unknown 'repeated pagination cursor'
  jq -nc --arg c "$cursor" '$c' >> "$HTH_TEMP/cursors.jsonl"
done
jq -se '([.[].groupId]|length)==([.[].groupId]|unique|length)' "$HTH_TEMP/groups.jsonl" >/dev/null || hth_unknown 'duplicate group IDs; inventory changed or pagination unreliable'
: > "$HTH_TEMP/details.jsonl"
while IFS= read -r group; do
  id="$(jq -r '.groupId' <<< "$group")"
  jq -n --arg id "$id" '{service_key:env.WINDSURF_SERVICE_KEY,group_id:$id}' > "$HTH_TEMP/request.json"
  hth_federal_post_read GetGroup "$HTH_TEMP/request.json" "$HTH_TEMP/detail.json"
  jq -e --arg id "$id" '(.group|type=="object") and .group.groupId==$id and (.group.cascadeModelUids|type=="array") and (.group.commandModelUids|type=="array")' "$HTH_TEMP/detail.json" >/dev/null || hth_unknown 'malformed/mismatched group detail'
  jq -c '.group|{groupId,name,memberCount,cascadeModelUids,commandModelUids,configuredCycleAcuLimit,effectiveCycleAcuLimit}' "$HTH_TEMP/detail.json" >> "$HTH_TEMP/details.jsonl"
done < "$HTH_TEMP/groups.jsonl"
jq -s '{scope:"groups visible to this key; group-scoped keys are not team-wide evidence",groups:.}' "$HTH_TEMP/details.jsonl" > "$HTH_TEMP/evidence.json"
hth_private_copy "$HTH_TEMP/evidence.json" "$HTH_OUTPUT_FILE"
printf 'COLLECTED %s visible groups; reconcile team bounds, user overrides and membership separately.\n' "$(jq '.groups|length' "$HTH_TEMP/evidence.json")"
# HTH Guide Excerpt: end inventory-groups
