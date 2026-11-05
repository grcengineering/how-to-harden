#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tailscale-4.5
#   guide: https://howtoharden.com/guides/tailscale/#45-pin-managed-client-identity-and-connection-policy
#   profile: L2
#   mode: read-only
#   requires: tailscale CLI with syspolicy support, TAILSCALE_OUTPUT, bash, jq, python3
# HTH Tailscale 4.5 — Pin Managed Client Identity and Connection Policy; NIST CM-6, AC-3; SOC 2 CC6.1
# Sources: https://tailscale.com/docs/features/tailscale-system-policies
# https://github.com/tailscale/tailscale/blob/main/util/syspolicy/setting/snapshot.go (available; 2026-11-05)
set +x
set -Eeuo pipefail
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# HTH Guide Excerpt: begin review-managed-system-policy
hth_init 2
hth_cli syspolicy list --json
jq -e 'type == "object" and ((.Settings|type) == "object" or length == 0)' "$HTH_TEMP/cli" >/dev/null 2>&1 ||
  hth_unknown 'unrecognized system-policy snapshot'
# AuthKey, raw errors, origins and unknown keys are deliberately not exported.
jq '(.Settings // {}) | with_entries(select(.key == "EncryptState" or .key == "Tailnet" or
  .key == "PostureChecking" or .key == "AllowIncomingConnections" or .key == "AlwaysOn.Enabled" or
  .key == "AlwaysOn.OverrideWithReason" or .key == "ReconnectAfter" or .key == "UseTailscaleDNSSettings" or
  .key == "UseTailscaleSubnets" or .key == "InstallUpdates" or .key == "CheckUpdates" or
  .key == "SUAutomaticallyUpdate")) |
  map_values({value:.Value,hasError:(.Error != null)}) |
  {policies:.,assessment:"CONFIGURATION-ONLY"}' "$HTH_TEMP/cli" > "$HTH_TEMP/evidence"
jq -e '.policies | all(.[]; (.value|type) == "boolean" or (.value|type) == "string" or .value == null)' \
  "$HTH_TEMP/evidence" >/dev/null 2>&1 || hth_unknown 'unrecognized system-policy value'
hth_save "$HTH_TEMP/evidence"
printf 'COLLECTED: selected system-policy values and error flags; not proof that node state is encrypted or all host controls are enforced.\n'
# HTH Guide Excerpt: end review-managed-system-policy
