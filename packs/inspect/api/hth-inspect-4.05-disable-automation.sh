#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: inspect-4.5
#   guide: https://howtoharden.com/guides/inspect/#45-disable-unneeded-scheduled-and-event-automations
#   profile: L1
#   mode: mutating (preview default; explicit HTH_APPLY=1 and matching HTH_CONFIRM_ID)
#   requires: bash, curl, jq, python3, INSPECT_API_KEY with target access
# HTH 4.5: Disable Unneeded Scheduled and Event Automations
# Profile: L1 | NIST SP 800-53 AC-6 | https://howtoharden.com/guides/inspect/
# Sources: https://docs.inspect.com/api/openapi.json (2026-11-17; available v2 routes).
# No live tenant validation. Download common.sh beside this file.
# HTH Guide Excerpt: begin disable-automation
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"
hth_init
id=${INSPECT_AUTOMATION_ID:-}; hth_id "$id"; hth_apply_gate "$id"
hth_request GET "/api/v2/automations/$id" "$HTH_TEMP/before.json"
hth_automation_valid "$id" "$HTH_TEMP/before.json"
jq -e '.data.viewer_can_edit==true and (.data.triggers|length)>0' "$HTH_TEMP/before.json" >/dev/null || hth_unknown 'requires editable scheduled/event automation; manual-only has no disable state'
printf '%s\n' '{"enabled":false}' > "$HTH_TEMP/body.json"
if [[ "${HTH_APPLY:-0}" == 0 ]]; then
  printf 'PREVIEW: would disable automatic triggers on this exact automation; no write.\n'; exit 0
fi
hth_snapshot_dir
cp "$HTH_TEMP/before.json" "$HTH_EVIDENCE/before.json"
cp "$HTH_TEMP/body.json" "$HTH_EVIDENCE/request.json"
hth_request GET "/api/v2/automations/$id" "$HTH_TEMP/recheck.json"
jq -se '.[0].data==.[1].data' "$HTH_TEMP/before.json" "$HTH_TEMP/recheck.json" >/dev/null || hth_unknown 'automation changed concurrently; no write'
hth_request PATCH "/api/v2/automations/$id" "$HTH_TEMP/write.json" "$HTH_TEMP/body.json"
hth_request GET "/api/v2/automations/$id" "$HTH_EVIDENCE/after.json"
hth_automation_valid "$id" "$HTH_EVIDENCE/after.json"
jq -se '.[1].data.enabled==false and ((.[0].data|del(.enabled,.updated_at,.next_run_at,.last_run_at))==(.[1].data|del(.enabled,.updated_at,.next_run_at,.last_run_at)))' "$HTH_TEMP/before.json" "$HTH_EVIDENCE/after.json" >/dev/null || hth_unknown 'read-back mismatch or concurrent edit; inspect private evidence'
printf 'VERIFIED: automatic triggers disabled. Manual runs and already-running sessions are NOT stopped.\n'
# HTH Guide Excerpt: end disable-automation
