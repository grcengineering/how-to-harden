#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tailscale-2.1
#   guide: https://howtoharden.com/guides/tailscale/#21-replace-broad-allows-with-least-privilege-grants
#   profile: L1
#   mode: read-only
#   requires: TAILSCALE_ACCESS_TOKEN(policy_file:read plus devices:core:read and devices:posture_attributes:read), TAILSCALE_TAILNET, TAILSCALE_OUTPUT, bash, curl, jq, python3
# HTH Tailscale 2.1 — Replace Broad Allows with Least-Privilege Grants; NIST AC-3, AC-4; SOC 2 CC6.1
# Source: https://tailscale.com/docs/reference/trust-credentials (available; 2026-11-04)
set +x
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin snapshot-policy
hth_api_init 1
hth_request GET "/api/v2/tailnet/${HTH_TAILNET}/acl" "$HTH_TEMP/policy.hujson" application/hujson
# Preserve comments, trailing commas, and the version needed for a future
# conditional write. Collection is not a syntax or authorization proof.
etag="$(awk 'tolower($1)=="etag:" {sub(/^[^:]*:[ \t]*/, ""); sub(/\r$/, ""); value=$0} END {print value}' "$HTH_TEMP/headers")"
[[ -n "$etag" && -s "$HTH_TEMP/policy.hujson" ]] || hth_unknown 'missing policy or ETag'
jq -n --arg etag "$etag" --rawfile hujson "$HTH_TEMP/policy.hujson" \
  '{etag:$etag, hujson:$hujson}' > "$HTH_TEMP/snapshot.json"
hth_save "$HTH_TEMP/snapshot.json"
printf 'COLLECTED: raw policy and ETag; review all existing allows before preparing a replacement.\n'
# HTH Guide Excerpt: end snapshot-policy
