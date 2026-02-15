#!/usr/bin/env bash
# HTH Okta Control 1.5: Configure Account Lockout
# Profile: L1 | NIST: AC-7 | DISA STIG: V-273189
# https://howtoharden.com/guides/okta/#15-configure-account-lockout
source "$(dirname "$0")/common.sh"

banner "1.5: Configure Account Lockout"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.5 Configuring account lockout..."

# Determine lockout threshold based on profile level
LOCKOUT_THRESHOLD=5
if [ "${HTH_PROFILE_LEVEL}" -ge 2 ]; then
  LOCKOUT_THRESHOLD=3
fi

# Get password policies and update lockout settings
POLICIES=$(okta_get "/api/v1/policies?type=PASSWORD") || {
  fail "1.5 Failed to retrieve password policies"
  increment_failed
  summary
  exit 0
}

POLICY_IDS=$(echo "${POLICIES}" | jq -r '.[].id' 2>/dev/null || true)
updated=0

for POLICY_ID in ${POLICY_IDS}; do
  POLICY_NAME=$(echo "${POLICIES}" | jq -r ".[] | select(.id == \"${POLICY_ID}\") | .name" 2>/dev/null || echo "unknown")
  info "1.5 Updating lockout for policy '${POLICY_NAME}'..."

  # HTH Guide Excerpt: begin api-update-lockout-policy
  okta_put "/api/v1/policies/${POLICY_ID}" "{
    \"settings\": {
      \"password\": {
        \"lockout\": {
          \"maxAttempts\": ${LOCKOUT_THRESHOLD},
          \"autoUnlockMinutes\": 30,
          \"showLockoutFailures\": true
        }
      }
    }
  }" > /dev/null 2>&1 && {
    updated=$((updated + 1))
  } || warn "1.5 Failed to update lockout for policy '${POLICY_NAME}'"
  # HTH Guide Excerpt: end api-update-lockout-policy
done

if [ "${updated}" -gt 0 ]; then
  pass "1.5 Account lockout configured (threshold: ${LOCKOUT_THRESHOLD} attempts) -- ${updated} policy/policies updated"
  increment_applied
else
  fail "1.5 Failed to update any lockout policies"
  increment_failed
fi

summary
