#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-3.3
#   guide: https://howtoharden.com/guides/devin/#33-bound-automations-oncall-and-auto-triage-authority
#   profile: L2
#   mode: read-only
#   requires: cog_ service-user key; organization access; new output file
# Sources: https://docs.devin.ai/product-guides/automations
# https://github.com/CognitionAI/terraform-provider-devin/blob/v0.5.0/internal/api/openapi.json
# Retrieved 2026-11-05. Inventory is not a least-privilege verdict.
# HTH Guide Excerpt: begin inventory-automations
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"
hth_init 2
[[ "${DEVIN_ORG_ID:-}" =~ ^[A-Za-z0-9_-]+$ ]] || hth_unknown 'set a confirmed DEVIN_ORG_ID'
[[ -n "${HTH_OUTPUT_FILE:-}" ]] || hth_unknown 'set HTH_OUTPUT_FILE to a new private evidence file'
hth_paginate "/v3/organizations/${DEVIN_ORG_ID}/automations" "$HTH_TEMP/automations.jsonl"
hth_paginate "/v3/organizations/${DEVIN_ORG_ID}/oncall/responders" "$HTH_TEMP/responders.jsonl"
jq -se 'all(.[]; (.automation_id|type=="string") and (.name|type=="string") and (.enabled|type=="boolean") and (.triggers|type=="array") and (.actions|type=="array"))' "$HTH_TEMP/automations.jsonl" >/dev/null || hth_unknown 'malformed automation item; partial evidence discarded'
jq -se 'all(.[]; (.id|type=="string") and (.name|type=="string") and (.enabled|type=="boolean") and (.triggers|type=="array"))' "$HTH_TEMP/responders.jsonl" >/dev/null || hth_unknown 'malformed responder item; partial evidence discarded'
# Event/condition configuration can itself contain secrets; keep all output private.
# Omit prompt/runbook text, actions, tools, URL/secret fields and arbitrary metadata.
jq -n --arg org "$DEVIN_ORG_ID" --slurpfile a "$HTH_TEMP/automations.jsonl" --slurpfile r "$HTH_TEMP/responders.jsonl" '
 {org_id:$org,scope:"visible to supplied credential; not an enterprise-completeness claim",
 automations:[$a[]|{automation_id,name,enabled,run_as,slack_reply_access,teams_reply_access,limits,concurrency,security_profile,
   triggers:[.triggers[]|{event_type,conditions}]}],
 responders:[$r[]|{id,name,enabled,run_as,source_channel_id,
   triggers:[.triggers[]|{event_type,conditions}]}]}' > "$HTH_TEMP/evidence.json"
hth_save_private "$HTH_TEMP/evidence.json" "$HTH_OUTPUT_FILE"
printf 'COLLECTED: %s automations; %s responders. Review scope, identity, triggers, tools and active runs separately.\n' \
 "$(jq '.automations|length' "$HTH_TEMP/evidence.json")" "$(jq '.responders|length' "$HTH_TEMP/evidence.json")"
# HTH Guide Excerpt: end inventory-automations
