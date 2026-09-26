#!/usr/bin/env bash
# HTH GitHub Control 3.31: Restrict Default GITHUB_TOKEN Permissions
# Profile: L1 | NIST: AC-6, CM-7
# https://howtoharden.com/guides/github/#32-use-least-privilege-workflow-permissions
source "$(dirname "$0")/common.sh"

banner "3.31: Restrict Default GITHUB_TOKEN Permissions"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "3.31 Checking default workflow permissions for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-restrict-workflow-token-permissions
# Read the organization's default GITHUB_TOKEN permissions
CUR=$(gh_get "/orgs/${GITHUB_ORG}/actions/permissions/workflow") || {
  fail "3.31 Unable to read default workflow permissions (requires org admin)"
  increment_failed
  summary
  exit 0
}
echo "${CUR}" | jq '{default_workflow_permissions, can_approve_pull_request_reviews}'

# Read-only by default, and Actions may not create or approve pull requests
if [ "$(echo "${CUR}" | jq -r '.default_workflow_permissions')" != "read" ] \
  || [ "$(echo "${CUR}" | jq -r '.can_approve_pull_request_reviews')" != "false" ]; then
  gh_put "/orgs/${GITHUB_ORG}/actions/permissions/workflow" \
    '{"default_workflow_permissions":"read","can_approve_pull_request_reviews":false}' || {
    fail "3.31 Unable to update default workflow permissions"
    increment_failed
    summary
    exit 0
  }
fi
# HTH Guide Excerpt: end api-restrict-workflow-token-permissions

pass "3.31 Default GITHUB_TOKEN is read-only and cannot approve pull requests"
increment_applied
summary
