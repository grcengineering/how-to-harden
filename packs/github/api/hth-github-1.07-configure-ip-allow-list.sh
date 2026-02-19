#!/usr/bin/env bash
# HTH GitHub Control 1.07: Configure Enterprise IP Allow List
# Profile: L2 | NIST: AC-17, SC-7
# https://howtoharden.com/guides/github/#15-configure-enterprise-ip-allow-list
source "$(dirname "$0")/common.sh"

banner "1.07: Configure IP Allow List"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "1.07 Checking IP allow list entries for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-configure-ip-allowlist
# List current IP allow list entries
info "1.07 Listing IP allow list entries for ${GITHUB_ORG}..."
ENTRIES=$(gh_get "/orgs/${GITHUB_ORG}/ip-allow-list") || {
  fail "1.07 Unable to retrieve IP allow list"
  increment_failed
  summary
  exit 0
}
echo "${ENTRIES}" | jq '.[] | {name: .name, value: .value, is_active: .is_active}'

# Add IP range (idempotent — checks if already exists)
add_ip_entry() {
  local name="$1" value="$2"
  local existing
  existing=$(echo "${ENTRIES}" | jq -r --arg v "${value}" '.[] | select(.value == $v) | .id')
  if [ -n "${existing}" ]; then
    pass "1.07 IP entry '${name}' (${value}) already exists"
    return
  fi
  gh_post "/orgs/${GITHUB_ORG}/ip-allow-list" "{
    \"name\": \"${name}\",
    \"value\": \"${value}\",
    \"is_active\": true
  }" || {
    fail "1.07 Failed to add IP entry '${name}' (${value})"
    return
  }
  pass "1.07 Added IP entry '${name}' (${value})"
}
# HTH Guide Excerpt: end api-configure-ip-allowlist

# Apply env-var-driven IP entries if provided
if [ -n "${CORPORATE_CIDR:-}" ]; then
  add_ip_entry "Corporate Network" "${CORPORATE_CIDR}"
fi
if [ -n "${RUNNER_CIDR:-}" ]; then
  add_ip_entry "GitHub Actions Runners" "${RUNNER_CIDR}"
fi

increment_applied
summary
