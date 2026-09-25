#!/usr/bin/env bash
# HTH GitHub Control 3.16: Workflow Approval for First-Time Contributors
# Profile: L2 | SLSA: Build L2
# https://howtoharden.com/guides/github/#33-require-workflow-approval-for-first-time-contributors
source "$(dirname "$0")/common.sh"

banner "3.16: Fork PR Workflow Approval"
should_apply 2 || { increment_skipped; summary; exit 0; }
REPO="${GITHUB_REPO:?Set GITHUB_REPO (repository to harden)}"

# HTH Guide Excerpt: begin api-workflow-approval-contributors
# Read the fork pull request approval policy for the repository
CUR=$(gh_get "/repos/${GITHUB_ORG}/${REPO}/actions/permissions/fork-pr-contributor-approval" \
  | jq -r '.approval_policy') || {
  fail "3.16 Unable to read the fork PR approval policy"
  increment_failed
  summary
  exit 0
}
echo "approval_policy: ${CUR}"

# Require approval for first-time contributors (L3: all_external_contributors)
case "${CUR}" in
  first_time_contributors|all_external_contributors) ;;
  *) gh_put "/repos/${GITHUB_ORG}/${REPO}/actions/permissions/fork-pr-contributor-approval" \
       '{"approval_policy":"first_time_contributors"}' >/dev/null || {
       fail "3.16 Unable to update the fork PR approval policy"
       increment_failed
       summary
       exit 0
     } ;;
esac
# HTH Guide Excerpt: end api-workflow-approval-contributors

pass "3.16 Fork pull request workflows require approval"
increment_applied
summary
