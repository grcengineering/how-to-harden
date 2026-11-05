#!/usr/bin/env bash
# HTH Pack Contract: v1
# control: grok-api-1.2
# guide: https://howtoharden.com/guides/grok-api/#12-audit-key-expiry-limits-and-owner-lifecycle
# profile: L1
# mode: read-only
# requires: Bun; XAI_MANAGEMENT_API_KEY; XAI_TEAM_ID; HTH_TEAM_ADMIN_CONFIRMED=1
# NIST AC-2/AC-6. Source fetched 2026-11-05:
# https://docs.x.ai/developers/rest-api-reference/management/auth
# Usage: bash <this-file>. GET only; does not mint/rotate/delete any key.
# Bash entrypoint; adjacent TypeScript helper performs fixed-host read-only REST or offline JSON preparation.
# Download the complete product pack folder, including common.ts and the adjacent helper.
set -euo pipefail
# HTH Guide Excerpt: begin run-bun-helper
command -v bun >/dev/null 2>&1 || { echo "PRECONDITION: Bun is required" >&2; exit 2; }
PACK_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec bun "${PACK_DIR}/audit-inference-keys.ts" "$@"
# HTH Guide Excerpt: end run-bun-helper
