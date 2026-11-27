#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: microsoft-azure-1.1
#   guide: https://howtoharden.com/guides/microsoft-azure/#11-inventory-inherited-management-group-policies
#   profile: L1
#   mode: read-only
#   requires: Azure CLI, jq, approved commercial tenant and management-group policy read permissions
# Source (reviewed 2026-11-27): https://learn.microsoft.com/en-us/cli/azure/policy/assignment?view=azure-cli-latest
# HTH Guide Excerpt: begin inventory-management-group-assignments
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${HTH_AZURE_SUBSCRIPTION:-}" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ]] || fail 'Missing or invalid HTH_AZURE_SUBSCRIPTION'
[[ "${HTH_AZURE_TENANT:-}" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ]] || fail 'Missing or invalid HTH_AZURE_TENANT'
[[ "${HTH_AZURE_MANAGEMENT_GROUP:-}" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.()-]{0,89}$ ]] || fail 'Missing or invalid HTH_AZURE_MANAGEMENT_GROUP'

command -v az >/dev/null || fail 'Azure CLI is not installed'
context=$(az account show --subscription "$HTH_AZURE_SUBSCRIPTION" --output json --only-show-errors) ||
  fail 'Unable to read Azure context'
jq -e --arg tenant "$HTH_AZURE_TENANT" --arg sub "$HTH_AZURE_SUBSCRIPTION" '
  (.tenantId|ascii_downcase)==($tenant|ascii_downcase) and
  (.id|ascii_downcase)==($sub|ascii_downcase) and .environmentName=="AzureCloud"
' <<<"$context" >/dev/null 2>&1 || fail 'Unexpected commercial Azure tenant/subscription'
assignments=$(az policy assignment list --management-group "$HTH_AZURE_MANAGEMENT_GROUP" \
  --subscription "$HTH_AZURE_SUBSCRIPTION" --filter 'atScope()' \
  --disable-scope-strict-match true --output json --only-show-errors) ||
  fail 'Unable to read management-group assignments'
jq -e 'type=="array" and all(.[];(.id|type=="string") and
  ((.scope // .properties.scope)|type=="string") and
  ((.policyDefinitionId // .properties.policyDefinitionId)|type=="string"))' \
  <<<"$assignments" >/dev/null 2>&1 || fail 'Unexpected policy assignment collection'
jq '{resource_compliance_checked:false,assignments:[.[]|
  {id,scope:(.scope // .properties.scope),
  definition_id:(.policyDefinitionId // .properties.policyDefinitionId),
  enforcement_mode:(.enforcementMode // .properties.enforcementMode)}]}' <<<"$assignments"
# HTH Guide Excerpt: end inventory-management-group-assignments
