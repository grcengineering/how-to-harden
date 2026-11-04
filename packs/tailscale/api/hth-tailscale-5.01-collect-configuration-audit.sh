#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tailscale-5.1
#   guide: https://howtoharden.com/guides/tailscale/#51-retain-and-review-configuration-audit-logs
#   profile: L1
#   mode: read-only
#   requires: TAILSCALE_ACCESS_TOKEN(logs:configuration:read), TAILSCALE_TAILNET, TAILSCALE_LOG_START, TAILSCALE_LOG_END, TAILSCALE_OUTPUT, bash, curl, jq, python3
# HTH Tailscale 5.1 — Retain and Review Configuration Audit Logs; NIST AU-2, AU-6, AU-9; SOC 2 CC7.2
# Source: https://tailscale.com/docs/features/logging/audit-logging (available; 2026-11-04)
set +x
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin collect-configuration-audit
hth_api_init 1
hth_window
hth_get "/api/v2/tailnet/${HTH_TAILNET}/logging/configuration?${HTH_WINDOW}" "$HTH_TEMP/logs.json"
jq -e '(.logs | type == "array") and (.version | type == "string") and
  all(.logs[]; (.eventTime | type == "string") and (.action | type == "string") and
    (.actor | type == "object") and (.target | type == "object"))' "$HTH_TEMP/logs.json" >/dev/null 2>&1 || hth_unknown 'invalid audit-log envelope or event'
# The vendor documents no pagination: all events in the time window are returned.
# A 20 MiB transport cap fails closed; shorten the window if it is exceeded.
hth_save "$HTH_TEMP/logs.json"
printf 'COLLECTED: %s configuration events for the requested window; account for delivery delay.\n' "$(jq '.logs | length' "$HTH_TEMP/logs.json")"
# HTH Guide Excerpt: end collect-configuration-audit
