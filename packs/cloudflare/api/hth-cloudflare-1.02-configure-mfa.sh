#!/usr/bin/env bash
# HTH Cloudflare Control 1.2: Configure Multi-Factor Authentication
# Profile: L1 | NIST: IA-2(1) | CIS: 6.5
# https://howtoharden.com/guides/cloudflare/#12-configure-multi-factor-authentication
source "$(dirname "$0")/common.sh"

banner "1.2: Configure Multi-Factor Authentication"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.2 Checking MFA enforcement in Access policies..."

# List Access policies to verify MFA requirement
POLICIES=$(cf_get "/accounts/${CF_ACCOUNT_ID}/access/apps") || {
  fail "1.2 Unable to retrieve Access applications"
  increment_failed
  summary
  exit 0
}

APP_COUNT=$(echo "${POLICIES}" | jq '.result | length')
info "1.2 Found ${APP_COUNT} Access application(s)"

# HTH Guide Excerpt: begin api-verify-mfa
# Verify MFA is required in Access policies
# MFA enforcement is set via Access policy 'require' rules
# Check each app for auth_method = mfa in require blocks
MFA_MISSING=0
while IFS= read -r app_id; do
  APP_POLICIES=$(cf_get "/accounts/${CF_ACCOUNT_ID}/access/apps/${app_id}/policies") || continue
  HAS_MFA=$(echo "${APP_POLICIES}" | jq '[.result[].require[]? | select(.auth_method.auth_method == "mfa")] | length')
  if [ "${HAS_MFA}" = "0" ]; then
    APP_NAME=$(echo "${POLICIES}" | jq -r ".result[] | select(.id == \"${app_id}\") | .name")
    warn "1.2 Application '${APP_NAME}' does not require MFA"
    MFA_MISSING=$((MFA_MISSING + 1))
  fi
done < <(echo "${POLICIES}" | jq -r '.result[].id')
# HTH Guide Excerpt: end api-verify-mfa

if [ "${MFA_MISSING}" = "0" ]; then
  pass "1.2 All Access applications require MFA"
  increment_applied
else
  warn "1.2 ${MFA_MISSING} application(s) missing MFA requirement -- configure via IdP or Access policy"
  increment_applied
fi

summary
