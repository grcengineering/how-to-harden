#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: statsig-3.1
#   guide: https://howtoharden.com/guides/statsig/#31-require-independent-production-reviews
#   profile: L1
#   mode: read-only
#   requires: STATSIG_CONSOLE_KEY, STATSIG_OUTPUT, bash, curl, jq, Bun
# HTH Statsig 3.1 — Require Independent Production Reviews; NIST CM-3; SOC 2 CC8.1
# Sources: https://api.statsig.com/openapi/20240601.json
# https://github.com/statsig-io/terraform-provider-statsig/blob/v2.2.1/internal/resource_settings_reviews/settings_reviews.go (2026-11-05)
set +x
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
# HTH Guide Excerpt: begin read-review-flags
statsig_api_init 1 console
statsig_request GET /console/v1/settings/reviews "$STATSIG_TEMP/response"
bun "$STATSIG_HELPER" reviews "$STATSIG_TEMP/response" "$STATSIG_TEMP/evidence"
statsig_finish "$STATSIG_TEMP/evidence"
# HTH Guide Excerpt: end read-review-flags
