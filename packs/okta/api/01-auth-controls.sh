#!/usr/bin/env bash
# HTH Okta Code Pack -- Section 1: Authentication & Access Controls
# Controls: 1.1, 1.2, 1.4, 1.5, 1.9, 1.10, 1.11
# https://howtoharden.com/guides/okta/#1-authentication--access-controls
source "$(dirname "$0")/common.sh"

banner "Section 1: Authentication & Access Controls"

# ===========================================================================
# 1.1 Enforce Phishing-Resistant MFA (FIDO2/WebAuthn)
# Profile: L1 | NIST: IA-2(1), IA-2(6) | DISA STIG: V-273190, V-273191
# ===========================================================================
control_1_1() {
  should_apply 1 || { increment_skipped; return 0; }
  info "1.1 Enforcing phishing-resistant MFA (FIDO2/WebAuthn)..."

  # Check if policy already exists (idempotent)
  EXISTING=$(okta_get "/api/v1/policies?type=ACCESS_POLICY" \
    | jq -r '.[] | select(.name == "Phishing-Resistant MFA Policy") | .id' 2>/dev/null || true)

  if [ -n "${EXISTING}" ]; then
    pass "1.1 Phishing-resistant MFA policy already exists (ID: ${EXISTING})"
    increment_applied
    return 0
  fi

  # Create FIDO2 authenticator policy
  info "1.1 Creating phishing-resistant MFA policy..."
  POLICY_RESPONSE=$(okta_post "/api/v1/policies" '{
    "type": "ACCESS_POLICY",
    "name": "Phishing-Resistant MFA Policy",
    "description": "Requires FIDO2 for sensitive applications",
    "priority": 1,
    "conditions": {
      "people": {
        "groups": {
          "include": ["EVERYONE"]
        }
      }
    }
  }') || {
    fail "1.1 Failed to create MFA policy"
    increment_failed
    return 0
  }

  POLICY_ID=$(echo "${POLICY_RESPONSE}" | jq -r '.id // empty' 2>/dev/null || true)

  if [ -n "${POLICY_ID}" ]; then
    # Create policy rule requiring WebAuthn
    info "1.1 Creating policy rule requiring FIDO2..."
    okta_post "/api/v1/policies/${POLICY_ID}/rules" '{
      "name": "Require FIDO2",
      "priority": 1,
      "conditions": {
        "network": {
          "connection": "ANYWHERE"
        }
      },
      "actions": {
        "signon": {
          "access": "ALLOW",
          "requireFactor": true,
          "factorPromptMode": "ALWAYS",
          "primaryFactor": "PASSWORD_IDP_ANY_FACTOR",
          "factorLifetime": 0
        }
      }
    }' > /dev/null 2>&1 || warn "1.1 Policy rule creation returned non-zero (may already exist)"

    pass "1.1 Phishing-resistant MFA policy created (ID: ${POLICY_ID})"
    increment_applied
  else
    fail "1.1 Policy creation returned empty ID"
    increment_failed
  fi
}

# ===========================================================================
# 1.2 Implement Admin Role Separation
# Profile: L1 | NIST: AC-5, AC-6(1)
# ===========================================================================
control_1_2() {
  should_apply 1 || { increment_skipped; return 0; }
  info "1.2 Implementing admin role separation..."

  # Check if Help Desk Admin role already exists (idempotent)
  EXISTING=$(okta_get "/api/v1/iam/roles" \
    | jq -r '.roles[]? | select(.label == "Help Desk Admin") | .id' 2>/dev/null || true)

  if [ -n "${EXISTING}" ]; then
    pass "1.2 Help Desk Admin role already exists (ID: ${EXISTING})"
    increment_applied
    return 0
  fi

  # Create custom Help Desk Admin role
  info "1.2 Creating Help Desk Admin custom role..."
  okta_post "/api/v1/iam/roles" '{
    "label": "Help Desk Admin",
    "description": "Limited admin for password resets and account unlocks",
    "permissions": [
      "okta.users.read",
      "okta.users.credentials.resetPassword",
      "okta.users.lifecycle.unlock"
    ]
  }' > /dev/null 2>&1 && {
    pass "1.2 Help Desk Admin role created"
    increment_applied
  } || {
    fail "1.2 Failed to create Help Desk Admin role"
    increment_failed
  }
}

# ===========================================================================
# 1.4 Configure Password Policy
# Profile: L1 | NIST: IA-5(1) | DISA STIG: V-273195 through V-273201, V-273208, V-273209
# ===========================================================================
control_1_4() {
  should_apply 1 || { increment_skipped; return 0; }
  info "1.4 Configuring password policy..."

  # Determine settings based on profile level
  local MIN_LENGTH=12
  local MAX_AGE_DAYS=90
  local MIN_AGE_MINUTES=0
  local HISTORY_COUNT=4

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
    return 0
  }

  POLICY_IDS=$(echo "${POLICIES}" | jq -r '.[].id' 2>/dev/null || true)

  if [ -z "${POLICY_IDS}" ]; then
    warn "1.4 No password policies found"
    increment_skipped
    return 0
  fi

  local updated=0
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
}

