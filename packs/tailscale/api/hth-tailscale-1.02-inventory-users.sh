#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tailscale-1.2
#   guide: https://howtoharden.com/guides/tailscale/#12-govern-membership-roles-and-offboarding
#   profile: L1
#   mode: read-only
#   requires: TAILSCALE_ACCESS_TOKEN(users:read), TAILSCALE_TAILNET, TAILSCALE_OUTPUT, bash, curl, jq, python3
# HTH Tailscale 1.2 — Govern Membership, Roles and Offboarding; NIST AC-2, AC-6; SOC 2 CC6.2
# Source: https://github.com/tailscale/tailscale-client-go-v2/blob/main/users.go (available; 2026-11-04)
set +x
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin inventory-users
hth_api_init 1
hth_get "/api/v2/tailnet/${HTH_TAILNET}/users" "$HTH_TEMP/users.json"
jq -e '(.users | type == "array") and all(.users[];
  (.id | type == "string" and length > 0) and (.role | type == "string") and
  (.status | type == "string")) and
  (([.users[].id] | unique | length) == (.users | length))' "$HTH_TEMP/users.json" >/dev/null 2>&1 || hth_unknown 'invalid or duplicate user inventory'
hth_save "$HTH_TEMP/users.json"
printf 'COLLECTED: %s users; reconcile roles and status with the IdP and approved membership.\n' "$(jq '.users | length' "$HTH_TEMP/users.json")"
# HTH Guide Excerpt: end inventory-users
