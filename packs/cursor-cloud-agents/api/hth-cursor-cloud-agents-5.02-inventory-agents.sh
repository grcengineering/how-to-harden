#!/usr/bin/env bash
# HTH Pack Contract: v1
# control: cursor-cloud-agents-5.2
# guide: https://howtoharden.com/guides/cursor-cloud-agents/#52-inventory-and-stop-runs-before-removing-access
# profile: L1
# mode: read-only
# requires: Bun; CURSOR_API_KEY(personal Cloud Agent API key)
# NIST AU-2/IR-4. Source: https://cursor.com/docs/cloud-agent/api/endpoints (2026-11-05)
# Usage: bash <this-file>. GET only; current API lists THIS user's agents, not all team members.
# Bash entrypoint; adjacent TypeScript helper performs fixed-host read-only REST or offline JSON preparation.
# Download the complete product pack folder, including common.ts and the adjacent helper.
set -euo pipefail
# HTH Guide Excerpt: begin run-bun-helper
command -v bun >/dev/null 2>&1 || { echo "PRECONDITION: Bun is required" >&2; exit 2; }
PACK_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec bun "${PACK_DIR}/inventory-agents.ts" "$@"
# HTH Guide Excerpt: end run-bun-helper
