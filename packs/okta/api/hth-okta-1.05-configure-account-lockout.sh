#!/usr/bin/env bash
# HTH Okta Control 1.5: Configure Account Lockout
# Profile: L1 | NIST: AC-7 | DISA STIG: V-273189
# https://howtoharden.com/guides/okta/#15-configure-account-lockout
#
# PUT /api/v1/policies/{id} replaces the whole policy, so each policy is read,
# modified with jq, and written back complete (Okta Management API, Policy).
# autoUnlockMinutes: 0 means "no automatic unlock" (stays locked until an admin unlocks).
source "$(dirname "$0")/common.sh"

banner "1.5: Configure Account Lockout"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.5 Configuring account lockout..."

# Determine lockout threshold and duration based on profile level
LOCKOUT_THRESHOLD=5
AUTO_UNLOCK_MINUTES=30
if [ "${HTH_PROFILE_LEVEL}" -ge 2 ]; then
  LOCKOUT_THRESHOLD=3
  AUTO_UNLOCK_MINUTES=0
fi

# Get password policies (a failed read stops the pack)
POLICIES=$(okta_get "/api/v1/policies?type=PASSWORD")
POLICY_IDS=$(printf '%s' "${POLICIES}" | jq -r '.[].id')

if [ -z "${POLICY_IDS}" ]; then
  fail "1.5 No password policies returned -- every Okta org has at least the Default Policy"
  increment_failed
  summary
fi

updated=0
failed=0
for POLICY_ID in ${POLICY_IDS}; do
  POLICY_NAME=$(printf '%s' "${POLICIES}" | jq -r --arg id "${POLICY_ID}" '.[] | select(.id == $id) | .name')
  info "1.5 Updating lockout for policy '${POLICY_NAME}'..."

  # HTH Guide Excerpt: begin api-update-lockout-policy
  CURRENT=$(okta_get "/api/v1/policies/${POLICY_ID}")
  UPDATED=$(printf '%s' "${CURRENT}" | jq \
    --argjson max "${LOCKOUT_THRESHOLD}" --argjson unlock "${AUTO_UNLOCK_MINUTES}" '
    .settings.password.lockout.maxAttempts = $max
    | .settings.password.lockout.autoUnlockMinutes = $unlock
    | .settings.password.lockout.showLockoutFailures = true')
  if okta_put "/api/v1/policies/${POLICY_ID}" "${UPDATED}" > /dev/null; then
    updated=$((updated + 1))
  else
    fail "1.5 Failed to update lockout for policy '${POLICY_NAME}'"
    failed=$((failed + 1))
  fi
  # HTH Guide Excerpt: end api-update-lockout-policy
done

if [ "${failed}" -eq 0 ]; then
  pass "1.5 Account lockout configured (threshold: ${LOCKOUT_THRESHOLD} attempts, auto-unlock: ${AUTO_UNLOCK_MINUTES} min) -- ${updated} policy/policies updated"
  increment_applied
else
  fail "1.5 ${failed} of $((updated + failed)) password policies were not updated"
  increment_failed
fi

summary
