#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tailscale-1.5
#   guide: https://howtoharden.com/guides/tailscale/#15-evaluate-tailnet-lock-with-a-recovery-plan
#   profile: L3
#   mode: read-only
#   requires: supported authenticated tailscale CLI, TAILSCALE_OUTPUT, bash, jq, python3
# HTH Tailscale 1.5 — Evaluate Tailnet Lock with a Recovery Plan; NIST SC-12, SC-23; SOC 2 CC6.1
# Source: https://tailscale.com/docs/features/tailnet-lock (available; 2026-11-04)
set +x
set -Eeuo pipefail
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# HTH Guide Excerpt: begin inspect-tailnet-lock
hth_init 3
hth_cli lock status
hth_save "$HTH_TEMP/cli"
printf 'COLLECTED: local Tailnet Lock status; compare trusted signing keys through an independent channel.\n'
# HTH Guide Excerpt: end inspect-tailnet-lock
