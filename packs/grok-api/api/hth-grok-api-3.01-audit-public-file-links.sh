#!/usr/bin/env bash
# HTH Pack Contract: v1
# control: grok-api-3.1
# guide: https://howtoharden.com/guides/grok-api/#31-keep-files-private-and-expire-public-media-links
# profile: L1
# mode: read-only
# requires: Bun; XAI_API_KEY; HTH_MAX_PUBLIC_URL_HOURS(optional, default24)
# NIST SC-8/SI-12. Sources fetched 2026-11-05:
# https://docs.x.ai/developers/files/public-urls
# https://docs.x.ai/developers/files/managing-files
# Usage: bash <this-file>. GET metadata only; never fetches or prints bearer URLs.
# Bash entrypoint; adjacent TypeScript helper performs fixed-host read-only REST or offline JSON preparation.
# Download the complete product pack folder, including common.ts and the adjacent helper.
set -euo pipefail
# HTH Guide Excerpt: begin run-bun-helper
command -v bun >/dev/null 2>&1 || { echo "PRECONDITION: Bun is required" >&2; exit 2; }
PACK_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec bun "${PACK_DIR}/audit-public-file-links.ts" "$@"
# HTH Guide Excerpt: end run-bun-helper
