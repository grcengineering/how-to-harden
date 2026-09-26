#!/usr/bin/env bash
# HTH Cloudflare Control 2.1: Create Secure Application Policies
# Profile: L1 | NIST: AC-3, AC-6 | CIS: 6.4
# https://howtoharden.com/guides/cloudflare/#21-create-secure-application-policies
#
# Read-only audit. Every Access application must carry at least one
# identity-based Access policy. An application fails when it has no policy,
# when a Bypass policy includes Everyone (Access is then not enforced at all),
# or when every policy it has is a Bypass. An Allow policy that includes
# Everyone with no Require rule is reported as a warning. An application whose
# policies cannot be read is a failure, never a pass, and an account with no
# applications is reported as nothing audited. Every page is read.
source "$(dirname "$0")/common.sh"

banner "2.1: Create Secure Application Policies"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "2.1 Auditing Access application policies..."

# HTH Guide Excerpt: begin api-audit-access-apps
# List all Access applications and check policy configuration
APPS=$(cf_get_all "/accounts/${CF_ACCOUNT_ID}/access/apps") || {
  fail "2.1 Unable to retrieve Access applications"
  increment_failed
  summary
  exit 0
}

APP_COUNT=$(echo "${APPS}" | jq '.result | length')
info "2.1 Found ${APP_COUNT} Access application(s)"

UNPROTECTED=0
FETCH_ERR=0
while IFS= read -r app_line; do
  APP_ID=$(echo "${app_line}" | jq -r '.id')
  APP_NAME=$(echo "${app_line}" | jq -r '.name')
  APP_DOMAIN=$(echo "${app_line}" | jq -r '.domain // "N/A"')

  POLICIES=$(cf_get_all "/accounts/${CF_ACCOUNT_ID}/access/apps/${APP_ID}/policies") || {
    fail "2.1 Could not read policies for application '${APP_NAME}'"
    FETCH_ERR=1
    continue
  }
  POLICY_COUNT=$(echo "${POLICIES}" | jq '.result | length')
  # Bypass switches Access off for whoever it includes; including Everyone
  # makes the application public, whatever its other policies say
  OPEN_BYPASS=$(echo "${POLICIES}" | jq '[.result[]
    | select(.decision == "bypass")
    | select(any(.include[]?; has("everyone")))] | length')
  IDENTITY_POLICIES=$(echo "${POLICIES}" | jq '[.result[]
    | select((.decision // "allow") != "bypass")] | length')
  OPEN_ALLOW=$(echo "${POLICIES}" | jq '[.result[]
    | select((.decision // "allow") == "allow")
    | select(any(.include[]?; has("everyone")))
    | select(((.require // []) | length) == 0)] | length')

  if [ "${POLICY_COUNT}" = "0" ]; then
    warn "2.1 Application '${APP_NAME}' (${APP_DOMAIN}) has NO Access policies"
    UNPROTECTED=$((UNPROTECTED + 1))
  elif [ "${OPEN_BYPASS}" -gt 0 ]; then
    warn "2.1 Application '${APP_NAME}' (${APP_DOMAIN}) has a Bypass policy that includes Everyone -- Access is not enforced"
    UNPROTECTED=$((UNPROTECTED + 1))
  elif [ "${IDENTITY_POLICIES}" = "0" ]; then
    warn "2.1 Application '${APP_NAME}' (${APP_DOMAIN}) has only Bypass policies -- no identity-based policy"
    UNPROTECTED=$((UNPROTECTED + 1))
  else
    info "2.1 Application '${APP_NAME}' has ${POLICY_COUNT} policy(s)"
    if [ "${OPEN_ALLOW}" -gt 0 ]; then
      warn "2.1 Application '${APP_NAME}': an Allow policy includes Everyone with no Require rule -- any identity from any login method gets in"
    fi
  fi
done < <(echo "${APPS}" | jq -c '.result[]')
# HTH Guide Excerpt: end api-audit-access-apps

if [ "${FETCH_ERR}" = "1" ]; then
  fail "2.1 Audit incomplete -- one or more applications could not be read"
  increment_failed
elif [ "${APP_COUNT}" = "0" ]; then
  warn "2.1 No Access applications to audit -- nothing was checked"
  increment_skipped
elif [ "${UNPROTECTED}" = "0" ]; then
  pass "2.1 All ${APP_COUNT} Access application(s) have identity-based policies"
  increment_applied
else
  fail "2.1 ${UNPROTECTED} application(s) lack an enforced identity-based Access policy -- add one and remove Bypass-Everyone policies before exposing"
  increment_failed
fi

summary
