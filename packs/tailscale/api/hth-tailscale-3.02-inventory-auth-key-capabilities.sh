#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tailscale-3.2
#   guide: https://howtoharden.com/guides/tailscale/#32-limit-ci-and-third-party-workload-enrollment
#   profile: L1
#   mode: read-only
#   requires: TAILSCALE_ACCESS_TOKEN(auth_keys:read), TAILSCALE_TAILNET, TAILSCALE_OUTPUT, bash, curl, jq, python3
# HTH Tailscale 3.2 — Limit CI and Third-Party Workload Enrollment; NIST AC-6, AC-4; SOC 2 CC6.1
# Source: https://github.com/tailscale/tailscale-client-go-v2/blob/main/keys.go (available; 2026-11-04)
# The documented list is credential-relative; an empty list is not tailnet-wide assurance.
set +x
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin inventory-auth-keys
hth_api_init 1
hth_get "/api/v2/tailnet/${HTH_TAILNET}/keys" "$HTH_TEMP/keys.json"
jq -e '(.keys | type == "array") and (.keys | length <= 1000) and
  all(.keys[]; (.id | type == "string" and test("^[A-Za-z0-9]{1,128}$"))) and
  (([.keys[].id] | unique | length) == (.keys | length))' "$HTH_TEMP/keys.json" >/dev/null 2>&1 || hth_unknown 'invalid, duplicate or excessive key list'
jq -r '.keys[].id' "$HTH_TEMP/keys.json" > "$HTH_TEMP/ids"
: > "$HTH_TEMP/records"
while IFS= read -r id; do
  hth_get "/api/v2/tailnet/${HTH_TAILNET}/keys/${id}" "$HTH_TEMP/key.json"
  jq -e --arg id "$id" '.id == $id and (.capabilities.devices.create | type == "object")' "$HTH_TEMP/key.json" >/dev/null 2>&1 || hth_unknown 'auth-key metadata mismatch'
  jq -c '{id, description, created, expires, revoked, capabilities}' "$HTH_TEMP/key.json" >> "$HTH_TEMP/records"
done < "$HTH_TEMP/ids"
jq -s '{keys:., coverage:"credential-visible auth keys only"}' "$HTH_TEMP/records" > "$HTH_TEMP/report.json"
hth_save "$HTH_TEMP/report.json"
printf 'COLLECTED: visible auth-key capabilities; reconcile other owners and tailnet credentials in the console.\n'
# HTH Guide Excerpt: end inventory-auth-keys
