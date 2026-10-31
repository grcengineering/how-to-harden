#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: factory-1.3
#   guide: https://howtoharden.com/guides/factory/#13-restrict-api-key-administration-and-use-workload-identities
#   profile: L1
#   mode: read-only
#   requires: FACTORY_API_KEY(human Manager or Owner credential; service-account keys rejected), FACTORY_KEYS_OUTPUT(new private file), bash, curl, jq, python3
# HTH Factory 1.3 — NIST AC-6, IA-5
# Source: https://docs.factory.com/api-reference/service-accounts (available; verified 2026-10-30)
# Reads metadata only. Does not mint, rotate, revoke, or delete credentials.
set +x
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin audit-workload-keys
hth_api_init 1
[[ -n "${FACTORY_KEYS_OUTPUT:-}" ]] || hth_unknown 'set FACTORY_KEYS_OUTPUT to a new private file'
hth_get '/api/v0/service-accounts' "$HTH_TEMP/accounts.json"
jq -e '(.serviceAccounts | type == "array") and all(.serviceAccounts[];
  (.id | type == "string" and length > 0) and (.name | type == "string") and
  (.status == "active" or .status == "inactive" or .status == "deleted")) and
  (([.serviceAccounts[].id] | unique | length) == (.serviceAccounts | length)) and
  (.serviceAccounts | length <= 1000)' "$HTH_TEMP/accounts.json" >/dev/null || hth_unknown 'invalid service account inventory'
: > "$HTH_TEMP/keys.jsonl"
while IFS= read -r account_id; do
  hth_get "/api/v0/service-accounts/$(jq -rn --arg id "$account_id" '$id | @uri')/api-keys" "$HTH_TEMP/keys.json"
  jq -e '(.apiKeys | type == "array") and all(.apiKeys[];
    (.id | type == "string" and length > 0) and (.isRevoked | type == "boolean") and
    (.createdAt | type == "number") and (.expiresAt == null or (.expiresAt | type == "number")))' \
    "$HTH_TEMP/keys.json" >/dev/null || hth_unknown 'invalid API key metadata'
  # Select documented metadata; discard unexpected fields such as one-time values.
  jq -c --arg id "$account_id" '{serviceAccountId: $id, keys: [.apiKeys[] |
    {id, name, createdAt, expiresAt, isRevoked, revokedAt}]}' "$HTH_TEMP/keys.json" >> "$HTH_TEMP/keys.jsonl"
done < <(jq -r '.serviceAccounts[] | select(.status != "deleted") | .id' "$HTH_TEMP/accounts.json")
jq -n --slurpfile accounts "$HTH_TEMP/accounts.json" --slurpfile keys "$HTH_TEMP/keys.jsonl" \
  '{serviceAccounts: $accounts[0].serviceAccounts, keyMetadata: $keys}' > "$HTH_TEMP/inventory.json"
hth_save_private "$HTH_TEMP/inventory.json" "$FACTORY_KEYS_OUTPUT"
printf 'COLLECTED: workload identities and key metadata; review ownership, activity and expiry. No policy compliance inferred.\n'
# HTH Guide Excerpt: end audit-workload-keys
