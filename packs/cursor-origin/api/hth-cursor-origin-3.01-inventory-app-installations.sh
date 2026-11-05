#!/usr/bin/env bash
# HTH Pack Contract: v1
# control: cursor-origin-3.1
# guide: https://howtoharden.com/guides/cursor-origin/#31-install-apps-on-selected-repositories-with-minimal-scopes
# profile: L1
# mode: read-only
# requires: Bun; ORIGIN_APP_JWT(existing app signing JWT; not a Cursor Admin key)
# NIST AC-6. Source: https://cursor.com/docs/api/origin (2026-11-05)
# Usage: bash <this-file>. No key generation, token minting, installation or deletion.
# Bash entrypoint; adjacent TypeScript helper performs fixed-host read-only REST or offline JSON preparation.
# Download the complete product pack folder, including common.ts and the adjacent helper.
set -euo pipefail
# HTH Guide Excerpt: begin run-bun-helper
command -v bun >/dev/null 2>&1 || { echo "PRECONDITION: Bun is required" >&2; exit 2; }
PACK_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec bun "${PACK_DIR}/inventory-app-installations.ts" "$@"
# HTH Guide Excerpt: end run-bun-helper
