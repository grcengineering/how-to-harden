#!/usr/bin/env bash
# HTH Okta Control 1.10: Harden Self-Service Recovery
# Profile: L1 | NIST: IA-5(1), IA-11
# https://howtoharden.com/guides/okta/#110-harden-self-service-recovery
source "$(dirname "$0")/common.sh"

banner "1.10: Harden Self-Service Recovery"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.10 Hardening self-service recovery..."

# Step 1: Update password policies to restrict recovery methods
POLICIES=$(okta_get "/api/v1/policies?type=PASSWORD") || {
  fail "1.10 Failed to retrieve password policies"
  increment_failed
  summary
  exit 0
}

POLICY_IDS=$(echo "${POLICIES}" | jq -r '.[].id' 2>/dev/null || true)
updated=0

for POLICY_ID in ${POLICY_IDS}; do
  POLICY_NAME=$(echo "${POLICIES}" | jq -r ".[] | select(.id == \"${POLICY_ID}\") | .name" 2>/dev/null || echo "unknown")
  info "1.10 Updating recovery settings for policy '${POLICY_NAME}'..."

  okta_put "/api/v1/policies/${POLICY_ID}" '{
    "settings": {
      "recovery": {
        "factors": {
          "okta_email": {
            "status": "ACTIVE",
            "properties": {
              "recoveryToken": {
                "tokenLifetimeMinutes": 10
              }
            }
          },
          "okta_sms": {
            "status": "INACTIVE"
          },
          "okta_call": {
            "status": "INACTIVE"
          },
          "recovery_question": {
            "status": "INACTIVE"
          }
        }
      }
    }
  }' > /dev/null 2>&1 && {
    updated=$((updated + 1))
  } || warn "1.10 Failed to update recovery for policy '${POLICY_NAME}'"
done

# Step 2: Deactivate Security Question authenticator
info "1.10 Deactivating Security Question authenticator..."
SECURITY_QUESTION_ID=$(okta_get "/api/v1/authenticators" \
  | jq -r '.[] | select(.key == "security_question") | .id' 2>/dev/null || true)

if [ -n "${SECURITY_QUESTION_ID}" ]; then
  okta_post "/api/v1/authenticators/${SECURITY_QUESTION_ID}/lifecycle/deactivate" '{}' > /dev/null 2>&1 \
    && info "1.10 Security Question authenticator deactivated" \
    || warn "1.10 Security Question may already be inactive"
fi

# Step 3: Update Phone authenticator to remove recovery usage
info "1.10 Removing Phone authenticator from recovery..."
PHONE_ID=$(okta_get "/api/v1/authenticators" \
  | jq -r '.[] | select(.key == "phone_number") | .id' 2>/dev/null || true)

if [ -n "${PHONE_ID}" ]; then
  okta_put "/api/v1/authenticators/${PHONE_ID}" '{
    "name": "Phone",
    "settings": {
      "allowedFor": "authentication"
    }
  }' > /dev/null 2>&1 \
    && info "1.10 Phone authenticator restricted to authentication only" \
    || warn "1.10 Failed to update phone authenticator"
fi

if [ "${updated}" -gt 0 ]; then
  pass "1.10 Self-service recovery hardened (SMS/voice/questions disabled) -- ${updated} policy/policies updated"
  increment_applied
else
  fail "1.10 Failed to update any recovery settings"
  increment_failed
fi

summary
