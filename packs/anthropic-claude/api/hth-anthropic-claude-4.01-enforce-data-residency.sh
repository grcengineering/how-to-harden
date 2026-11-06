#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: anthropic-api-3.1
#   guide: https://howtoharden.com/guides/anthropic-api/#31-enforce-data-residency-restrictions
#   profile: L2
#   mode: mutating
# Read-only default; exact workspace write requires HTH_APPLY=1.
#   requires: ANTHROPIC_ADMIN_KEY, optional WORKSPACE_ID and HTH_APPLY
# Source: https://platform.claude.com/docs/en/manage-claude/data-residency
set -euo pipefail
source "$(dirname "$0")/common.sh"
# HTH Guide Excerpt: begin api-audit-data-residency
evidence=$(anthropic_evidence_dir)
trap 'rm -f "${evidence}/workspaces.pending"' EXIT
anthropic_list_all "/v1/organizations/workspaces?include_default=true" > "${evidence}/workspaces.pending"
jq -e 'all(.[]; .type=="workspace" and (.id|type)=="string" and (.data_residency|type)=="object")' "${evidence}/workspaces.pending" >/dev/null
mv "${evidence}/workspaces.pending" "${evidence}/workspaces.json"
printf 'Private workspace residency inventory: %s. Storage geo alone does not prove constrained inference.\n' "${evidence}/workspaces.json"
# HTH Guide Excerpt: end api-audit-data-residency

# HTH Guide Excerpt: begin api-restrict-inference-geo
# Example optional US-only update. workspace_geo is immutable and is NOT changed.
# Review the target/region and set BOTH WORKSPACE_ID and HTH_APPLY=1 deliberately.
if [[ -n "${WORKSPACE_ID:-}" ]]; then
  [[ "${WORKSPACE_ID}" =~ ^wrkspc_[A-Za-z0-9]+$ ]] || exit 2
  [[ "${HTH_APPLY:-0}" == 1 ]] || { echo 'Update refused without HTH_APPLY=1.' >&2; exit 2; }
  jq -e --arg id "${WORKSPACE_ID}" 'any(.[]; .id==$id)' "${evidence}/workspaces.json" >/dev/null || exit 2
  anthropic_post "/v1/organizations/workspaces/${WORKSPACE_ID}" '{"data_residency":{"default_inference_geo":"us","allowed_inference_geos":["us"]}}' > "${evidence}/update-response.json"
  anthropic_get "/v1/organizations/workspaces/${WORKSPACE_ID}" > "${evidence}/updated-workspace.json"
  jq -e --arg id "${WORKSPACE_ID}" '.id==$id and .data_residency.default_inference_geo=="us" and .data_residency.allowed_inference_geos==["us"]' "${evidence}/updated-workspace.json" >/dev/null || { echo 'Update readback differs; review private evidence.' >&2; exit 1; }
  echo 'Selected workspace readback restricts inference to us; storage/model/provider eligibility still requires review.'
fi
# HTH Guide Excerpt: end api-restrict-inference-geo
# No empty-inventory pass. Audit-only output requires an explicit organization baseline.
jq -e 'length > 0' "${evidence}/workspaces.json" >/dev/null || exit 2
if [[ -z "${WORKSPACE_ID:-}" ]]; then
  echo 'Inventory only: compare all storage/default/allowed inference geos with your approved baseline; no residency pass asserted.'
fi
