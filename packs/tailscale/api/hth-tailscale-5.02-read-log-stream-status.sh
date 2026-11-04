#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tailscale-5.2
#   guide: https://howtoharden.com/guides/tailscale/#52-export-flow-logs-and-verify-delivery
#   profile: L2
#   mode: read-only
#   requires: TAILSCALE_ACCESS_TOKEN(log_streaming:read), TAILSCALE_TAILNET, TAILSCALE_OUTPUT, bash, curl, jq, python3
# HTH Tailscale 5.2 — Export Flow Logs and Verify Delivery; NIST AU-12, AU-6; SOC 2 CC7.2
# Source: https://tailscale.com/docs/reference/trust-credentials (available; 2026-11-04)
set +x
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin log-stream-status
hth_api_init 2
for kind in configuration network; do
  hth_get "/api/v2/tailnet/${HTH_TAILNET}/logging/${kind}/status" "$HTH_TEMP/${kind}.json"
done
jq -n --slurpfile configuration "$HTH_TEMP/configuration.json" --slurpfile network "$HTH_TEMP/network.json" \
  '{configuration:$configuration[0], network:$network[0]}' > "$HTH_TEMP/report.json"
hth_save "$HTH_TEMP/report.json"
printf 'COLLECTED: stream status responses; verify fresh events at the actual destination before claiming delivery.\n'
# HTH Guide Excerpt: end log-stream-status