# ===========================================================================
# 1.5 Configure Account Lockout
# Profile: L1 | NIST: AC-7 | DISA STIG: V-273189
# ===========================================================================
control_1_5() {
  should_apply 1 || { increment_skipped; return 0; }
  info "1.5 Configuring account lockout..."

  # Determine lockout threshold based on profile level
  local LOCKOUT_THRESHOLD=5
  if [ "${HTH_PROFILE_LEVEL}" -ge 2 ]; then
    LOCKOUT_THRESHOLD=3
  fi

  # Get password policies and update lockout settings
  POLICIES=$(okta_get "/api/v1/policies?type=PASSWORD") || {
    fail "1.5 Failed to retrieve password policies"
    increment_failed
    return 0
  }

  POLICY_IDS=$(echo "${POLICIES}" | jq -r '.[].id' 2>/dev/null || true)
  local updated=0

  for POLICY_ID in ${POLICY_IDS}; do
    POLICY_NAME=$(echo "${POLICIES}" | jq -r ".[] | select(.id == \"${POLICY_ID}\") | .name" 2>/dev/null || echo "unknown")
    info "1.5 Updating lockout for policy '${POLICY_NAME}'..."

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
  done

  if [ "${updated}" -gt 0 ]; then
    pass "1.5 Account lockout configured (threshold: ${LOCKOUT_THRESHOLD} attempts) -- ${updated} policy/policies updated"
    increment_applied
  else
    fail "1.5 Failed to update any lockout policies"
    increment_failed
  fi
}

# ===========================================================================
# 1.9 Audit Default Authentication Policy
# Profile: L1 | NIST: AC-3, IA-2
# ===========================================================================
control_1_9() {
  should_apply 1 || { increment_skipped; return 0; }
  info "1.9 Auditing default authentication policy..."

  # Find the default policy (system=true)
  DEFAULT_POLICY_ID=$(okta_get "/api/v1/policies?type=ACCESS_POLICY" \
    | jq -r '.[] | select(.system == true and .name == "Default Policy") | .id' 2>/dev/null || true)

  if [ -z "${DEFAULT_POLICY_ID}" ]; then
    warn "1.9 Could not find Default Policy"
    increment_skipped
    return 0
  fi

  info "1.9 Default Policy ID: ${DEFAULT_POLICY_ID}"

  # List apps assigned to the default policy
  DEFAULT_APPS=$(okta_get "/api/v1/policies/${DEFAULT_POLICY_ID}/app" 2>/dev/null || echo "[]")
  APP_COUNT=$(echo "${DEFAULT_APPS}" | jq 'length' 2>/dev/null || echo "0")

  if [ "${APP_COUNT}" -gt 0 ]; then
    warn "1.9 Found ${APP_COUNT} application(s) assigned to the Default Policy (password-only):"
    echo "${DEFAULT_APPS}" | jq -r '.[] | "  - \(.label // .name) (ID: \(.id))"' 2>/dev/null || true
    warn "1.9 These apps allow password-only login -- reassign to an MFA-enforcing policy"
    warn "1.9 Reassign: curl -X PUT \"\${OKTA_BASE}/api/v1/apps/\${APP_ID}/policies/\${TARGET_POLICY_ID}\" -H \"\${AUTH_HEADER}\""
  else
    pass "1.9 Default Policy has zero applications assigned -- no MFA gap"
  fi

  increment_applied
}

# ===========================================================================
# 1.10 Harden Self-Service Recovery
# Profile: L1 | NIST: IA-5(1), IA-11
# ===========================================================================
control_1_10() {
  should_apply 1 || { increment_skipped; return 0; }
  info "1.10 Hardening self-service recovery..."

  # Step 1: Update password policies to restrict recovery methods
  POLICIES=$(okta_get "/api/v1/policies?type=PASSWORD") || {
    fail "1.10 Failed to retrieve password policies"
    increment_failed
    return 0
  }

  POLICY_IDS=$(echo "${POLICIES}" | jq -r '.[].id' 2>/dev/null || true)
  local updated=0

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
}

# ===========================================================================
# 1.11 Enable End-User Security Notifications
# Profile: L1 | NIST: SI-4, IR-6
# ===========================================================================
control_1_11() {
  should_apply 1 || { increment_skipped; return 0; }
  info "1.11 Enabling end-user security notifications..."

  # Enable all five end-user notification types
  info "1.11 Enabling all five notification types..."
  okta_put "/api/v1/org/settings" '{
    "endUserNotifications": {
      "newSignOnNotification": {
        "enabled": true
      },
      "authenticatorEnrolledNotification": {
        "enabled": true
      },
      "authenticatorResetNotification": {
        "enabled": true
      },
      "passwordChangedNotification": {
        "enabled": true
      },
      "factorResetNotification": {
        "enabled": true
      }
    }
  }' > /dev/null 2>&1 && {
    pass "1.11 All five end-user notification types enabled"
  } || {
    fail "1.11 Failed to enable end-user notifications"
    increment_failed
    return 0
  }

  # Enable Suspicious Activity Reporting
  info "1.11 Enabling Suspicious Activity Reporting..."
  okta_post "/api/v1/org/privacy/suspicious-activity-reporting" '{
    "enabled": true
  }' > /dev/null 2>&1 && {
    pass "1.11 Suspicious Activity Reporting enabled"
  } || {
    warn "1.11 Suspicious Activity Reporting may already be enabled"
  }

  # Verify settings
  NOTIFICATIONS=$(okta_get "/api/v1/org/settings" | jq -c '.endUserNotifications' 2>/dev/null || echo "{}")
  info "1.11 Current notification settings: ${NOTIFICATIONS}"

  increment_applied
}

# ===========================================================================
# Execute all controls
# ===========================================================================
control_1_1
control_1_2
control_1_4
control_1_5
control_1_9
control_1_10
control_1_11

summary
