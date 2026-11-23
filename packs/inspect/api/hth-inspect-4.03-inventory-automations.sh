#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: inspect-4.3
#   guide: https://howtoharden.com/guides/inspect/#43-narrow-automation-triggers-and-destinations
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq, python3, INSPECT_API_KEY with target access
# HTH 4.3: Narrow Automation Triggers and Destinations
# Profile: L1 | NIST SP 800-53 AC-6 | https://howtoharden.com/guides/inspect/
# Sources: https://docs.inspect.com/api/openapi.json (2026-11-17; available v2 routes).
# No live tenant validation. Download common.sh beside this file.
# HTH Guide Excerpt: begin inventory-automations
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"
hth_init
max=${HTH_MAX_PAGES:-1000}; [[ "$max" =~ ^[1-9][0-9]{0,3}$ ]] || hth_unknown 'HTH_MAX_PAGES must be 1..9999'
cursor=''; pages=0; : > "$HTH_TEMP/items.jsonl"; : > "$HTH_TEMP/cursors.jsonl"
while :; do
  path='/api/v2/automations?first=100&scope=all'
  [[ -z "$cursor" ]] || path+="&after=$(jq -rn --arg c "$cursor" '$c|@uri')"
  hth_request GET "$path" "$HTH_TEMP/page.json"
  jq -e '(.data|type)=="array" and (.meta.has_next_page|type)=="boolean" and (.meta|has("next_cursor")) and (.meta.next_cursor==null or (.meta.next_cursor|type)=="string") and all(.data[]; (.id|type)=="string" and (.enabled|type)=="boolean" and (.viewer_can_edit|type)=="boolean" and (.triggers|type)=="array" and (.repositories|type)=="array" and all(.repositories[];type=="string") and (.name|type)=="string" and (.run_as=="owner" or .run_as=="inspect") and has("agent_id") and (.agent_id==null or (.agent_id|type)=="string") and (.autofix_ci_failures|type)=="boolean" and has("auto_address_pull_request_reviews_policy") and all(.triggers[]; (.type|type)=="string"))' "$HTH_TEMP/page.json" >/dev/null || hth_unknown 'malformed automation page'
  jq -c '.data[]|{id,name,enabled,viewer_can_edit,repositories,run_as,agent_id,trigger_types:[.triggers[].type],autofix_ci_failures,auto_address_pull_request_reviews_policy}' "$HTH_TEMP/page.json" >> "$HTH_TEMP/items.jsonl"
  pages=$((pages+1))
  [[ $(jq -r '.meta.has_next_page' "$HTH_TEMP/page.json") == true ]] || break
  cursor=$(jq -r '.meta.next_cursor // empty' "$HTH_TEMP/page.json")
  [[ -n "$cursor" ]] || hth_unknown 'next page without cursor'
  jq -se --arg c "$cursor" 'index($c)==null' "$HTH_TEMP/cursors.jsonl" >/dev/null || hth_unknown 'cursor repeated; partial evidence discarded'
  (( pages < max )) || hth_unknown 'page limit reached; partial evidence discarded'
  jq -nc --arg c "$cursor" '$c' >> "$HTH_TEMP/cursors.jsonl"
done
jq -se '(map(.id)|unique|length)==length' "$HTH_TEMP/items.jsonl" >/dev/null || hth_unknown 'duplicate items across pages; retry after inventory stabilizes'
jq -s '{scope:"Visible automations, including published/soft forks; archived excluded; not all tenant automations",warning:"viewer_can_edit=false means destinations, collaborators and execution settings are redacted; do not treat them as absent. Prompts, trigger details, and recipients omitted; inspect these in the console.",automations:.}' "$HTH_TEMP/items.jsonl" > "$HTH_TEMP/output.json"
hth_save "$HTH_TEMP/output.json"
printf 'COLLECTED: %s visible automations; review redaction and trigger details in Inspect.\n' "$(jq '.automations|length' "$HTH_TEMP/output.json")"
# HTH Guide Excerpt: end inventory-automations
