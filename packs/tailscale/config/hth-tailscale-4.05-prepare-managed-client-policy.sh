#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tailscale-4.5
#   guide: https://howtoharden.com/guides/tailscale/#45-pin-managed-client-identity-and-connection-policy
#   profile: L2
#   mode: read-only
#   requires: TAILSCALE_PLATFORM, TAILSCALE_CLIENT_VERSION, TAILSCALE_ALLOWED_TAILNET_ID, TAILSCALE_OUTPUT, bash, jq, python3
# HTH Tailscale 4.5 — Pin Managed Client Identity and Connection Policy; NIST CM-6, AC-3; SOC 2 CC6.1
# Source: https://tailscale.com/docs/features/tailscale-system-policies (available; 2026-11-05)
# 1.86+ Windows/standalone macOS; 1.102+ Linux. No AuthKey/LoginURL is emitted.
set +x
set -Eeuo pipefail
# shellcheck source=system-policy.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/system-policy.sh"

# HTH Guide Excerpt: begin prepare-managed-client-policy
# On Apple platforms these AlwaysOn policies cannot coexist with an independently
# managed VPN profile. Review deployment/recovery before merging the candidate:
# https://tailscale.com/docs/features/client/ios-vpn-on-demand
hth_policy_init 2 86 102
[[ "${TAILSCALE_ALLOWED_TAILNET_ID:-}" =~ ^[To][A-Za-z0-9]{5,63}$ ]] ||
  hth_unknown 'set one reviewed tailnet/organization unique ID, not a domain or credential'
jq -n --arg tailnet "required:${TAILSCALE_ALLOWED_TAILNET_ID}" \
  '{Tailnet:$tailnet,PostureChecking:"always"}' > "$HTH_TEMP/settings"
if [[ "$TAILSCALE_PLATFORM" != linux ]]; then
  jq '. + {"AlwaysOn.Enabled":true,"AlwaysOn.OverrideWithReason":true,ReconnectAfter:"5m"}' \
    "$HTH_TEMP/settings" > "$HTH_TEMP/desktop"
  mv "$HTH_TEMP/desktop" "$HTH_TEMP/settings"
fi
hth_policy_emit "$HTH_TEMP/settings"
# HTH Guide Excerpt: end prepare-managed-client-policy
