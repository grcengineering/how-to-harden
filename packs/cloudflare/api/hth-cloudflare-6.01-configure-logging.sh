#!/usr/bin/env bash
# HTH Cloudflare Control 6.1: Configure Logging
# Profile: L1 | NIST: AU-2, AU-6 | CIS: 8.2
# https://howtoharden.com/guides/cloudflare/#61-configure-logging
#
# Read-only audit. Passes only when an ENABLED Logpush job exists for every
# recommended dataset: access_requests, gateway_dns, gateway_http,
# gateway_network (the Zero Trust logs of Step 1) and audit_logs (admin
# changes; the Terraform pack creates the same five jobs). No jobs at all, or
# any dataset without an enabled job, is a failure. Zero Trust Logpush is
# Enterprise / Contract only, so on other plans this audit reports the gap.
source "$(dirname "$0")/common.sh"

banner "6.1: Configure Logging"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "6.1 Auditing Logpush job configuration..."

# HTH Guide Excerpt: begin api-audit-logpush
# List all Logpush jobs and check for Zero Trust datasets
LOGPUSH=$(cf_get "/accounts/${CF_ACCOUNT_ID}/logpush/jobs") || {
  fail "6.1 Unable to retrieve Logpush jobs"
  increment_failed
  summary
  exit 0
}

JOB_COUNT=$(echo "${LOGPUSH}" | jq '.result | length')
info "6.1 Found ${JOB_COUNT} Logpush job(s)"

# Check for recommended Zero Trust datasets
RECOMMENDED_DATASETS=("access_requests" "gateway_dns" "gateway_http" "gateway_network" "audit_logs")
MISSING_DATASETS=()

for dataset in "${RECOMMENDED_DATASETS[@]}"; do
  HAS_DATASET=$(echo "${LOGPUSH}" | jq --arg ds "${dataset}" '[.result[] | select(.dataset == $ds and .enabled == true)] | length')
  if [ "${HAS_DATASET}" -gt 0 ]; then
    info "6.1 Logpush configured for '${dataset}'"
  else
    warn "6.1 No active Logpush job for '${dataset}'"
    MISSING_DATASETS+=("${dataset}")
  fi
done

echo "${LOGPUSH}" | jq -r '.result[] | "  - \(.name // "unnamed"): \(.dataset) → \((.destination_conf // "") | split("://")[0]) [\(if .enabled then "enabled" else "disabled" end)]"'
# HTH Guide Excerpt: end api-audit-logpush

if [ "${JOB_COUNT}" = "0" ]; then
  fail "6.1 No Logpush jobs are configured (Zero Trust Logpush requires an Enterprise / Contract plan)"
  increment_failed
elif [ ${#MISSING_DATASETS[@]} -gt 0 ]; then
  fail "6.1 Missing an enabled Logpush job for: ${MISSING_DATASETS[*]}"
  increment_failed
else
  pass "6.1 All recommended log datasets have an enabled Logpush job"
  increment_applied
fi

summary
