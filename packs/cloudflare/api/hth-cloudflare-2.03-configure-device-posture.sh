#!/usr/bin/env bash
# HTH Cloudflare Control 2.3: Configure Device Posture Checks
# Profile: L2 | NIST: AC-2(11) | CIS: 4.1
# https://howtoharden.com/guides/cloudflare/#23-configure-device-posture-checks
source "$(dirname "$0")/common.sh"

banner "2.3: Configure Device Posture Checks"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "2.3 Auditing device posture checks..."

# HTH Guide Excerpt: begin api-audit-posture
# List all device posture rules
POSTURE_RULES=$(cf_get "/accounts/${CF_ACCOUNT_ID}/devices/posture") || {
  fail "2.3 Unable to retrieve device posture rules"
  increment_failed
  summary
  exit 0
}

RULE_COUNT=$(echo "${POSTURE_RULES}" | jq '.result | length')
info "2.3 Found ${RULE_COUNT} device posture rule(s)"

# Check for recommended posture checks
HAS_DISK=$(echo "${POSTURE_RULES}" | jq '[.result[] | select(.type == "disk_encryption")] | length')
HAS_FW=$(echo "${POSTURE_RULES}" | jq '[.result[] | select(.type == "firewall")] | length')
HAS_OS=$(echo "${POSTURE_RULES}" | jq '[.result[] | select(.type == "os_version")] | length')

[ "${HAS_DISK}" -gt 0 ] && pass "2.3 Disk encryption check configured" || warn "2.3 No disk encryption posture check found"
[ "${HAS_FW}" -gt 0 ]   && pass "2.3 Firewall check configured"        || warn "2.3 No firewall posture check found"
[ "${HAS_OS}" -gt 0 ]   && pass "2.3 OS version check configured"       || warn "2.3 No OS version posture check found"

echo "${POSTURE_RULES}" | jq -r '.result[] | "  - \(.name) (\(.type))"'
# HTH Guide Excerpt: end api-audit-posture

increment_applied
summary
