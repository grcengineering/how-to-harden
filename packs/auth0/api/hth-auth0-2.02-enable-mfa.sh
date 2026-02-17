#!/usr/bin/env bash
# HTH Auth0 Control 2.2: Enable Multi-Factor Authentication
# Profile: L1 | NIST: IA-2(1) | CIS: 6.5
# https://howtoharden.com/guides/auth0/#22-enable-multi-factor-authentication
source "$(dirname "$0")/common.sh"

banner "2.2: Enable Multi-Factor Authentication"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "2.2 Checking MFA configuration..."

POLICY=$(a0_get "/guardian/policies") || {
  fail "2.2 Unable to retrieve MFA policies"
  increment_failed; summary; exit 0
}

CURRENT_POLICY=$(echo "${POLICY}" | jq -r '.[]' 2>/dev/null || echo "never")

if [ "${CURRENT_POLICY}" = "all-applications" ]; then
  pass "2.2 MFA is enforced for all applications"
else
  info "2.2 Current MFA policy: ${CURRENT_POLICY}"
fi

# HTH Guide Excerpt: begin api-enable-mfa
# Set MFA policy to all-applications and enable OTP + WebAuthn
info "2.2 Setting MFA policy to 'all-applications'..."
a0_put "/guardian/policies" '["all-applications"]' || {
  fail "2.2 Failed to set MFA policy"
  increment_failed; summary; exit 0
}

info "2.2 Enabling OTP factor..."
a0_put "/guardian/factors/otp" '{"enabled": true}' || warn "2.2 Failed to enable OTP"

info "2.2 Enabling WebAuthn (security keys)..."
a0_put "/guardian/factors/webauthn-roaming" '{"enabled": true}' || warn "2.2 Failed to enable WebAuthn roaming"

info "2.2 Enabling WebAuthn (biometrics)..."
a0_put "/guardian/factors/webauthn-platform" '{"enabled": true}' || warn "2.2 Failed to enable WebAuthn platform"

info "2.2 Enabling recovery codes..."
a0_put "/guardian/factors/recovery-code" '{"enabled": true}' || warn "2.2 Failed to enable recovery codes"
# HTH Guide Excerpt: end api-enable-mfa

pass "2.2 MFA configured with OTP + WebAuthn"
increment_applied
summary
