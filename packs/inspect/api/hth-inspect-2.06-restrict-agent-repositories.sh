#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: inspect-2.6
#   guide: https://howtoharden.com/guides/inspect/#26-enforce-an-agent-repository-allowlist
#   profile: L2
#   mode: mutating (preview default; explicit HTH_APPLY=1 and matching HTH_CONFIRM_ID)
#   requires: bash, curl, jq, python3, INSPECT_API_KEY with target access
# HTH 2.6: Enforce an Agent Repository Allowlist
# Profile: L2 | NIST SP 800-53 AC-6 | https://howtoharden.com/guides/inspect/
# Sources: https://docs.inspect.com/api/openapi.json (2026-11-17; available v2 routes).
# No live tenant validation. Download common.sh beside this file.
# HTH Guide Excerpt: begin restrict-agent-repositories
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"
hth_init
id=${INSPECT_AGENT_ID:-}; hth_id "$id"; hth_apply_gate "$id"
[[ -f "${HTH_REPOSITORIES_FILE:-}" ]] || hth_unknown 'set HTH_REPOSITORIES_FILE to a JSON array of approved repository IDs'
# Parse and validate the input once. Later gates and the PATCH use this same snapshot.
jq -se 'if length==1 and (.[0]|type)=="array" and (.[0]|length)>0 and all(.[0][]; type=="string" and length>0) and (.[0]|unique|length)==(.[0]|length) then .[0] else error("invalid allowlist") end' "$HTH_REPOSITORIES_FILE" > "$HTH_TEMP/desired.json" 2>/dev/null || hth_unknown 'require a nonempty unique string array; null/empty allowlists refused'
jq '{repositories:.}' "$HTH_TEMP/desired.json" > "$HTH_TEMP/body.json"
hth_request GET "/api/v2/agents/$id" "$HTH_TEMP/before.json"
hth_agent_valid "$id" "$HTH_TEMP/before.json"
jq -e '.data.builtin==false' "$HTH_TEMP/before.json" >/dev/null || hth_unknown 'built-in agents are not supported'
# Never broaden a restricted list. Null is documented as unrestricted.
jq -e --slurpfile desired "$HTH_TEMP/desired.json" '.data.repositories==null or (($desired[0] - .data.repositories)|length)==0' "$HTH_TEMP/before.json" >/dev/null || hth_unknown 'requested list would broaden current repository scope'
if [[ "${HTH_APPLY:-0}" == 0 ]]; then
  printf 'PREVIEW: would set the nonempty approved repository list on the exact agent; no write.\n'; exit 0
fi
hth_snapshot_dir
cp "$HTH_TEMP/before.json" "$HTH_EVIDENCE/before.json"
cp "$HTH_TEMP/body.json" "$HTH_EVIDENCE/request.json"
# No conditional-write primitive is documented. Re-read, fail on changes; residual race remains.
hth_request GET "/api/v2/agents/$id" "$HTH_TEMP/recheck.json"
jq -se '.[0].data==.[1].data' "$HTH_TEMP/before.json" "$HTH_TEMP/recheck.json" >/dev/null || hth_unknown 'agent changed concurrently; no write'
hth_request PATCH "/api/v2/agents/$id" "$HTH_TEMP/write.json" "$HTH_TEMP/body.json"
hth_request GET "/api/v2/agents/$id" "$HTH_EVIDENCE/after.json"
hth_agent_valid "$id" "$HTH_EVIDENCE/after.json"
jq -se --slurpfile desired "$HTH_TEMP/desired.json" '((.[1].data.repositories|sort)==($desired[0]|sort)) and ((.[0].data|del(.repositories))==(.[1].data|del(.repositories)))' "$HTH_TEMP/before.json" "$HTH_EVIDENCE/after.json" >/dev/null || hth_unknown 'read-back mismatch or concurrent edit; inspect private evidence, no automatic rollback'
printf 'VERIFIED: stored repository allowlist matches; not proof of runtime enforcement or connector isolation.\n'
# HTH Guide Excerpt: end restrict-agent-repositories
