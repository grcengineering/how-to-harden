#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: okta-1.3
#   guide:   https://howtoharden.com/guides/okta/#13-enable-hardware-bound-session-tokens
#   profile: L2
#   mode:    read-only
#   requires: OKTA_DOMAIN, OKTA_API_TOKEN(SSWS token owned by a Read-only Administrator), HTH_PROFILE_LEVEL(optional)
# HTH Okta Control 1.3: Enable Hardware-Bound Session Tokens
# Profile: L2 | NIST: SC-23, IA-11
# https://howtoharden.com/guides/okta/#13-enable-hardware-bound-session-tokens
#
# Read-only audit. A token owned by a Read-Only Administrator is sufficient.
# Checks (Okta Management API): the Okta Verify authenticator's
# settings.userVerification (AuthenticatorKeyOktaVerify), and app sign-in
# (ACCESS_POLICY) rules that require a registered or assured device
# (conditions.device, DeviceAccessPolicyRuleCondition).
source "$(dirname "$0")/common.sh"

banner "1.3: Enable Hardware-Bound Session Tokens"

should_apply 2 || { increment_skipped; summary; exit 0; }
info "1.3 Auditing Okta Verify (FastPass) and device-bound sign-in rules..."

findings=0

# HTH Guide Excerpt: begin api-check-okta-verify
# Okta Verify must be active and require user verification (biometric or PIN)
OKTA_VERIFY=$(okta_get "/api/v1/authenticators" | jq -c '[.[] | select(.key == "okta_verify")][0] // {}')
OV_STATUS=$(printf '%s' "${OKTA_VERIFY}" | jq -r '.status // "ABSENT"')
OV_UV=$(printf '%s' "${OKTA_VERIFY}" | jq -r '.settings.userVerification // "unset"')
# HTH Guide Excerpt: end api-check-okta-verify

if [ "${OV_STATUS}" = "ACTIVE" ] && [ "${OV_UV}" = "REQUIRED" ]; then
  pass "1.3 Okta Verify is active with user verification REQUIRED"
else
  warn "1.3 Okta Verify status=${OV_STATUS}, userVerification=${OV_UV} (want ACTIVE / REQUIRED)"
  findings=$((findings + 1))
fi

# HTH Guide Excerpt: begin api-check-device-rules
# App sign-in rules that allow access only from a registered/managed/assured device
DEVICE_RULES=0
for POLICY_ID in $(okta_get "/api/v1/policies?type=ACCESS_POLICY" | jq -r '.[].id'); do
  COUNT=$(okta_get "/api/v1/policies/${POLICY_ID}/rules" | jq '[.[]
    | select(.status == "ACTIVE" and .actions.appSignOn.access == "ALLOW")
    | select(.conditions.device.registered == true
             or ((.conditions.device.assurance.include // []) | length > 0))] | length')
  DEVICE_RULES=$((DEVICE_RULES + COUNT))
done
# HTH Guide Excerpt: end api-check-device-rules

if [ "${DEVICE_RULES}" -gt 0 ]; then
  pass "1.3 ${DEVICE_RULES} active app sign-in rule(s) require a registered or assured device"
else
  warn "1.3 No app sign-in rule requires a registered or assured device"
  findings=$((findings + 1))
fi

if [ "${findings}" -gt 0 ]; then
  warn "1.3 ${findings} gap(s) found -- see Section 1.3 ClickOps steps"
fi
increment_applied

summary
