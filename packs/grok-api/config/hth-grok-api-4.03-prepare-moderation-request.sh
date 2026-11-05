#!/usr/bin/env bash
# HTH Pack Contract: v1
# control: grok-api-4.3
# guide: https://howtoharden.com/guides/grok-api/#43-apply-per-request-moderation-and-preserve-provenance
# profile: L1
# mode: read-only
# requires: Bun
# NIST AC-3. Source: https://docs.x.ai/developers/advanced-api-usage/custom-moderation-controls (2026-11-05)
# Usage: bash <this-file>. Emits synthetic JSON only; no key, network or tenant write.
# Bash entrypoint; adjacent TypeScript helper performs fixed-host read-only REST or offline JSON preparation.
# Download the complete product pack folder, including common.ts and the adjacent helper.
set -euo pipefail
# HTH Guide Excerpt: begin run-bun-helper
command -v bun >/dev/null 2>&1 || { echo "PRECONDITION: Bun is required" >&2; exit 2; }
PACK_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec bun "${PACK_DIR}/prepare-moderation-request.ts" "$@"
# HTH Guide Excerpt: end run-bun-helper
