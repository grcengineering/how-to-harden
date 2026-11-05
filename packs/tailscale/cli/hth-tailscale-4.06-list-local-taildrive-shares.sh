#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tailscale-4.6
#   guide: https://howtoharden.com/guides/tailscale/#46-constrain-taildrop-and-taildrive-file-sharing
#   profile: L2
#   mode: read-only
#   requires: tailscale CLI with Taildrive support, TAILSCALE_OUTPUT, bash, jq, python3
# HTH Tailscale 4.6 — Constrain Taildrop and Taildrive File Sharing; NIST AC-3, AC-4; SOC 2 CC6.6
# Source: https://tailscale.com/docs/reference/tailscale-cli (available; 2026-11-05)
set +x
set -Eeuo pipefail
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# HTH Guide Excerpt: begin list-local-taildrive-shares
hth_init 2
hth_cli drive list
hth_save "$HTH_TEMP/cli"
printf 'COLLECTED: private text listing of local Taildrive shares, not file contents or tailnet-wide permission proof.\n'
# HTH Guide Excerpt: end list-local-taildrive-shares
