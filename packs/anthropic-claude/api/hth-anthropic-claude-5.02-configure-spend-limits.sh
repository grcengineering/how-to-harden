#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: anthropic-api-4.2
#   guide: https://howtoharden.com/guides/anthropic-api/#42-configure-spend-limits-per-workspace
#   profile: L1
#   mode: read-only
#   requires: ANTHROPIC_ADMIN_KEY(Console admin credential), WORKSPACE_ID
# Source: https://github.com/anthropics/anthropic-sdk-typescript/blob/main/src/resources/organization/workspaces/rate-limits.ts
# This proves rate limits, not spend-cap enforcement; set spend caps in Console.
set -euo pipefail
source "$(dirname "$0")/common.sh"
# HTH Guide Excerpt: begin workspace-rate-limit-readback
: "${WORKSPACE_ID:?Use an explicit named workspace ID}"
[[ "${WORKSPACE_ID}" =~ ^wrkspc_[A-Za-z0-9]+$ ]] || exit 2
ANTHROPIC_VERSION=2026-10-21
evidence=$(anthropic_evidence_dir)
trap 'rm -f "${evidence}/rate-limits.pending"' EXIT
anthropic_page_token_all "/v1/organizations/workspaces/${WORKSPACE_ID}/rate_limits?include_inherited=true&limit=1000" > "${evidence}/rate-limits.pending"
mv "${evidence}/rate-limits.pending" "${evidence}/rate-limits.json"
printf 'Private rate-limit evidence: %s. Check the workspace Spend limits tab separately; this GET sets no cap.\n' "${evidence}/rate-limits.json"
# HTH Guide Excerpt: end workspace-rate-limit-readback
