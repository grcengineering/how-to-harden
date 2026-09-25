#!/usr/bin/env bash
# HTH GitHub Control 3.32: Restrict Who and What Can Trigger Workflows (Actions policies)
# Profile: L2 | NIST: AC-3, CM-7
# https://howtoharden.com/guides/github/#315-restrict-who-and-what-can-trigger-workflows
#
# Creates an Actions policy in EVALUATE mode (GitHub Enterprise Cloud): nothing is
# blocked; would-be blocks appear in Policy insights. Edit allowed_events to the
# events your repositories actually need before switching enforcement to "active".
# Revert: DELETE /orgs/{org}/actions/policies/{policy_id} (id printed below).
source "$(dirname "$0")/common.sh"

banner "3.32: Workflow Execution Policy"
should_apply 2 || { increment_skipped; summary; exit 0; }

# HTH Guide Excerpt: begin api-workflow-execution-policy
# List existing Actions policies
EXISTING=$(gh_get "/orgs/${GITHUB_ORG}/actions/policies") || {
  fail "3.32 Unable to list Actions policies (requires org admin)"
  increment_failed
  summary
  exit 0
}
echo "${EXISTING}" | jq '.'

# Create an evaluate-mode policy that allows only push and pull_request events
POLICY=$(gh_post "/orgs/${GITHUB_ORG}/actions/policies" '{
  "name": "hth-3.15-restrict-events",
  "enforcement": "evaluate",
  "conditions": {
    "repository_name": {"include": ["~ALL"], "exclude": []}
  },
  "rules": [
    {
      "type": "restrict_action_events",
      "parameters": {"allowed_events": ["push", "pull_request"]}
    }
  ]
}') || {
  fail "3.32 Unable to create the Actions policy (evaluate mode needs Enterprise Cloud)"
  increment_failed
  summary
  exit 0
}
echo "Created policy id: $(echo "${POLICY}" | jq -r '.id')"
# HTH Guide Excerpt: end api-workflow-execution-policy

pass "3.32 Evaluate-mode Actions policy created"
increment_applied
summary
