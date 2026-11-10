#!/usr/bin/env bash
# HTH Vercel Control 1.6: Audit Team Member MFA
# Profile Level: L1 (Crawl)
# Frameworks: NIST IA-2(1)
# Source: https://howtoharden.com/guides/vercel/#16-enforce-team-two-factor-authentication
# Reference: https://vercel.com/docs/cli/security (available read-only check)
# This checks member posture, not whether the team's enforcement toggle is on.
set -euo pipefail
: "${VERCEL_TOKEN:?Set VERCEL_TOKEN}"
: "${VERCEL_TEAM_ID:?Set VERCEL_TEAM_ID}"
# HTH Guide Excerpt: begin cli
umask 077
REPORT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/hth-mfa.XXXXXX")"
vercel --scope "${VERCEL_TEAM_ID}" security check members-no-mfa \
  --findings --limit 200 --json > "${REPORT_DIR}/report.json"
jq -e 'type == "object" and (.report | type == "object")' "${REPORT_DIR}/report.json" >/dev/null
echo "MFA report saved privately to ${REPORT_DIR}/report.json."
echo "Review report statuses and counts; CLI exit 0 means report produced, NOT compliance."
echo "Counts remain exact but finding details are capped at 200 per check."
# HTH Guide Excerpt: end cli
