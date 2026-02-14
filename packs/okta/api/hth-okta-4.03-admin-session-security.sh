#!/usr/bin/env bash
# HTH Okta Control 4.3: Configure Admin Session Security
# Profile: L1 | NIST: SC-23, AC-12
# https://howtoharden.com/guides/okta/#43-configure-admin-session-security
source "$(dirname "$0")/common.sh"

banner "4.3: Configure Admin Session Security"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "4.3 Configuring admin session security..."

# Check current admin session settings
info "4.3 Checking admin session ASN and IP binding..."
ORG_SETTINGS=$(okta_get "/api/v1/org/settings" 2>/dev/null || echo "{}")

ASN_BINDING=$(echo "${ORG_SETTINGS}" | jq -r '.adminSessionASNBinding // "unknown"' 2>/dev/null || echo "unknown")
IP_BINDING=$(echo "${ORG_SETTINGS}" | jq -r '.adminSessionIPBinding // "unknown"' 2>/dev/null || echo "unknown")

info "4.3 Current ASN binding: ${ASN_BINDING}"
info "4.3 Current IP binding: ${IP_BINDING}"

# Determine target settings
asn_target="ENABLED"
ip_target="${IP_BINDING}"

if [ "${HTH_PROFILE_LEVEL}" -ge 2 ]; then
  ip_target="ENABLED"
fi

# Update if needed
if [ "${ASN_BINDING}" = "ENABLED" ] && { [ "${HTH_PROFILE_LEVEL}" -lt 2 ] || [ "${IP_BINDING}" = "ENABLED" ]; }; then
  pass "4.3 Admin session binding already configured correctly"
  increment_applied
  summary
  exit 0
fi

info "4.3 Updating admin session binding settings..."
okta_put "/api/v1/org/settings" "{
  \"adminSessionASNBinding\": \"${asn_target}\",
  \"adminSessionIPBinding\": \"${ip_target}\"
}" > /dev/null 2>&1 && {
  pass "4.3 Admin session security updated (ASN: ${asn_target}, IP: ${ip_target})"
  increment_applied
} || {
  fail "4.3 Failed to update admin session settings"
  increment_failed
}

info "4.3 Additionally, enable Protected Actions via: Security > General > Protected Actions"

summary
