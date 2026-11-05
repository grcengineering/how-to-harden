#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: claude-enterprise-2.1
#   guide: https://howtoharden.com/guides/claude-enterprise/#21-export-and-retain-audit-logs
#   profile: L2
#   mode: read-only
#   requires: ANTHROPIC_COMPLIANCE_ACCESS_KEY(read:compliance_activities), HTH_ORGANIZATION_ID, HTH_STARTING_AT, HTH_ENDING_AT
# Source: https://platform.claude.com/docs/en/manage-claude/compliance-activity-feed
set -euo pipefail
source "$(dirname "$0")/../../anthropic-claude/api/common.sh"
# HTH Guide Excerpt: begin bounded-activity-evidence
: "${ANTHROPIC_COMPLIANCE_ACCESS_KEY:?Use an activity-only scoped key}"
: "${HTH_ORGANIZATION_ID:?Use the child organization bare UUID}"
: "${HTH_STARTING_AT:?Use an inclusive UTC start}"
: "${HTH_ENDING_AT:?Use an exclusive UTC end}"
[[ "${HTH_ORGANIZATION_ID}" =~ ^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$ ]] || exit 2
for value in "${HTH_STARTING_AT}" "${HTH_ENDING_AT}"; do
  [[ "${value}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]] || exit 2
done
ANTHROPIC_ADMIN_KEY="${ANTHROPIC_COMPLIANCE_ACCESS_KEY}"
ANTHROPIC_VERSION=2026-10-21
evidence=$(anthropic_evidence_dir)
trap 'rm -f "${evidence}/activities.pending"' EXIT
# organization_ids accepts the bare UUID; upper bound avoids an ever-moving read window.
anthropic_list_all "/v1/compliance/activities?organization_ids%5B%5D=${HTH_ORGANIZATION_ID}&created_at.gte=${HTH_STARTING_AT}&created_at.lt=${HTH_ENDING_AT}" > "${evidence}/activities.pending"
jq -e --arg org "${HTH_ORGANIZATION_ID}" 'all(.[]; (.id|type)=="string" and (.type|type)=="string" and (.created_at|type)=="string" and (.organization_uuid|ascii_downcase)==($org|ascii_downcase))' "${evidence}/activities.pending" >/dev/null
mv "${evidence}/activities.pending" "${evidence}/activities.json"
printf 'Complete private activity export: %s. Deduplicate by id before SIEM ingest; no posture event name is guessed.\n' "${evidence}/activities.json"
# HTH Guide Excerpt: end bounded-activity-evidence
