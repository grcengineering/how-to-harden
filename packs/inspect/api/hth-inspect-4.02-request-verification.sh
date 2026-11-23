#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: inspect-4.2
#   guide: https://howtoharden.com/guides/inspect/#42-review-the-exact-revision-and-verification-gaps
#   profile: L1
#   mode: mutating (starts paid agent work; preview default; explicit apply and matching session ID)
#   requires: bash, curl, jq, python3, INSPECT_API_KEY authorized as session owner or original API creator
# HTH 4.2: Request verification on a reviewed session/PR target.
# Profile: L1 | NIST SP 800-53 SA-11 | https://howtoharden.com/guides/inspect/
# Sources: https://docs.inspect.com/api/sessions/startSessionVerification
# https://docs.inspect.com/api/openapi.json (2026-11-17; available v2).
# Requires .inspect/verification/config.yml in the target repository.
# WARNING: starts work/cost and supersedes older runs; runs even if automatic verification is off.
# No retry. Endpoint uses CURRENT PR head; no atomic expected-SHA precondition is documented.
# No live validation. A 202 receipt is NOT successful testing, approval, or evidence of isolation.
# Download common.sh beside this file.
# HTH Guide Excerpt: begin request-verification
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"
hth_init
id=${INSPECT_SESSION_ID:-}; hth_id "$id"; hth_apply_gate "$id"
repo=${INSPECT_REPOSITORY_ID:-}; hth_id "$repo"
pr=${INSPECT_PULL_REQUEST_NUMBER:-}; [[ "$pr" =~ ^[1-9][0-9]*$ ]] || hth_unknown 'supply exact INSPECT_PULL_REQUEST_NUMBER'
sha=${INSPECT_EXPECTED_HEAD_SHA:-}; [[ "$sha" =~ ^[a-fA-F0-9]{40}$ ]] || hth_unknown 'supply the reviewed 40-character INSPECT_EXPECTED_HEAD_SHA'
check_target() {
  jq -e --arg id "$id" --arg repo "$repo" --argjson pr "$pr" --arg sha "$sha" '
    .data | .id==$id and .read_only==false and has("deleted_at") and .deleted_at==null
    and (.pull_requests|type)=="array" and (.repositories|type)=="array"
    and ([.pull_requests[]|select(.repository==$repo)]|length)==1
    and any(.pull_requests[]; .repository==$repo and .pull_request_number==$pr and has("merged_at") and .merged_at==null)
    and ([.repositories[]|select(.id==$repo)]|length)==1
    and any(.repositories[]; .id==$repo and .latest_commit_sha==$sha)' "$1" >/dev/null || hth_unknown 'session/PR/head mismatch or archived/read-only/merged target; no verified target'
}
hth_request GET "/api/v2/sessions/$id" "$HTH_TEMP/session.json"
check_target "$HTH_TEMP/session.json"
jq -n --arg repository "$repo" '{repository:$repository}' > "$HTH_TEMP/body.json"
if [[ "${HTH_APPLY:-0}" == 0 ]]; then
  printf 'PREVIEW: would start or rerun verification; this can incur cost and supersede older runs. No invocation.\n'; exit 0
fi
hth_snapshot_dir
# Keep only target identifiers, not session transcripts, URLs, participants, or deployment details.
jq -n --arg session "$id" --arg repository "$repo" --argjson pr "$pr" --arg head "$sha" '{session,repository,pull_request_number:$pr,expected_head:$head}' > "$HTH_EVIDENCE/target.json"
hth_request GET "/api/v2/sessions/$id" "$HTH_TEMP/recheck.json"
check_target "$HTH_TEMP/recheck.json"
hth_request POST "/api/v2/sessions/$id/verification" "$HTH_EVIDENCE/receipt.json" "$HTH_TEMP/body.json" 202
jq -e --arg repo "$repo" --argjson pr "$pr" '.data | (.status=="started" or .status=="already_running") and .repository==$repo and .pull_request_number==$pr' "$HTH_EVIDENCE/receipt.json" >/dev/null || hth_unknown 'unexpected receipt; invocation may have happened, inspect before retrying'
printf 'ACCEPTED: %s. Review results and tested commit in Inspect; no pass or isolation verdict.\n' "$(jq -r '.data.status' "$HTH_EVIDENCE/receipt.json")"
# HTH Guide Excerpt: end request-verification
