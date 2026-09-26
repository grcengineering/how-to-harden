#!/usr/bin/env bash
# HTH Okta Control 1.10: Harden Self-Service Recovery
# Profile: L1 | NIST: IA-5(1), IA-11
# https://howtoharden.com/guides/okta/#110-harden-self-service-recovery
#
# Identity Engine keeps the recovery authenticators in each password policy RULE
# (actions.selfServicePasswordReset.requirement.primary.methods), not in the
# policy's settings object (Okta Management API, Policy: PasswordPolicyRuleActions,
# SsprPrimaryRequirement). PUT replaces the whole object, so every rule and
# authenticator is read, modified with jq, and written back complete.
source "$(dirname "$0")/common.sh"

banner "1.10: Harden Self-Service Recovery"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.10 Hardening self-service recovery..."

failed=0
updated=0

# Step 1: restrict recovery methods in every password policy rule
POLICIES=$(okta_get "/api/v1/policies?type=PASSWORD")
POLICY_IDS=$(printf '%s' "${POLICIES}" | jq -r '.[].id')

for POLICY_ID in ${POLICY_IDS}; do
  POLICY_NAME=$(printf '%s' "${POLICIES}" | jq -r --arg id "${POLICY_ID}" '.[] | select(.id == $id) | .name')
  RULE_IDS=$(okta_get "/api/v1/policies/${POLICY_ID}/rules" | jq -r '.[].id')
  for RULE_ID in ${RULE_IDS}; do
    info "1.10 Restricting recovery methods in policy '${POLICY_NAME}', rule ${RULE_ID}..."
    # HTH Guide Excerpt: begin api-update-recovery-settings
    # Recovery may start only with Okta Verify push or email -- never SMS, voice, or OTP
    RULE=$(okta_get "/api/v1/policies/${POLICY_ID}/rules/${RULE_ID}")
    UPDATED=$(printf '%s' "${RULE}" | jq '
      .actions.selfServicePasswordReset.requirement.primary.methods = ["push", "email"]
      | del(.actions.selfServicePasswordReset.requirement.primary.methodConstraints)')
    if okta_put "/api/v1/policies/${POLICY_ID}/rules/${RULE_ID}" "${UPDATED}" > /dev/null; then
      updated=$((updated + 1))
    else
      fail "1.10 Failed to update rule ${RULE_ID} in policy '${POLICY_NAME}'"
      failed=$((failed + 1))
    fi
    # HTH Guide Excerpt: end api-update-recovery-settings
  done
done

AUTHENTICATORS=$(okta_get "/api/v1/authenticators")

# HTH Guide Excerpt: begin api-deactivate-security-question
# Step 2: Deactivate the Security Question authenticator if it is active
SECURITY_QUESTION=$(printf '%s' "${AUTHENTICATORS}" | jq -c '[.[] | select(.key == "security_question")][0] // empty')
if [ -n "${SECURITY_QUESTION}" ] && [ "$(printf '%s' "${SECURITY_QUESTION}" | jq -r '.status')" = "ACTIVE" ]; then
  SQ_ID=$(printf '%s' "${SECURITY_QUESTION}" | jq -r '.id')
  if okta_post "/api/v1/authenticators/${SQ_ID}/lifecycle/deactivate" '{}' > /dev/null; then
    info "1.10 Security Question authenticator deactivated"
  else
    fail "1.10 Failed to deactivate the Security Question authenticator"
    failed=$((failed + 1))
  fi
else
  info "1.10 Security Question authenticator is not active"
fi
# HTH Guide Excerpt: end api-deactivate-security-question

# HTH Guide Excerpt: begin api-update-phone-authenticator
# Step 3: Phone may still serve sign-in (allowedFor "sso") but never recovery
PHONE=$(printf '%s' "${AUTHENTICATORS}" | jq -c '[.[] | select(.key == "phone_number")][0] // empty')
if [ -n "${PHONE}" ]; then
  PHONE_ID=$(printf '%s' "${PHONE}" | jq -r '.id')
  PHONE_UPDATED=$(printf '%s' "${PHONE}" | jq '.settings.allowedFor = "sso"')
  if okta_put "/api/v1/authenticators/${PHONE_ID}" "${PHONE_UPDATED}" > /dev/null; then
    info "1.10 Phone authenticator restricted to sign-in only (allowedFor: sso)"
  else
    fail "1.10 Failed to update the Phone authenticator"
    failed=$((failed + 1))
  fi
fi
# HTH Guide Excerpt: end api-update-phone-authenticator

if [ "${failed}" -eq 0 ]; then
  pass "1.10 Self-service recovery hardened -- ${updated} password policy rule(s) updated"
  increment_applied
else
  fail "1.10 ${failed} recovery change(s) failed"
  increment_failed
fi

summary
