#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tailscale-4.2
#   guide: https://howtoharden.com/guides/tailscale/#42-prevent-unapproved-public-funnel-exposure
#   profile: L1
#   mode: read-only
#   requires: supported authenticated tailscale CLI, TAILSCALE_OUTPUT, bash, jq, python3
# HTH Tailscale 4.2 — Prevent Unapproved Public Funnel Exposure; NIST SC-7, CM-7; SOC 2 CC6.6
# Source: https://tailscale.com/docs/reference/tailscale-cli/funnel (available; 2026-11-04)
set +x
set -Eeuo pipefail
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# HTH Guide Excerpt: begin inspect-funnel
hth_init 1
hth_cli funnel status --json
jq -e 'type == "object"' "$HTH_TEMP/cli" >/dev/null 2>&1 || hth_unknown 'invalid Funnel status response'
hth_save "$HTH_TEMP/cli"
printf 'COLLECTED: local Funnel status; inspect every managed node and review funnel nodeAttrs in the full policy.\n'
# HTH Guide Excerpt: end inspect-funnel
