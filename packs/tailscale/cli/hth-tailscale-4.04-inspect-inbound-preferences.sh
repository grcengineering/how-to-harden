#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tailscale-4.4
#   guide: https://howtoharden.com/guides/tailscale/#44-restrict-client-inbound-and-management-exposure
#   profile: L1
#   mode: read-only
#   requires: tailscale CLI with get support, TAILSCALE_OUTPUT, bash, jq, python3
# HTH Tailscale 4.4 — Restrict Client Inbound and Management Exposure; NIST CM-7, SC-7; SOC 2 CC6.6
# Sources: https://tailscale.com/docs/reference/tailscale-cli
# https://github.com/tailscale/tailscale/blob/main/cmd/tailscale/cli/get.go (available; 2026-11-05)
set +x
set -Eeuo pipefail
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# HTH Guide Excerpt: begin inspect-inbound-preferences
hth_init 1
hth_cli get --json shields-up
jq -e '."shields-up" | type == "boolean"' "$HTH_TEMP/cli" >/dev/null 2>&1 || hth_unknown 'missing shields-up preference'
jq '{shieldsUp:."shields-up"}' "$HTH_TEMP/cli" > "$HTH_TEMP/inbound"
hth_cli get --json webclient
jq -e '.webclient | type == "boolean"' "$HTH_TEMP/cli" >/dev/null 2>&1 || hth_unknown 'missing webclient preference'
jq --slurpfile inbound "$HTH_TEMP/inbound" '$inbound[0] + {remoteWebClient:.webclient}' \
  "$HTH_TEMP/cli" > "$HTH_TEMP/evidence"
hth_save "$HTH_TEMP/evidence"
printf 'COLLECTED: active-tailnet preferences only; remoteWebClient=false does not disable the local web interface.\n'
# HTH Guide Excerpt: end inspect-inbound-preferences
