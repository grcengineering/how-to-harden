#!/usr/bin/env bash
# HTH Okta Control 1.4: Configure Password Policy
# Profile: L1 | NIST: IA-5(1) | DISA STIG: V-273195 through V-273201, V-273208, V-273209
# https://howtoharden.com/guides/okta/#14-configure-password-policy
source "$(dirname "$0")/common.sh"

banner "1.4: Configure Password Policy"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.4 Configuring password policy..."

# Determine settings based on profile level
MIN_LENGTH=12
MAX_AGE_DAYS=90
MIN_AGE_MINUTES=0
HISTORY_COUNT=4

if [ "${HTH_PROFILE_LEVEL}" -ge 2 ]; then
  MIN_LENGTH=15
  MAX_AGE_DAYS=60
  MIN_AGE_MINUTES=1440
  HISTORY_COUNT=5
fi

info "1.4 Target settings: minLength=${MIN_LENGTH}, maxAge=${MAX_AGE_DAYS}d, minAge=${MIN_AGE_MINUTES}min, history=${HISTORY_COUNT}"

# Get password policies
POLICIES=$(okta_get "/api/v1/policies?type=PASSWORD") || {
  fail "1.4 Failed to retrieve password policies"
  increment_failed
  summary
  exit 0
}

POLICY_IDS=$(echo "${POLICIES}" | jq -r '.[].id' 2>/dev/null || true)

if [ -z "${POLICY_IDS}" ]; then
  warn "1.4 No password policies found"
  increment_skipped
  summary
  exit 0
fi

updated=0
for POLICY_ID in ${POLICY_IDS}; do
  POLICY_NAME=$(echo "${POLICIES}" | jq -r ".[] | select(.id == \"${POLICY_ID}\") | .name" 2>/dev/null || echo "unknown")
  info "1.4 Updating password policy '${POLICY_NAME}' (${POLICY_ID})..."

  okta_put "/api/v1/policies/${POLICY_ID}" "{
    \"settings\": {
      \"password\": {
        \"complexity\": {
          \"minLength\": ${MIN_LENGTH},
          \"minLowerCase\": 1,
          \"minUpperCase\": 1,
          \"minNumber\": 1,
          \"minSymbol\": 1
        },
        \"age\": {
          \"maxAgeDays\": ${MAX_AGE_DAYS},
          \"minAgeMinutes\": ${MIN_AGE_MINUTES},
          \"historyCount\": ${HISTORY_COUNT}
        }
      }
    }
  }" > /dev/null 2>&1 && {
    updated=$((updated + 1))
  } || warn "1.4 Failed to update policy '${POLICY_NAME}'"
done

if [ "${updated}" -gt 0 ]; then
  pass "1.4 Password policy configured (min ${MIN_LENGTH} chars, ${MAX_AGE_DAYS}d max age, ${HISTORY_COUNT} history) -- ${updated} policy/policies updated"
  increment_applied
else
  fail "1.4 Failed to update any password policies"
  increment_failed
fi

summary
