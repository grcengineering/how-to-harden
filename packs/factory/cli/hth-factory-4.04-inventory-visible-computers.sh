#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: factory-4.4
#   guide: https://howtoharden.com/guides/factory/#44-restrict-managed-compute-and-remote-control
#   profile: L2
#   mode: read-only
#   requires: FACTORY_PROJECT_DIR(trusted absolute repository), FACTORY_COMPUTERS_OUTPUT(new private file), authenticated Droid CLI, jq, python3
# HTH Factory 4.4 — NIST AC-6
# Source: https://docs.factory.com/droid-cli/cli-reference (available; verified 2026-10-31)
# Inventory only; no model task, provisioning or policy mutation.
set +x
set -Eeuo pipefail
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# HTH Guide Excerpt: begin inventory-visible-computers
hth_init 2
hth_project
[[ -n "${FACTORY_COMPUTERS_OUTPUT:-}" ]] || hth_unknown 'provide FACTORY_COMPUTERS_OUTPUT'
cd -- "$FACTORY_PROJECT_DIR"
droid computer list > "$HTH_TEMP/inventory.txt" 2> "$HTH_TEMP/droid.stderr" || hth_unknown 'Droid inventory failed'
hth_save_private "$HTH_TEMP/inventory.txt" "$FACTORY_COMPUTERS_OUTPUT"
printf 'COLLECTED: computers visible to this identity; review other operators and persistent resources separately.\n'
# HTH Guide Excerpt: end inventory-visible-computers
