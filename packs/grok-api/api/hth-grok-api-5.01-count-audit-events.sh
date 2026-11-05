#!/usr/bin/env bash
# HTH Pack Contract: v1
# control: grok-api-5.1
# guide: https://howtoharden.com/guides/grok-api/#51-export-administrative-evidence-and-contain-all-credential-planes
# profile: L1
# mode: read-only
# requires: Bun; XAI_MANAGEMENT_API_KEY; XAI_TEAM_ID; HTH_AUDIT_FROM; HTH_AUDIT_TO
# NIST AU-2/AU-6. Source: https://docs.x.ai/developers/rest-api-reference/management/audit (2026-11-05)
# Usage: bash <this-file>. Counts metadata only; no user, event descriptions or raw export printed.
# Bash entrypoint; adjacent TypeScript helper performs fixed-host read-only REST or offline JSON preparation.
# Download the complete product pack folder, including common.ts and the adjacent helper.
set -euo pipefail
# HTH Guide Excerpt: begin run-bun-helper
command -v bun >/dev/null 2>&1 || { echo "PRECONDITION: Bun is required" >&2; exit 2; }
PACK_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec bun "${PACK_DIR}/count-audit-events.ts" "$@"
# HTH Guide Excerpt: end run-bun-helper
