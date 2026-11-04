#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tailscale-3.3
#   guide: https://howtoharden.com/guides/tailscale/#33-review-subnet-and-exit-node-routes
#   profile: L2
#   mode: read-only
#   requires: TAILSCALE_ACCESS_TOKEN(devices:core:read and devices:routes:read), TAILSCALE_TAILNET, TAILSCALE_OUTPUT, bash, curl, jq, python3
# HTH Tailscale 3.3 — Review Subnet and Exit-Node Routes; NIST SC-7, AC-4; SOC 2 CC6.6
# Source: https://github.com/tailscale/tailscale-client-go-v2/blob/main/devices.go (available; 2026-11-04)
set +x
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin inventory-route-approvals
hth_api_init 2
hth_get "/api/v2/tailnet/${HTH_TAILNET}/devices?fields=all" "$HTH_TEMP/devices.json"
jq -e '(.devices | type == "array") and (.devices | length <= 1000) and
  all(.devices[]; ((.nodeId // .id) | type == "string" and test("^[A-Za-z0-9]{1,128}$"))) and
  (([.devices[] | .nodeId // .id] | unique | length) == (.devices | length))' "$HTH_TEMP/devices.json" >/dev/null 2>&1 || hth_unknown 'invalid, duplicate or excessive device inventory'
jq -r '.devices[] | .nodeId // .id' "$HTH_TEMP/devices.json" > "$HTH_TEMP/ids"
: > "$HTH_TEMP/records"
while IFS= read -r id; do
  hth_get "/api/v2/device/${id}/routes" "$HTH_TEMP/routes.json"
  jq -e '(.advertisedRoutes | type == "array") and (.enabledRoutes | type == "array") and
    all(.advertisedRoutes[], .enabledRoutes[]; type == "string")' "$HTH_TEMP/routes.json" >/dev/null 2>&1 || hth_unknown 'invalid route response'
  jq -c --arg id "$id" '{deviceId:$id, advertisedRoutes, enabledRoutes}' "$HTH_TEMP/routes.json" >> "$HTH_TEMP/records"
done < "$HTH_TEMP/ids"
jq -s '{routes:.}' "$HTH_TEMP/records" > "$HTH_TEMP/report.json"
hth_save "$HTH_TEMP/report.json"
printf 'COLLECTED: advertised and enabled routes for the device snapshot; compare default routes and autoApprovers separately.\n'
# HTH Guide Excerpt: end inventory-route-approvals
