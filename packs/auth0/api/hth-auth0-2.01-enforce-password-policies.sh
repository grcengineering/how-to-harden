#!/usr/bin/env bash
# HTH Auth0 Control 2.1: Enforce Strong Password Policies
# Profile: L1 | NIST: IA-5 | CIS: 5.2
# https://howtoharden.com/guides/auth0/#21-enforce-strong-password-policies
source "$(dirname "$0")/common.sh"

banner "2.1: Enforce Strong Password Policies"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "2.1 Checking database connection password policy..."

# Find the database connection
CONNECTIONS=$(a0_get "/connections?strategy=auth0") || {
  fail "2.1 Unable to retrieve database connections"
  increment_failed; summary; exit 0
}

CONNECTION_ID=$(echo "${CONNECTIONS}" | jq -r '.[0].id // empty')
if [ -z "${CONNECTION_ID}" ]; then
  warn "2.1 No database connection found"
  increment_skipped; summary; exit 0
fi

CONN_NAME=$(echo "${CONNECTIONS}" | jq -r '.[0].name')
CURRENT_POLICY=$(echo "${CONNECTIONS}" | jq -r '.[0].options.password_policy // "none"')
info "2.1 Connection '${CONN_NAME}' has password policy: ${CURRENT_POLICY}"

# HTH Guide Excerpt: begin api-set-password-policy
# Set strong password policy on database connection
info "2.1 Setting password policy to 'excellent' with history and dictionary..."
RESPONSE=$(a0_patch "/connections/${CONNECTION_ID}" '{
  "options": {
    "password_policy": "excellent",
    "brute_force_protection": true,
    "password_complexity_options": { "min_length": 14 },
    "password_history": { "enable": true, "size": 5 },
    "password_dictionary": { "enable": true },
    "password_no_personal_info": { "enable": true }
  }
}') || {
  fail "2.1 Failed to update password policy"
  increment_failed; summary; exit 0
}
# HTH Guide Excerpt: end api-set-password-policy

RESULT=$(echo "${RESPONSE}" | jq -r '.options.password_policy')
[ "${RESULT}" = "excellent" ] && { pass "2.1 Password policy set to 'excellent'"; increment_applied; } || { fail "2.1 Password policy not confirmed"; increment_failed; }
summary
