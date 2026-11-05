#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: statsig-2.1
#   guide: https://howtoharden.com/guides/statsig/#21-separate-and-scope-sdk-and-console-keys
#   profile: L1
#   mode: read-only
#   requires: STATSIG_CONSOLE_KEY, STATSIG_OUTPUT, bash, curl, jq, Bun
# HTH Statsig 2.1 — Separate and Scope SDK and Console Keys; NIST IA-5, AC-6; SOC 2 CC6.1
# Source: https://docs.statsig.com/api-reference/keys/list-keys (2026-11-05)
set +x
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
# HTH Guide Excerpt: begin inventory-key-metadata
statsig_api_init 1 console
page=1
while :; do
  statsig_request GET "/console/v1/keys?limit=100&page=$page" "$STATSIG_TEMP/response"
  next=$(bun "$STATSIG_HELPER" keys-page "$STATSIG_TEMP/response" "$page" "$STATSIG_TEMP/keys")
  [[ "$next" != 'done' ]] || break
  (( page < 100 )) || statsig_unknown 'page bound reached; incomplete inventory discarded'
  page=$((page+1))
done
bun "$STATSIG_HELPER" keys-finish "$STATSIG_TEMP/keys" "$STATSIG_TEMP/evidence"
statsig_finish "$STATSIG_TEMP/evidence"
# HTH Guide Excerpt: end inventory-key-metadata
