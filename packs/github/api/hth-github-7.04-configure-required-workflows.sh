#!/usr/bin/env bash
# HTH GitHub Control 7.04: Configure Required Workflows via Organization Rulesets
# Profile: L2 | NIST: SA-11, CM-3
# https://howtoharden.com/guides/github/#73-enforce-required-workflows-via-organization-rulesets
#
# The workflow files live in the organization's .github repository.
source "$(dirname "$0")/common.sh"

banner "7.04: Configure Required Workflows"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "7.04 Configuring required workflows for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-create-required-workflow-ruleset
# Resolve the numeric ID of the repository that holds the required workflows
WF_REPO_ID=$(gh_get "/repos/${GITHUB_ORG}/.github" | jq -r '.id') || WF_REPO_ID=""
[ -n "${WF_REPO_ID}" ] || { fail "7.04 .github repository not found"; increment_failed; summary; exit 0; }

# Create an organization ruleset that enforces required workflows
BODY=$(jq -n --argjson rid "${WF_REPO_ID}" '{
  name: "Required Security Workflows",
  enforcement: "active",
  target: "branch",
  conditions: {
    ref_name: {include: ["refs/heads/main", "refs/heads/master"], exclude: []},
    repository_name: {include: ["~ALL"], exclude: [".github"]}
  },
  rules: [{
    type: "workflows",
    parameters: {workflows: [
      {path: ".github/workflows/security-scan.yml", repository_id: $rid, ref: "refs/heads/main"},
      {path: ".github/workflows/dependency-review.yml", repository_id: $rid, ref: "refs/heads/main"}
    ]}
  }]
}')
gh_post "/orgs/${GITHUB_ORG}/rulesets" "${BODY}" >/dev/null || {
  fail "7.04 Unable to create required workflow ruleset"
  increment_failed
  summary
  exit 0
}
pass "7.04 Required workflow ruleset created"

# List existing rulesets
info "7.04 Current organization rulesets:"
gh_get "/orgs/${GITHUB_ORG}/rulesets" \
  | jq '.[] | {name: .name, enforcement: .enforcement, id: .id}'
# HTH Guide Excerpt: end api-create-required-workflow-ruleset

increment_applied
summary
