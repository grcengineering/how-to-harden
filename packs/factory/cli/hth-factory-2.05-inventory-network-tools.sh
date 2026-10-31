#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: factory-2.5
#   guide: https://howtoharden.com/guides/factory/#25-govern-built-in-network-tools
#   profile: L2
#   mode: read-only
#   requires: FACTORY_PROJECT_DIR(trusted absolute repository), FACTORY_TOOLS_OUTPUT(new private file), authenticated Droid CLI, jq, python3
# HTH Factory 2.5 — NIST AC-6
# Source: https://docs.factory.com/droid-cli/cli-reference (available; verified 2026-10-31)
# Inventory only; no model task, provisioning or policy mutation.
set +x
set -Eeuo pipefail
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# HTH Guide Excerpt: begin inventory-network-tools
hth_init 2
hth_project
[[ -n "${FACTORY_TOOLS_OUTPUT:-}" ]] || hth_unknown 'provide FACTORY_TOOLS_OUTPUT'
cd -- "$FACTORY_PROJECT_DIR"
droid exec --list-tools > "$HTH_TEMP/inventory.txt" 2> "$HTH_TEMP/droid.stderr" || hth_unknown 'Droid inventory failed'
hth_save_private "$HTH_TEMP/inventory.txt" "$FACTORY_TOOLS_OUTPUT"
printf 'COLLECTED: available tools; confirm built-in Search is absent and test Fetch approval separately.\n'
# HTH Guide Excerpt: end inventory-network-tools
