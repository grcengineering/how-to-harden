#!/usr/bin/env bash
# HTH LaunchDarkly Control 3.2: Flag Security
# Profile: L2 | NIST: CM-7
# https://howtoharden.com/guides/launchdarkly/#32-flag-security
source "$(dirname "$0")/common.sh"

banner "3.2: Flag Security"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "3.2 Auditing flag lifecycle and client-side exposure..."

# HTH Guide Excerpt: begin api-audit-flag-security
# Check for stale flags and unrestricted client-side exposure
FLAGS=$(ld_get "/flags/${LD_PROJECT_KEY}?summary=true&limit=100") || {
  fail "3.2 Unable to retrieve flags"
  increment_failed; summary; exit 0
}

TOTAL_FLAGS=$(echo "${FLAGS}" | jq '.items | length')
TEMP_FLAGS=$(echo "${FLAGS}" | jq '[.items[] | select(.temporary == true)] | length')
CLIENT_EXPOSED=$(echo "${FLAGS}" | jq '[.items[] | select(.clientSideAvailability.usingEnvironmentId == true)] | length')
NO_MAINTAINER=$(echo "${FLAGS}" | jq '[.items[] | select(._maintainer == null and ._maintainerTeam == null)] | length')

info "3.2 Total flags: ${TOTAL_FLAGS}"
info "3.2 Temporary flags: ${TEMP_FLAGS}"
info "3.2 Client-side exposed: ${CLIENT_EXPOSED}"
info "3.2 Without maintainer: ${NO_MAINTAINER}"

if [ "${NO_MAINTAINER}" -gt 0 ]; then
  warn "3.2 ${NO_MAINTAINER} flag(s) have no assigned maintainer"
fi

if [ "${CLIENT_EXPOSED}" -gt 0 ]; then
  warn "3.2 ${CLIENT_EXPOSED} flag(s) exposed to client-side SDKs — review for sensitive data"
fi

pass "3.2 Flag security audit complete"
increment_applied
# HTH Guide Excerpt: end api-audit-flag-security

summary
