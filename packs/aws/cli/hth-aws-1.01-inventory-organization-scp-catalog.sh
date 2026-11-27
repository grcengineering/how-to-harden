#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: aws-1.1
#   guide: https://howtoharden.com/guides/aws/#11-verify-organization-scope-and-scp-guardrails
#   profile: L1
#   mode: read-only
#   requires: AWS CLI v2, jq, approved AWS Organizations read-only profile
# Source (reviewed 2026-11-27): https://docs.aws.amazon.com/cli/latest/reference/organizations/list-policies.html
# HTH Guide Excerpt: begin inventory-organization-scp-catalog
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${HTH_AWS_PROFILE:-}" =~ ^[[:alnum:]_.-]+$ ]] || fail 'Missing or invalid HTH_AWS_PROFILE'
[[ "${HTH_AWS_ORG_ID:-}" =~ ^o-[a-z0-9]{10,32}$ ]] || fail 'Missing or invalid HTH_AWS_ORG_ID'

export AWS_IGNORE_CONFIGURED_ENDPOINT_URLS=true
command -v aws >/dev/null || fail 'AWS CLI is not installed'
cli=(aws --profile "$HTH_AWS_PROFILE" --region us-east-1 --output json --no-cli-pager)
org=$("${cli[@]}" organizations describe-organization) || fail 'Unable to read organization'
jq -e --arg id "$HTH_AWS_ORG_ID" '
  .Organization.Id==$id and .Organization.FeatureSet=="ALL"
' <<<"$org" >/dev/null 2>&1 || fail 'Organization ID mismatch or all-features mode unavailable'
catalog=$("${cli[@]}" organizations list-policies --filter SERVICE_CONTROL_POLICY --max-items 100) ||
  fail 'Unable to read service control policy catalog'
jq -e '(.Policies|type=="array") and all(.Policies[];(.Id|type=="string")) and
  (.NextToken==null or (.NextToken|type=="string"))' <<<"$catalog" >/dev/null 2>&1 ||
  fail 'Unexpected service control policy collection'
jq '{organization_match:true,all_features:true,returned_policy_ids:[.Policies[].Id],
  additional_items:((.NextToken // "")!=""),attachments_checked:false}' <<<"$catalog"
# HTH Guide Excerpt: end inventory-organization-scp-catalog
