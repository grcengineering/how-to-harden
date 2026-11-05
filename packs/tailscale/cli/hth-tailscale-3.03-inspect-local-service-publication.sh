#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tailscale-3.3
#   guide: https://howtoharden.com/guides/tailscale/#33-review-subnet-and-exit-node-routes
#   profile: L2
#   mode: read-only
#   requires: tailscale CLI, TAILSCALE_OUTPUT, bash, jq, python3
# HTH Tailscale 3.3 — Review Subnet and Exit-Node Routes; NIST SC-7, AC-4; SOC 2 CC6.6
# Source: https://tailscale.com/docs/features/tailscale-services (available; 2026-11-05)
set +x
set -Eeuo pipefail
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# HTH Guide Excerpt: begin inspect-local-service-publication
hth_init 2
hth_cli serve status --json
jq -e 'type == "object"' "$HTH_TEMP/cli" >/dev/null 2>&1 || hth_unknown 'invalid Serve configuration response'
hth_save "$HTH_TEMP/cli"
printf 'COLLECTED: local Serve/Service-host configuration only; reconcile central approvals, grants and other hosts separately.\n'
# HTH Guide Excerpt: end inspect-local-service-publication
