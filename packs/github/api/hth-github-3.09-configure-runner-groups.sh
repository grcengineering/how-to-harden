#!/usr/bin/env bash
# HTH GitHub Control 3.09: Configure Self-Hosted Runner Security
# Profile: L2 | NIST: CM-6
# https://howtoharden.com/guides/github/#34-configure-self-hosted-runner-security
source "$(dirname "$0")/common.sh"

banner "3.09: Configure Runner Groups"
should_apply 2 || { increment_skipped; summary; exit 0; }

# HTH Guide Excerpt: begin api-configure-runners
# List runner groups
info "3.09 Listing runner groups for ${GITHUB_ORG}..."
GROUPS=$(gh_get "/orgs/${GITHUB_ORG}/actions/runner-groups") || {
  fail "3.09 Unable to retrieve runner groups"
  increment_failed
  summary
  exit 0
}
echo "${GROUPS}" | jq '.runner_groups[] | {name: .name, id: .id, visibility: .visibility}'

# Create a runner group with restricted repository access
info "3.09 Creating production runner group..."
gh_post "/orgs/${GITHUB_ORG}/actions/runner-groups" '{
  "name": "production-runners",
  "visibility": "selected",
  "allows_public_repositories": false
}' || {
  warn "3.09 Failed to create runner group -- may already exist"
}

# List runners in a group
GROUP_ID=$(echo "${GROUPS}" | jq -r '.runner_groups[] | select(.name == "production-runners") | .id')
if [ -n "${GROUP_ID}" ]; then
  gh_get "/orgs/${GITHUB_ORG}/actions/runner-groups/${GROUP_ID}/runners" \
    | jq '.runners[] | {name: .name, status: .status}'
fi
# HTH Guide Excerpt: end api-configure-runners

pass "3.09 Runner group configuration complete"
increment_applied

summary
