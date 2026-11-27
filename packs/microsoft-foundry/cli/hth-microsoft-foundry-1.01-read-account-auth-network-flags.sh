#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: microsoft-foundry-1.1
#   guide: https://howtoharden.com/guides/microsoft-foundry/#11-disable-local-keys-after-migrating-clients
#   profile: L1
#   mode: read-only
#   requires: Azure CLI, jq, approved commercial Foundry account Reader access
# Source (reviewed 2026-11-27): https://learn.microsoft.com/en-us/azure/foundry/concepts/encryption-keys-portal
# HTH Guide Excerpt: begin read-account-auth-network-flags
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${HTH_FOUNDRY_TENANT:-}" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ]] || fail 'Missing or invalid HTH_FOUNDRY_TENANT'
[[ "${HTH_FOUNDRY_SUBSCRIPTION:-}" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ]] || fail 'Missing or invalid HTH_FOUNDRY_SUBSCRIPTION'
[[ "${HTH_FOUNDRY_RESOURCE_GROUP:-}" =~ ^[a-zA-Z0-9_][a-zA-Z0-9_.()-]{0,89}$ ]] || fail 'Missing or invalid HTH_FOUNDRY_RESOURCE_GROUP'
[[ "${HTH_FOUNDRY_ACCOUNT:-}" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$ ]] || fail 'Missing or invalid HTH_FOUNDRY_ACCOUNT'

command -v az >/dev/null || fail 'Azure CLI is not installed'
context=$(az account show --subscription "$HTH_FOUNDRY_SUBSCRIPTION" --output json --only-show-errors) ||
  fail 'Unable to read Azure context'
jq -e --arg tenant "$HTH_FOUNDRY_TENANT" --arg sub "$HTH_FOUNDRY_SUBSCRIPTION" '
  (.tenantId|ascii_downcase)==($tenant|ascii_downcase) and
  (.id|ascii_downcase)==($sub|ascii_downcase) and .environmentName=="AzureCloud"
' <<<"$context" >/dev/null 2>&1 || fail 'Unexpected commercial Azure tenant/subscription'
account=$(az cognitiveservices account show --subscription "$HTH_FOUNDRY_SUBSCRIPTION" \
  --resource-group "$HTH_FOUNDRY_RESOURCE_GROUP" --name "$HTH_FOUNDRY_ACCOUNT" \
  --output json --only-show-errors) || fail 'Unable to read Foundry account'
expected="/subscriptions/$HTH_FOUNDRY_SUBSCRIPTION/resourceGroups/$HTH_FOUNDRY_RESOURCE_GROUP/providers/Microsoft.CognitiveServices/accounts/$HTH_FOUNDRY_ACCOUNT"
jq -e --arg expected "$expected" '
  (.id|ascii_downcase)==($expected|ascii_downcase) and .kind=="AIServices" and
  (.properties.disableLocalAuth|type=="boolean") and
  (.properties.publicNetworkAccess|type=="string")
' <<<"$account" >/dev/null 2>&1 || fail 'Wrong account kind, ID mismatch or unreported security flags'
jq '{account_id:.id,local_auth_disabled:.properties.disableLocalAuth,
  public_network_access:.properties.publicNetworkAccess,data_plane_checked:false,
  private_network_egress_checked:false}' <<<"$account"
# HTH Guide Excerpt: end read-account-auth-network-flags
