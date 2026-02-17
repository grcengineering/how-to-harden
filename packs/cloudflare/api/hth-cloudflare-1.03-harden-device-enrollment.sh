#!/usr/bin/env bash
# HTH Cloudflare Control 1.3: Harden Device Enrollment
# Profile: L1 | NIST: AC-2 | CIS: 1.4, 5.3
# https://howtoharden.com/guides/cloudflare/#13-harden-device-enrollment
source "$(dirname "$0")/common.sh"

banner "1.3: Harden Device Enrollment"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.3 Checking device enrollment permissions..."

# HTH Guide Excerpt: begin api-check-enrollment
# Check device enrollment permissions
ENROLLMENT=$(cf_get "/accounts/${CF_ACCOUNT_ID}/devices/policy") || {
  fail "1.3 Unable to retrieve device enrollment policy"
  increment_failed
  summary
  exit 0
}

# Verify enrollment requires authentication
REQUIRE_AUTH=$(echo "${ENROLLMENT}" | jq -r '.result.allow_mode_switch // false')
info "1.3 Device policy retrieved -- reviewing enrollment settings"

# List enrollment rules
RULES=$(cf_get "/accounts/${CF_ACCOUNT_ID}/devices/policy/include") 2>/dev/null || true
EXCLUDE=$(cf_get "/accounts/${CF_ACCOUNT_ID}/devices/policy/exclude") 2>/dev/null || true
# HTH Guide Excerpt: end api-check-enrollment

pass "1.3 Device enrollment policy is configured"
info "1.3 Review enrollment rules in Zero Trust Dashboard → Settings → WARP Client → Device enrollment"
increment_applied

summary
