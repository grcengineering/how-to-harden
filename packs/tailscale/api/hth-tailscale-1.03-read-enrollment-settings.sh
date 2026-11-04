#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tailscale-1.3
#   guide: https://howtoharden.com/guides/tailscale/#13-review-new-device-enrollment
#   profile: L1
#   mode: read-only
#   requires: TAILSCALE_ACCESS_TOKEN(feature_settings:read), TAILSCALE_TAILNET, TAILSCALE_OUTPUT, bash, curl, jq, python3
# HTH Tailscale 1.3 — Review New Device Enrollment; NIST IA-3, AC-3; SOC 2 CC6.1
# Source: https://github.com/tailscale/tailscale-client-go-v2/blob/main/tailnet_settings.go (available; 2026-11-04)
set +x
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin enrollment-settings
hth_api_init 1
hth_get "/api/v2/tailnet/${HTH_TAILNET}/settings" "$HTH_TEMP/settings.json"
jq -e '(.devicesApprovalOn | type == "boolean") and
  (.devicesKeyDurationDays | type == "number") and
  (.devicesAutoUpdatesOn | type == "boolean")' "$HTH_TEMP/settings.json" >/dev/null 2>&1 || hth_unknown 'missing or invalid enrollment settings'
hth_save "$HTH_TEMP/settings.json"
printf 'COLLECTED: enrollment defaults; review device approval, expiry and update settings with their exceptions.\n'
# HTH Guide Excerpt: end enrollment-settings
