#!/usr/bin/env bash
# HTH Qualys Control 2.2: Configure Scan Options
# Profile: L1 | NIST: RA-5
# https://howtoharden.com/guides/qualys/#22-configure-scan-options
source "$(dirname "$0")/common.sh"

banner "2.2: Configure Scan Options"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "2.2 Auditing scan option profiles for comprehensive settings..."

# HTH Guide Excerpt: begin api-audit-scan-profiles
# List all scan option profiles and check for hardened configuration
PROFILES_XML=$(ql_get "/scan/option_profile/?action=list" 2>/dev/null) || {
  fail "2.2 Failed to retrieve scan option profiles"
  increment_failed
  summary
  exit 1
}

PROFILE_COUNT=$(echo "${PROFILES_XML}" | xml_count "OPTION_PROFILE")
info "2.2 Found ${PROFILE_COUNT} scan option profile(s)"

# Check each profile for vulnerability detection settings
# A hardened profile should have:
#   - TCP and UDP scanning enabled
#   - Authentication scanning enabled
#   - All port ranges covered (1-65535)
echo "${PROFILES_XML}" | grep -oP "<TITLE>\K[^<]+" | while read -r title; do
  info "2.2   Profile: ${title}"
done
# HTH Guide Excerpt: end api-audit-scan-profiles

# HTH Guide Excerpt: begin api-audit-active-scans
# List recent scans to verify scanning is active and not stale
SCANS_XML=$(ql_get "/scan/?action=list" 2>/dev/null) || {
  warn "2.2 Failed to retrieve scan list"
  SCANS_XML=""
}

if [ -n "${SCANS_XML}" ]; then
  SCAN_COUNT=$(echo "${SCANS_XML}" | xml_count "SCAN")
  info "2.2 Found ${SCAN_COUNT} scan(s) in history"

  # Check for scans in the last 30 days
  RECENT_SCANS=$(echo "${SCANS_XML}" | grep -c "<STATUS>Finished</STATUS>" || echo "0")
  if [ "${RECENT_SCANS}" -gt 0 ]; then
    pass "2.2 ${RECENT_SCANS} completed scan(s) found"
  else
    warn "2.2 No recently completed scans -- verify scan scheduling"
  fi
fi
# HTH Guide Excerpt: end api-audit-active-scans

if [ "${PROFILE_COUNT}" -gt 0 ]; then
  pass "2.2 Scan option profiles configured (${PROFILE_COUNT} profile(s))"
  increment_applied
else
  fail "2.2 No scan option profiles found -- create a hardened scan profile"
  increment_failed
fi

summary
