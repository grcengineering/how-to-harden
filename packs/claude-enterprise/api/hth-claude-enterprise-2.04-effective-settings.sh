#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: claude-enterprise-2.4
#   guide: https://howtoharden.com/guides/claude-enterprise/#24-assess-effective-settings-against-an-explicit-baseline
#   profile: L2
#   mode: read-only
#   requires: ANTHROPIC_COMPLIANCE_ACCESS_KEY(read:compliance_org_data), HTH_ORGANIZATION_ID, HTH_BASELINE_FILE
# Source: https://platform.claude.com/docs/en/manage-claude/compliance-org-data (2026-11-05)
set -euo pipefail
source "$(dirname "$0")/../../anthropic-claude/api/common.sh"
# HTH Guide Excerpt: begin effective-settings-assessment
# A baseline is an operator-reviewed JSON array of {name,type,value} rows.
# This is an HTH assessment input, not vendor configuration or native posture status.
: "${ANTHROPIC_COMPLIANCE_ACCESS_KEY:?Inject a read:compliance_org_data key}"
: "${HTH_ORGANIZATION_ID:?Use the linked child organization bare UUID}"
: "${HTH_BASELINE_FILE:?Supply a reviewed nonempty baseline JSON file}"
[[ "${HTH_ORGANIZATION_ID}" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]] || exit 2
[[ -f "${HTH_BASELINE_FILE}" && ! -L "${HTH_BASELINE_FILE}" ]] || exit 2
command -v node >/dev/null || { echo 'Node.js 22+ is required.' >&2; exit 2; }
ANTHROPIC_ADMIN_KEY="${ANTHROPIC_COMPLIANCE_ACCESS_KEY}"
ANTHROPIC_VERSION=2026-10-21
evidence=$(anthropic_evidence_dir)
trap 'rm -f "${evidence}/response.pending" "${evidence}/assessment.pending"' EXIT
anthropic_get "/v1/compliance/organizations/${HTH_ORGANIZATION_ID}/settings" > "${evidence}/response.pending"
result=0
node "$(dirname "$0")/../lib/effective-settings.js" "${evidence}/response.pending" "${HTH_BASELINE_FILE}" "${HTH_ORGANIZATION_ID}" > "${evidence}/assessment.pending" || result=$?
[[ -s "${evidence}/assessment.pending" ]] || exit 2
mv "${evidence}/response.pending" "${evidence}/effective-settings.json"
mv "${evidence}/assessment.pending" "${evidence}/assessment.json"
printf 'Private evidence: %s (0 match, 1 differs, 2 incomplete/unknown).\n' "${evidence}"
exit "${result}"
# HTH Guide Excerpt: end effective-settings-assessment
