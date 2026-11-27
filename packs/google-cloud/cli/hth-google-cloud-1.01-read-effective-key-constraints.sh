#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: google-cloud-1.1
#   guide: https://howtoharden.com/guides/google-cloud/#11-assess-effective-long-lived-key-guardrails
#   profile: L1
#   mode: read-only
#   requires: Google Cloud CLI, jq, approved project/org-policy read access
# Source (reviewed 2026-11-27): https://docs.cloud.google.com/organization-policy/create-organization-policies
# HTH Guide Excerpt: begin read-effective-key-constraints
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${HTH_GCP_PROJECT:-}" =~ ^[a-z][a-z0-9-]{4,28}[a-z0-9]$ ]] || fail 'Missing or invalid HTH_GCP_PROJECT'
[[ "${HTH_GCP_ORG_ID:-}" =~ ^[0-9]{1,20}$ ]] || fail 'Missing or invalid HTH_GCP_ORG_ID'

command -v gcloud >/dev/null || fail 'Google Cloud CLI is not installed'
ancestors=$(gcloud projects get-ancestors "$HTH_GCP_PROJECT" --quiet --format=json) ||
  fail 'Unable to read project hierarchy'
jq -e --arg id "$HTH_GCP_ORG_ID" '
  type=="array" and any(.[];.type=="organization" and (.id|tostring)==$id)
' <<<"$ancestors" >/dev/null 2>&1 || fail 'Expected organization is not the project ancestor'
# Use v2 org-policies, not the legacy resource-manager command.
policies=()
for constraint in iam.managed.disableServiceAccountKeyCreation iam.managed.disableServiceAccountKeyUpload; do
  policy=$(gcloud org-policies describe "$constraint" --project "$HTH_GCP_PROJECT" --effective --quiet --format=json) ||
    fail "Unable to read $constraint"
  summary=$(jq -ce --arg constraint "$constraint" '
    if (.spec.rules|type=="array" and length>0) and
      all(.spec.rules[];(.enforce|type=="boolean")) then
      {constraint:$constraint,rules:[.spec.rules[]|
        {enforce,condition_present:(.condition!=null)}]}
    else error("Unexpected policy rule data") end
  ' <<<"$policy" 2>/dev/null) || fail "Unknown enforcement: $constraint"
  policies+=("$summary")
done
printf '%s\n' "${policies[@]}" | jq -s '{organization_ancestor_verified:true,
  effective_project_rules:.,existing_keys_checked:false}'
# HTH Guide Excerpt: end read-effective-key-constraints
