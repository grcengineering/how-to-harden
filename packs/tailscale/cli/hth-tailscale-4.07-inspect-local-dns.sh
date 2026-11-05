#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tailscale-4.7
#   guide: https://howtoharden.com/guides/tailscale/#47-govern-dns-resolvers-and-certificate-name-disclosure
#   profile: L2
#   mode: read-only
#   requires: tailscale CLI 1.74+, TAILSCALE_OUTPUT, bash, jq, python3
# HTH Tailscale 4.7 — Govern DNS Resolvers and Certificate Name Disclosure; NIST SC-20, SC-21; SOC 2 CC6.6
# Source: https://tailscale.com/docs/reference/tailscale-cli (available; 2026-11-05)
set +x
set -Eeuo pipefail
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# HTH Guide Excerpt: begin inspect-local-dns
hth_init 2
hth_cli dns status --json
jq -e 'type == "object"' "$HTH_TEMP/cli" >/dev/null 2>&1 || hth_unknown 'invalid local DNS status response'
hth_save "$HTH_TEMP/cli"
printf 'COLLECTED: local DNS configuration; verify real name resolution and certificate disclosure separately.\n'
# HTH Guide Excerpt: end inspect-local-dns
