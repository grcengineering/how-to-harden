#!/usr/bin/env bash
# HTH Cloudflare Control 6.1: Configure Logging
# Profile: L1 | NIST: AU-2, AU-6 | CIS: 8.2
# https://howtoharden.com/guides/cloudflare/#61-configure-logging
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
RECOMMENDED_DATASETS=("access_requests" "gateway_dns" "gateway_http" "gateway_network")
MISSING_DATASETS=()

for dataset in "${RECOMMENDED_DATASETS[@]}"; do
  HAS_DATASET=$(echo "${LOGPUSH}" | jq --arg ds "${dataset}" '[.result[] | select(.dataset == $ds and .enabled == true)] | length')
  if [ "${HAS_DATASET}" -gt 0 ]; then
    pass "6.1 Logpush configured for '${dataset}'"
  else
    warn "6.1 No active Logpush job for '${dataset}'"
    MISSING_DATASETS+=("${dataset}")
  fi
done

echo "${LOGPUSH}" | jq -r '.result[] | "  - \(.name // "unnamed"): \(.dataset) → \(.destination_conf | split("://")[0]) [\(if .enabled then "enabled" else "disabled" end)]"'
# HTH Guide Excerpt: end api-audit-logpush

if [ ${#MISSING_DATASETS[@]} -eq 0 ]; then
  pass "6.1 All recommended Zero Trust log datasets are configured"
else
  warn "6.1 Missing Logpush for: ${MISSING_DATASETS[*]}"
fi

increment_applied
summary
