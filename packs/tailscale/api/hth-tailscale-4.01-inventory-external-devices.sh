#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tailscale-4.1
#   guide: https://howtoharden.com/guides/tailscale/#41-govern-external-sharing-and-tailnet-membership
#   profile: L2
#   mode: read-only
#   requires: TAILSCALE_ACCESS_TOKEN(devices:core:read), TAILSCALE_TAILNET, TAILSCALE_OUTPUT, bash, curl, jq, python3
# HTH Tailscale 4.1 — Govern External Sharing and Tailnet Membership; NIST AC-20, AC-4; SOC 2 CC6.6
# Source: https://github.com/tailscale/tailscale-client-go-v2/blob/main/devices.go (available; 2026-11-04)
# Inbound external-node inventory cannot enumerate outbound share recipients.
set +x
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin inventory-external-devices
hth_api_init 2
hth_get "/api/v2/tailnet/${HTH_TAILNET}/devices?fields=all" "$HTH_TEMP/devices.json"
jq -e '(.devices | type == "array") and all(.devices[];
  (.id | type == "string" and length > 0) and (.isExternal | type == "boolean")) and
  (([.devices[].id] | unique | length) == (.devices | length))' "$HTH_TEMP/devices.json" >/dev/null 2>&1 || hth_unknown 'external-device state missing or invalid'
jq '{externalDevices:[.devices[] | select(.isExternal)],
  coverage:"inbound external nodes only; review outbound recipients and invites in console"}' "$HTH_TEMP/devices.json" > "$HTH_TEMP/report.json"
hth_save "$HTH_TEMP/report.json"
printf 'COLLECTED: inbound external devices; this does not prove that outbound sharing is disabled.\n'
# HTH Guide Excerpt: end inventory-external-devices
