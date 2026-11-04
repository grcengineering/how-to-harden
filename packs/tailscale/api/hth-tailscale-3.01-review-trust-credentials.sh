#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tailscale-3.1
#   guide: https://howtoharden.com/guides/tailscale/#31-scope-automation-trust-credentials
#   profile: L1
#   mode: read-only
#   requires: TAILSCALE_ACCESS_TOKEN(oauth_keys:read or federated_keys:read for the reviewed credential types), TAILSCALE_TAILNET, TAILSCALE_KEY_IDS_FILE, TAILSCALE_OUTPUT, bash, curl, jq, python3
# HTH Tailscale 3.1 — Scope Automation Trust Credentials; NIST IA-5, AC-6; SOC 2 CC6.1
# Sources: https://tailscale.com/docs/reference/trust-credentials
# https://github.com/tailscale/tailscale-client-go-v2/blob/main/keys.go (available; 2026-11-04)
# Known-ID review only: this does not discover every OAuth/federated credential.
set +x
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin review-trust-credentials
hth_api_init 1
[[ -f "${TAILSCALE_KEY_IDS_FILE:-}" ]] || hth_unknown 'provide a JSON array of reviewed credential IDs from Trust credentials'
jq -e 'type == "array" and length > 0 and length <= 100 and
  all(.[]; type == "string" and test("^[A-Za-z0-9]{1,128}$")) and
  ((unique | length) == length)' "$TAILSCALE_KEY_IDS_FILE" >/dev/null 2>&1 || hth_unknown 'invalid credential ID list'
jq -r '.[]' "$TAILSCALE_KEY_IDS_FILE" > "$HTH_TEMP/ids"
: > "$HTH_TEMP/records"
while IFS= read -r id; do
  hth_get "/api/v2/tailnet/${HTH_TAILNET}/keys/${id}" "$HTH_TEMP/key.json"
  jq -e --arg id "$id" '.id == $id and (.scopes | type == "array")' "$HTH_TEMP/key.json" >/dev/null 2>&1 || hth_unknown 'credential metadata mismatch or absent scopes'
  # Explicit projection never retains a resolved secret should the API add one.
  jq -c '{id, keyType, description, scopes, tags, created, updated, expires, revoked, userId, audience, issuer, subject}' "$HTH_TEMP/key.json" >> "$HTH_TEMP/records"
done < "$HTH_TEMP/ids"
jq -s '{reviewedCredentials:., coverage:"known IDs only; reconcile with console"}' "$HTH_TEMP/records" > "$HTH_TEMP/report.json"
hth_save "$HTH_TEMP/report.json"
printf 'COLLECTED: known credential metadata; compare scopes, owners, tags and federation claims with approvals.\n'
# HTH Guide Excerpt: end review-trust-credentials
