#!/usr/bin/env bash
# HTH JumpCloud Control 4.1: Configure System Policies
# Profile: L1 | NIST: CM-7 | CIS: 4.1
# https://howtoharden.com/guides/jumpcloud/#41-configure-system-policies
source "$(dirname "$0")/common.sh"

banner "4.1: Configure System Policies"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "4.1 Auditing system policy compliance..."

# HTH Guide Excerpt: begin api-audit-system-policies
# List all device policies and check compliance status
POLICIES=$(jc_get_v2 "/policies") || {
  fail "4.1 Unable to retrieve policies"
  increment_failed; summary; exit 0
}

TOTAL_POLICIES=$(echo "${POLICIES}" | jq 'length')
info "4.1 Total device policies: ${TOTAL_POLICIES}"

# Check each policy for compliance status
for POLICY_ID in $(echo "${POLICIES}" | jq -r '.[].id'); do
  POLICY_NAME=$(echo "${POLICIES}" | jq -r ".[] | select(.id == \"${POLICY_ID}\") | .name")
  STATUSES=$(jc_get_v2 "/policies/${POLICY_ID}/policystatuses" 2>/dev/null) || continue

  TOTAL=$(echo "${STATUSES}" | jq 'length')
  COMPLIANT=$(echo "${STATUSES}" | jq '[.[] | select(.status == "success")] | length')
  NON_COMPLIANT=$(echo "${STATUSES}" | jq '[.[] | select(.status != "success")] | length')

  if [ "${NON_COMPLIANT}" -gt 0 ]; then
    warn "4.1 Policy '${POLICY_NAME}': ${COMPLIANT}/${TOTAL} compliant (${NON_COMPLIANT} non-compliant)"
  else
    info "4.1 Policy '${POLICY_NAME}': ${COMPLIANT}/${TOTAL} compliant"
  fi
done

pass "4.1 System policy compliance audit complete"
increment_applied
# HTH Guide Excerpt: end api-audit-system-policies

summary
