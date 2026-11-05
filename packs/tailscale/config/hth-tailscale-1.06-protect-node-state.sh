#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tailscale-1.6
#   guide: https://howtoharden.com/guides/tailscale/#16-protect-stored-node-identity
#   profile: L2
#   mode: read-only
#   requires: TAILSCALE_PLATFORM, TAILSCALE_CLIENT_VERSION, TAILSCALE_OUTPUT, bash, jq, python3
# HTH Tailscale 1.6 — Protect Stored Node Identity; NIST IA-5, SC-28; SOC 2 CC6.1
# Sources: https://tailscale.com/docs/features/secure-node-state-storage
# https://tailscale.com/docs/features/tailscale-system-policies (available; 2026-11-05)
# Windows and standalone macOS: 1.86+. Linux JSON policy: 1.102+.
# Older supported Linux clients use the documented tailscaled --encrypt-state flag.
# Linux/Windows deployment requires a working TPM 2.0 and independent recovery.
set +x
set -Eeuo pipefail
# shellcheck source=system-policy.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/system-policy.sh"

# HTH Guide Excerpt: begin prepare-state-protection
hth_policy_init 2 86 102
printf '%s\n' '{"EncryptState":true}' > "$HTH_TEMP/settings"
hth_policy_emit "$HTH_TEMP/settings"
# HTH Guide Excerpt: end prepare-state-protection
