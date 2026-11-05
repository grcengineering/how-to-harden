#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: anthropic-api-4.1
#   guide: https://howtoharden.com/guides/anthropic-api/#41-monitor-api-usage-and-costs
#   profile: L1
#   mode: read-only
#   requires: ANTHROPIC_ADMIN_KEY(Console admin credential), HTH_STARTING_AT, HTH_ENDING_AT
# Source: https://platform.claude.com/docs/en/manage-claude/usage-cost-analytics-api
# Beta analytics-usage-cost-2026-08-24, API 2026-10-21.
set -euo pipefail
source "$(dirname "$0")/common.sh"
# HTH Guide Excerpt: begin complete-usage-cost-analytics
: "${HTH_STARTING_AT:?Set RFC3339 UTC inclusive start}"
: "${HTH_ENDING_AT:?Set RFC3339 UTC exclusive end, at most 31 days later}"
for value in "${HTH_STARTING_AT}" "${HTH_ENDING_AT}"; do
  [[ "${value}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]] || exit 2
done
ANTHROPIC_VERSION=2026-10-21
HTH_ANTHROPIC_BETA=analytics-usage-cost-2026-08-24
evidence=$(anthropic_evidence_dir)
trap 'rm -f "${evidence}/usage.pending" "${evidence}/cost.pending"' EXIT
query="starting_at=${HTH_STARTING_AT}&ending_at=${HTH_ENDING_AT}&group_by%5B%5D=workspace_id&time_bucket_width=1d&limit=1000"
anthropic_report_all "/v1/organizations/analytics/usage?${query}" > "${evidence}/usage.pending"
anthropic_report_all "/v1/organizations/analytics/cost?${query}" > "${evidence}/cost.pending"
jq -e 'all(.[]; (.group|type)=="object" and (.usage.total_tokens|type)=="number" and .usage.total_tokens>=0)' "${evidence}/usage.pending" >/dev/null
jq -e 'all(.[]; (.group|type)=="object" and .cost.currency=="USD" and (.cost.amount|type)=="string" and (.cost.amount|test("^[0-9]+(\\.[0-9]+)?$")))' "${evidence}/cost.pending" >/dev/null
mv "${evidence}/usage.pending" "${evidence}/usage.json"
mv "${evidence}/cost.pending" "${evidence}/cost.json"
printf 'Private, complete analytics: %s. Cost amount is fractional CENTS, not dollars. Empty results are no activity evidence, not a hardening pass.\n' "${evidence}"
# HTH Guide Excerpt: end complete-usage-cost-analytics
