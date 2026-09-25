#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: okta-1.8
#   guide:   https://howtoharden.com/guides/okta/#18-configure-fips-compliant-authenticators
#   profile: L3
#   mode:    mutating
#   requires: OKTA_DOMAIN, OKTA_API_TOKEN(SSWS token owned by a Super Administrator; edits the Okta Verify authenticator), HTH_PROFILE_LEVEL(optional)
# HTH Okta Control 1.8: Configure FIPS-Compliant Authenticators
# Profile: L3 | NIST: SC-13 | DISA STIG: V-273205
# https://howtoharden.com/guides/okta/#18-configure-fips-compliant-authenticators
#
# Sets the Okta Verify authenticator's settings.compliance.fips to REQUIRED
# (Okta Management API, Authenticator: AuthenticatorKeyOktaVerify, FipsEnum
# OPTIONAL | REQUIRED). PUT replaces the authenticator, so it is read, modified
# with jq, and written back complete. Users on non-FIPS devices can no longer
# enroll Okta Verify afterwards -- confirm device compatibility first.
source "$(dirname "$0")/common.sh"

banner "1.8: Configure FIPS-Compliant Authenticators"

should_apply 3 || { increment_skipped; summary; exit 0; }
info "1.8 Requiring FIPS-compliant devices for Okta Verify..."

# HTH Guide Excerpt: begin api-require-fips-okta-verify
OKTA_VERIFY=$(okta_get "/api/v1/authenticators" | jq -c '[.[] | select(.key == "okta_verify")][0] // empty')
if [ -z "${OKTA_VERIFY}" ]; then
  fail "1.8 Okta Verify authenticator not found"
  increment_failed
  summary
fi
OV_ID=$(printf '%s' "${OKTA_VERIFY}" | jq -r '.id')
CURRENT_FIPS=$(printf '%s' "${OKTA_VERIFY}" | jq -r '.settings.compliance.fips // "unset"')
info "1.8 Okta Verify FIPS compliance is currently: ${CURRENT_FIPS}"

if [ "${CURRENT_FIPS}" = "REQUIRED" ]; then
  pass "1.8 Okta Verify already requires FIPS-compliant devices"
  increment_applied
  summary
  exit 0
fi

UPDATED=$(printf '%s' "${OKTA_VERIFY}" | jq '.settings.compliance.fips = "REQUIRED"')
if okta_put "/api/v1/authenticators/${OV_ID}" "${UPDATED}" > /dev/null; then
  pass "1.8 Okta Verify now requires FIPS-compliant devices"
  increment_applied
else
  fail "1.8 Failed to update Okta Verify FIPS compliance"
  increment_failed
fi
# HTH Guide Excerpt: end api-require-fips-okta-verify

summary
