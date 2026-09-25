#!/usr/bin/env bash
# HTH GitHub Control 6.06: Enforce Dependency Review Across Organization
# Profile: L2 | NIST: SA-12, SA-11
# https://howtoharden.com/guides/github/#65-enforce-dependency-review-across-the-organization
#
# WORKFLOW_REPO names the repository that holds dependency-review.yml (default: .github).
source "$(dirname "$0")/common.sh"

banner "6.06: Enforce Dependency Review Across Organization"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "6.06 Enforcing dependency review via organization ruleset..."

# HTH Guide Excerpt: begin api-enforce-dependency-review
# The workflows rule needs the numeric ID of the repository holding the workflow file
WF_REPO_ID=$(gh_get "/repos/${GITHUB_ORG}/${WORKFLOW_REPO:-.github}" | jq -r '.id') || WF_REPO_ID=""
[ -n "${WF_REPO_ID}" ] || { fail "6.06 workflow repository not found"; increment_failed; summary; exit 0; }

# Create an organization ruleset that requires the dependency-review workflow
BODY=$(jq -n --argjson rid "${WF_REPO_ID}" '{
  name: "Require Dependency Review",
  enforcement: "active",
  target: "branch",
  conditions: {
    ref_name: {include: ["refs/heads/main", "refs/heads/master"], exclude: []},
    repository_name: {include: ["~ALL"], exclude: []}
  },
  rules: [{
    type: "workflows",
    parameters: {workflows: [{path: ".github/workflows/dependency-review.yml", repository_id: $rid, ref: "refs/heads/main"}]}
  }]
}')
gh_post "/orgs/${GITHUB_ORG}/rulesets" "${BODY}" >/dev/null || {
  fail "6.06 Unable to create ruleset (may already exist or require GitHub Team/Enterprise)"
  increment_failed
  summary
  exit 0
}
pass "6.06 Dependency review enforcement ruleset created"
# HTH Guide Excerpt: end api-enforce-dependency-review

increment_applied
summary
