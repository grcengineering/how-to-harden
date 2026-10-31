#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: factory-3.2
#   guide: https://howtoharden.com/guides/factory/#32-restrict-plugins-and-marketplace-sources
#   profile: L2
#   mode: read-only
#   requires: FACTORY_PROJECT_DIR(trusted absolute repository path), FACTORY_PLUGINS_OUTPUT(new private file), Droid CLI, jq, python3
# HTH Factory 3.2 — NIST CM-7, CM-10
# Source: https://docs.factory.com/droid-cli/cli-reference (available; verified 2026-10-30)
set +x
set -Eeuo pipefail
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# HTH Guide Excerpt: begin inventory-plugins
hth_init 2
hth_project
[[ -n "${FACTORY_PLUGINS_OUTPUT:-}" ]] || hth_unknown 'provide FACTORY_PLUGINS_OUTPUT'
cd -- "$FACTORY_PROJECT_DIR"
droid plugin list > "$HTH_TEMP/plugins.txt" 2> "$HTH_TEMP/droid.stderr" || hth_unknown 'plugin inventory failed'
hth_save_private "$HTH_TEMP/plugins.txt" "$FACTORY_PLUGINS_OUTPUT"
printf 'COLLECTED: installed plugins. Installation does not prove enablement or managed-policy enforcement.\n'
# HTH Guide Excerpt: end inventory-plugins
