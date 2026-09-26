#!/usr/bin/env bash
# HTH Okta Control 1.4: Configure Password Policy
# Profile: L1 | NIST: IA-5(1) | DISA STIG: V-273195 through V-273201, V-273208, V-273209
# https://howtoharden.com/guides/okta/#14-configure-password-policy
#
# PUT /api/v1/policies/{id} replaces the whole policy, so each policy is read,
# modified with jq, and written back complete (Okta Management API, Policy).
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

info "1.4 Target settings: minLength=${MIN_LENGTH}, maxAge=${MAX_AGE_DAYS}d, minAge=${MIN_AGE_MINUTES}min, history=${HISTORY_COUNT}, common-password check on"

# Get password policies (a failed read stops the pack)
POLICIES=$(okta_get "/api/v1/policies?type=PASSWORD")
POLICY_IDS=$(printf '%s' "${POLICIES}" | jq -r '.[].id')

if [ -z "${POLICY_IDS}" ]; then
  fail "1.4 No password policies returned -- every Okta org has at least the Default Policy"
  increment_failed
  summary
fi

updated=0
failed=0
for POLICY_ID in ${POLICY_IDS}; do
  POLICY_NAME=$(printf '%s' "${POLICIES}" | jq -r --arg id "${POLICY_ID}" '.[] | select(.id == $id) | .name')
  info "1.4 Updating password policy '${POLICY_NAME}' (${POLICY_ID})..."

  # HTH Guide Excerpt: begin api-update-password-policy
  CURRENT=$(okta_get "/api/v1/policies/${POLICY_ID}")
  UPDATED=$(printf '%s' "${CURRENT}" | jq \
    --argjson len "${MIN_LENGTH}" --argjson maxage "${MAX_AGE_DAYS}" \
    --argjson minage "${MIN_AGE_MINUTES}" --argjson hist "${HISTORY_COUNT}" '
    .settings.password.complexity.minLength = $len
    | .settings.password.complexity.minLowerCase = 1
    | .settings.password.complexity.minUpperCase = 1
    | .settings.password.complexity.minNumber = 1
    | .settings.password.complexity.minSymbol = 1
    | .settings.password.complexity.dictionary.common.exclude = true
    | .settings.password.age.maxAgeDays = $maxage
    | .settings.password.age.minAgeMinutes = $minage
    | .settings.password.age.historyCount = $hist')
  if okta_put "/api/v1/policies/${POLICY_ID}" "${UPDATED}" > /dev/null; then
    updated=$((updated + 1))
  else
    fail "1.4 Failed to update policy '${POLICY_NAME}'"
    failed=$((failed + 1))
  fi
  # HTH Guide Excerpt: end api-update-password-policy
done

if [ "${failed}" -eq 0 ]; then
  pass "1.4 Password policy configured (min ${MIN_LENGTH} chars, ${MAX_AGE_DAYS}d max age, ${HISTORY_COUNT} history) -- ${updated} policy/policies updated"
  increment_applied
else
  fail "1.4 ${failed} of $((updated + failed)) password policies were not updated"
  increment_failed
fi

summary
