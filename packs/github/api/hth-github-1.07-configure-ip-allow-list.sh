#!/usr/bin/env bash
# HTH GitHub Control 1.07: Configure Enterprise IP Allow List
# Profile: L2 | NIST: AC-17, SC-7
# https://howtoharden.com/guides/github/#15-configure-enterprise-ip-allow-list
#
# The enterprise IP allow list has no REST API; it is managed through GraphQL
# (createIpAllowListEntry / updateIpAllowListEnabledSetting). This pack lists the
# entries and adds entries; it never turns the list ON. Enable the list only after
# an entry covering your own egress IP exists, or you lock yourself out.
source "$(dirname "$0")/common.sh"
: "${GITHUB_ENTERPRISE:?Set GITHUB_ENTERPRISE (your enterprise slug)}"

banner "1.07: Configure IP Allow List"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "1.07 Checking IP allow list entries for enterprise ${GITHUB_ENTERPRISE}..."

# HTH Guide Excerpt: begin api-configure-ip-allowlist
# List the enterprise IP allow list (GraphQL -- there is no REST endpoint)
ENT=$(gh api graphql -f slug="${GITHUB_ENTERPRISE}" -f query='
  query($slug: String!) {
    enterprise(slug: $slug) {
      id
      ownerInfo {
        ipAllowListEnabledSetting
        ipAllowListEntries(first: 100) {
          nodes { id allowListValue name isActive }
        }
      }
    }
  }') || {
  fail "1.07 Unable to read the IP allow list (requires an enterprise owner token)"
  increment_failed
  summary
  exit 0
}
ENT_ID=$(echo "${ENT}" | jq -r '.data.enterprise.id')
echo "${ENT}" | jq '.data.enterprise.ownerInfo'

# Add an entry (idempotent). Adding entries never enables the list itself.
add_ip_entry() {
  local name="$1" value="$2"
  if echo "${ENT}" | jq -e --arg v "${value}" \
      '.data.enterprise.ownerInfo.ipAllowListEntries.nodes[] | select(.allowListValue == $v)' >/dev/null; then
    pass "1.07 IP entry '${name}' (${value}) already exists"
    return
  fi
  gh api graphql -f owner="${ENT_ID}" -f value="${value}" -f name="${name}" -f query='
    mutation($owner: ID!, $value: String!, $name: String) {
      createIpAllowListEntry(input: {ownerId: $owner, allowListValue: $value, name: $name, isActive: true}) {
        ipAllowListEntry { id allowListValue }
      }
    }' >/dev/null || {
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
