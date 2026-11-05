#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: factory-2.7
#   guide: https://howtoharden.com/guides/factory/#27-verify-client-versions-and-controlled-updates
#   profile: L1
#   mode: read-only
#   requires: FACTORY_PROJECT_DIR(trusted absolute directory), FACTORY_VERSION_OUTPUT(new private file), approved Droid CLI, bash, jq, python3
# HTH Factory 2.7 — NIST CM-8, SI-2
# Source: https://docs.factory.com/droid-cli/cli-reference (available; checked 2026-11-05)
set +x
set -Eeuo pipefail
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# HTH Guide Excerpt: begin inventory-client-version
hth_init 1
hth_project
[[ -n "${FACTORY_VERSION_OUTPUT:-}" ]] || hth_unknown 'provide FACTORY_VERSION_OUTPUT'
cd -- "$FACTORY_PROJECT_DIR"
command -v droid > "$HTH_TEMP/version.txt"
droid --version >> "$HTH_TEMP/version.txt" 2> "$HTH_TEMP/droid.stderr" || hth_unknown 'version inventory failed'
droid update --check >> "$HTH_TEMP/version.txt" 2>> "$HTH_TEMP/droid.stderr" ||
  hth_unknown 'update check unavailable or failed; verify distribution and update owner'
hth_save_private "$HTH_TEMP/version.txt" "$FACTORY_VERSION_OUTPUT"
printf 'COLLECTED: client path, version and check-only update result. No update or daemon restart was requested.\n'
# HTH Guide Excerpt: end inventory-client-version
