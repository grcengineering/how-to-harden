#!/usr/bin/env bash
# HTH Cloudflare Control 2.4: Replace Long-Lived SSH Keys with Access for Infrastructure
# Profile: L2 | NIST: AC-17, IA-5(2), AU-14 | CIS: 6.4, 8.5
# https://howtoharden.com/guides/cloudflare/#24-replace-long-lived-ssh-keys-with-access-for-infrastructure
#
# Read-only audit. Lists infrastructure targets and every Access application
# of type "infrastructure", and fails if any infrastructure application has no
# Access policy or cannot be read.
source "$(dirname "$0")/common.sh"

banner "2.4: Replace Long-Lived SSH Keys with Access for Infrastructure"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "2.4 Auditing Access for Infrastructure targets and applications..."

# HTH Guide Excerpt: begin api-audit-infrastructure
TARGETS=$(cf_get_all "/accounts/${CF_ACCOUNT_ID}/infrastructure/targets") || {
  fail "2.4 Unable to list infrastructure targets"
  increment_failed
  summary
  exit 0
}
TARGET_COUNT=$(echo "${TARGETS}" | jq '.result | length')
info "2.4 Found ${TARGET_COUNT} infrastructure target(s)"

APPS=$(cf_get_all "/accounts/${CF_ACCOUNT_ID}/access/apps") || {
  fail "2.4 Unable to retrieve Access applications"
  increment_failed
  summary
  exit 0
}

INFRA_COUNT=0
NO_POLICY=0
FETCH_ERR=0
while IFS= read -r app; do
  INFRA_COUNT=$((INFRA_COUNT + 1))
  APP_ID=$(echo "${app}" | jq -r '.id')
  APP_NAME=$(echo "${app}" | jq -r '.name')
  POLICIES=$(cf_get_all "/accounts/${CF_ACCOUNT_ID}/access/apps/${APP_ID}/policies") || {
    fail "2.4 Could not read policies for infrastructure application '${APP_NAME}'"
    FETCH_ERR=1
    continue
  }
  if [ "$(echo "${POLICIES}" | jq '.result | length')" = "0" ]; then
    warn "2.4 Infrastructure application '${APP_NAME}' has no Access policy"
    NO_POLICY=$((NO_POLICY + 1))
  fi
done < <(echo "${APPS}" | jq -c '.result[] | select(.type == "infrastructure")')
# HTH Guide Excerpt: end api-audit-infrastructure

if [ "${FETCH_ERR}" = "1" ]; then
  fail "2.4 Audit incomplete -- one or more applications could not be read"
  increment_failed
elif [ "${TARGET_COUNT}" -gt 0 ] && [ "${INFRA_COUNT}" = "0" ]; then
  fail "2.4 ${TARGET_COUNT} target(s) registered but no infrastructure application protects them"
  increment_failed
elif [ "${INFRA_COUNT}" = "0" ]; then
  info "2.4 No infrastructure targets or applications -- nothing was checked"
  increment_skipped
elif [ "${NO_POLICY}" = "0" ]; then
  pass "2.4 All ${INFRA_COUNT} infrastructure application(s) have Access policies"
  increment_applied
else
  fail "2.4 ${NO_POLICY} infrastructure application(s) without Access policies"
  increment_failed
fi

summary
