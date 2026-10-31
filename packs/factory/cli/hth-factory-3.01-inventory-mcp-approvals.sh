#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: factory-3.1
#   guide: https://howtoharden.com/guides/factory/#31-allow-only-reviewed-mcp-servers-and-tools
#   profile: L2
#   mode: read-only
#   requires: FACTORY_PROJECT_DIR(trusted absolute repository path), FACTORY_MCP_OUTPUT(new private file), Droid CLI, jq, python3
# HTH Factory 3.1 — NIST AC-6, CM-7
# Source: https://docs.factory.com/harness/mcp (available; verified 2026-10-30)
# Inventory can load configured runtime components; use a trusted managed project.
set +x
set -Eeuo pipefail
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# HTH Guide Excerpt: begin inventory-mcp-approvals
hth_init 2
hth_project
[[ -n "${FACTORY_MCP_OUTPUT:-}" ]] || hth_unknown 'provide FACTORY_MCP_OUTPUT'
cd -- "$FACTORY_PROJECT_DIR"
droid mcp list > "$HTH_TEMP/servers.txt" 2> "$HTH_TEMP/droid.stderr" || hth_unknown 'MCP inventory failed'
droid mcp permissions list > "$HTH_TEMP/permissions.txt" 2> "$HTH_TEMP/droid.stderr" || hth_unknown 'MCP approval inventory failed'
jq -n --rawfile servers "$HTH_TEMP/servers.txt" --rawfile permissions "$HTH_TEMP/permissions.txt" \
  '{servers: $servers, persistentPermissions: $permissions}' > "$HTH_TEMP/mcp.json"
hth_save_private "$HTH_TEMP/mcp.json" "$FACTORY_MCP_OUTPUT"
printf 'COLLECTED: MCP servers and persistent approvals; review against the managed allowlist.\n'
# HTH Guide Excerpt: end inventory-mcp-approvals
