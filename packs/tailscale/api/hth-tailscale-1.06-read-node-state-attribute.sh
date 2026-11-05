#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tailscale-1.6
#   guide: https://howtoharden.com/guides/tailscale/#16-protect-stored-node-identity
#   profile: L2
#   mode: read-only
#   requires: TAILSCALE_ACCESS_TOKEN(devices:posture_attributes:read), TAILSCALE_TAILNET, TAILSCALE_DEVICE_ID, TAILSCALE_OUTPUT, bash, curl, jq, python3
# HTH Tailscale 1.6 — Protect Stored Node Identity; NIST IA-5, SC-28; SOC 2 CC6.1
# Sources: https://tailscale.com/docs/features/device-posture/postures-and-attributes
# https://tailscale.com/docs/reference/trust-credentials
# https://github.com/tailscale/tailscale-client-go-v2/blob/v2.12.0/devices.go (available; 2026-11-05)
set +x
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin read-node-state-attribute
hth_api_init 2
[[ "${TAILSCALE_DEVICE_ID:-}" =~ ^[A-Za-z0-9_-]{1,128}$ ]] || hth_unknown 'set one reviewed TAILSCALE_DEVICE_ID'
hth_get "/api/v2/device/${TAILSCALE_DEVICE_ID}/attributes" "$HTH_TEMP/attributes"
jq -e '.attributes | type == "object" and has("node:tsStateEncrypted")' "$HTH_TEMP/attributes" >/dev/null 2>&1 ||
  hth_unknown 'node state attribute not reported; verify platform, client and posture availability'
# Preserve the reported type; do not turn an observation into a policy test.
jq -e '.attributes["node:tsStateEncrypted"] | type == "boolean" or . == "true" or . == "false"' \
  "$HTH_TEMP/attributes" >/dev/null 2>&1 || hth_unknown 'unrecognized state attribute value'
jq '{attribute:"node:tsStateEncrypted",reportedValue:.attributes["node:tsStateEncrypted"],assessment:"REQUIRES-REVIEW"}' \
  "$HTH_TEMP/attributes" > "$HTH_TEMP/evidence"
hth_save "$HTH_TEMP/evidence"
printf 'COLLECTED: one reported node-state attribute; not hardware attestation or live enforcement proof.\n'
# HTH Guide Excerpt: end read-node-state-attribute
