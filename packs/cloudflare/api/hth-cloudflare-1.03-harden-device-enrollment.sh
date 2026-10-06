#!/usr/bin/env bash
# HTH Cloudflare Control 1.3: Harden Device Enrollment
# Profile: L1 | NIST: AC-2 | CIS: 1.4, 5.3
# https://howtoharden.com/guides/cloudflare/#13-harden-device-enrollment
#
# Read-only audit. Device enrollment permissions are an Access application of
# type "warp"; who may enroll is decided by that application's Access
# policies. The pack fails when there is no enrollment application, when it has
# no policies, or when an Allow policy includes Everyone.
source "$(dirname "$0")/common.sh"

banner "1.3: Harden Device Enrollment"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.3 Checking device enrollment permissions..."

# HTH Guide Excerpt: begin api-check-enrollment
# Find the device enrollment application (type "warp") and audit its policies
APPS=$(cf_get_all "/accounts/${CF_ACCOUNT_ID}/access/apps") || {
  fail "1.3 Unable to retrieve Access applications"
  increment_failed
  summary
  exit 0
}

WARP_APP=$(echo "${APPS}" | jq -r '[.result[] | select(.type == "warp")][0].id // empty')
if [ -z "${WARP_APP}" ]; then
  fail "1.3 No device enrollment permissions configured (no Access application of type warp)"
  increment_failed
  summary
  exit 0
fi

POLICIES=$(cf_get_all "/accounts/${CF_ACCOUNT_ID}/access/apps/${WARP_APP}/policies") || {
  fail "1.3 Unable to retrieve device enrollment policies"
  increment_failed
  summary
  exit 0
}

POLICY_COUNT=$(echo "${POLICIES}" | jq '.result | length')
OPEN_ALLOW=$(echo "${POLICIES}" | jq '[.result[] | select(.decision == "allow") | select(any(.include[]?; has("everyone")))] | length')
# HTH Guide Excerpt: end api-check-enrollment

if [ "${POLICY_COUNT}" = "0" ]; then
  fail "1.3 Device enrollment application has no policies"
  increment_failed
elif [ "${OPEN_ALLOW}" -gt 0 ]; then
  fail "1.3 ${OPEN_ALLOW} enrollment Allow policy(s) include Everyone -- any user can enroll a device"
  increment_failed
else
  pass "1.3 Device enrollment is restricted by ${POLICY_COUNT} policy(s)"
  echo "${POLICIES}" | jq -r '.result[] | "  - \(.name) (\(.decision))"'
  increment_applied
fi

summary
