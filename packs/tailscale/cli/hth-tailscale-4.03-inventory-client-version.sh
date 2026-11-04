#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tailscale-4.3
#   guide: https://howtoharden.com/guides/tailscale/#43-maintain-supported-clients-and-security-contacts
#   profile: L1
#   mode: read-only
#   requires: tailscale CLI, TAILSCALE_OUTPUT, bash, jq, python3
# HTH Tailscale 4.3 — Maintain Supported Clients and Security Contacts; NIST SI-2, CM-8; SOC 2 CC7.1
# Source: https://tailscale.com/docs/reference/tailscale-cli (available; 2026-11-04)
set +x
set -Eeuo pipefail
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# HTH Guide Excerpt: begin inventory-client-version
hth_init 1
hth_cli version --json
jq -e 'type == "object"' "$HTH_TEMP/cli" >/dev/null 2>&1 || hth_unknown 'invalid version response'
hth_save "$HTH_TEMP/cli"
printf 'COLLECTED: installed local client version; compare with approved releases and security bulletins.\n'
# HTH Guide Excerpt: end inventory-client-version
