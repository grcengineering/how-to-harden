#!/usr/bin/env bash
# HTH Cloudflare Control 2.1: Create Secure Application Policies
# Profile: L1 | NIST: AC-3, AC-6 | CIS: 6.4
# https://howtoharden.com/guides/cloudflare/#21-create-secure-application-policies
source "$(dirname "$0")/common.sh"

banner "2.1: Create Secure Application Policies"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "2.1 Auditing Access application policies..."

# HTH Guide Excerpt: begin api-audit-access-apps
# List all Access applications and check policy configuration
APPS=$(cf_get "/accounts/${CF_ACCOUNT_ID}/access/apps") || {
  fail "2.1 Unable to retrieve Access applications"
  increment_failed
  summary
  exit 0
}

APP_COUNT=$(echo "${APPS}" | jq '.result | length')
info "2.1 Found ${APP_COUNT} Access application(s)"

UNPROTECTED=0
while IFS= read -r app_line; do
  APP_ID=$(echo "${app_line}" | jq -r '.id')
  APP_NAME=$(echo "${app_line}" | jq -r '.name')
  APP_DOMAIN=$(echo "${app_line}" | jq -r '.domain // "N/A"')

  POLICIES=$(cf_get "/accounts/${CF_ACCOUNT_ID}/access/apps/${APP_ID}/policies") || continue
  POLICY_COUNT=$(echo "${POLICIES}" | jq '.result | length')

  if [ "${POLICY_COUNT}" = "0" ]; then
    warn "2.1 Application '${APP_NAME}' (${APP_DOMAIN}) has NO Access policies"
    UNPROTECTED=$((UNPROTECTED + 1))
  else
    pass "2.1 Application '${APP_NAME}' has ${POLICY_COUNT} policy(s)"
  fi
done < <(echo "${APPS}" | jq -c '.result[]')
# HTH Guide Excerpt: end api-audit-access-apps

if [ "${UNPROTECTED}" = "0" ]; then
  pass "2.1 All Access applications have policies configured"
else
  warn "2.1 ${UNPROTECTED} application(s) have no Access policies -- create policies before exposing"
fi

increment_applied
summary
