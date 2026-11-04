#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tailscale-1.4
#   guide: https://howtoharden.com/guides/tailscale/#14-review-node-key-expiry-and-exceptions
#   profile: L1
#   mode: read-only
#   requires: TAILSCALE_ACCESS_TOKEN(devices:core:read), TAILSCALE_TAILNET, TAILSCALE_OUTPUT, bash, curl, jq, python3
# HTH Tailscale 1.4 — Review Node Key Expiry and Exceptions; NIST IA-5, IA-3; SOC 2 CC6.2
# Source: https://github.com/tailscale/tailscale-client-go-v2/blob/main/devices.go (available; 2026-11-04)
set +x
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin inventory-device-keys
hth_api_init 1
hth_get "/api/v2/tailnet/${HTH_TAILNET}/devices?fields=all" "$HTH_TEMP/devices.json"
jq -e '(.devices | type == "array") and all(.devices[];
  (.id | type == "string" and length > 0) and
  (.keyExpiryDisabled | type == "boolean") and (.expires | type == "string") and
  (.authorized | type == "boolean")) and
  (([.devices[].id] | unique | length) == (.devices | length))' "$HTH_TEMP/devices.json" >/dev/null 2>&1 || hth_unknown 'invalid or duplicate device inventory'
hth_save "$HTH_TEMP/devices.json"
printf 'COLLECTED: %s devices; compare disabled expiry and tagged workloads with approved exceptions.\n' "$(jq '.devices | length' "$HTH_TEMP/devices.json")"
# HTH Guide Excerpt: end inventory-device-keys
