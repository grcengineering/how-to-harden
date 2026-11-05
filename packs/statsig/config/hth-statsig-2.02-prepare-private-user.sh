#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: statsig-2.2
#   guide: https://howtoharden.com/guides/statsig/#22-keep-sensitive-targeting-data-out-of-logs
#   profile: L2
#   mode: read-only
#   requires: STATSIG_USER_INPUT, STATSIG_OUTPUT, bash, jq, Bun
# HTH Statsig 2.2 — Keep Sensitive Targeting Data out of Logs; NIST PT-3; SOC 2 CC6.1
# Source: https://docs.statsig.com/guides/private-attributes (2026-11-05)
# Emits a native StatsigUser parameter object, not a project policy or an SDK installer.
set +x
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
# HTH Guide Excerpt: begin prepare-private-user
statsig_init 2
[[ -f "${STATSIG_USER_INPUT:-}" ]] || statsig_unknown 'provide a reviewed native user input file'
bun "$STATSIG_HELPER" user "$STATSIG_USER_INPUT" "$STATSIG_TEMP/candidate"
bun "$STATSIG_HELPER" save "$STATSIG_TEMP/candidate"
printf 'GENERATED-CANDIDATE: native user parameter only; client initialization still sends privateAttributes for evaluation.\n'
# HTH Guide Excerpt: end prepare-private-user
