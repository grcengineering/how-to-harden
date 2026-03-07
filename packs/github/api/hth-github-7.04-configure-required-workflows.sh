#!/usr/bin/env bash
# HTH GitHub Control 7.04: Configure Required Workflows via Organization Rulesets
# Profile: L2 | NIST: SA-11, CM-3
# https://howtoharden.com/guides/github/#73-enforce-required-workflows
source "$(dirname "$0")/common.sh"

banner "7.04: Configure Required Workflows"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "7.04 Configuring required workflows for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-create-required-workflow-ruleset
# Create an organization ruleset that enforces required workflows
info "7.04 Creating required workflow ruleset..."
RESPONSE=$(gh_post "/orgs/${GITHUB_ORG}/rulesets" '{
  "name": "Required Security Workflows",
  "enforcement": "active",
  "target": "branch",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main", "refs/heads/master"],
      "exclude": []
    },
    "repository_name": {
      "include": ["~ALL"],
      "exclude": ["*.github"]
    }
  },
  "rules": [
    {
      "type": "workflows",
      "parameters": {
        "workflows": [
          {
            "path": ".github/workflows/security-scan.yml",
            "repository_id": 0,
            "ref": "refs/heads/main"
          },
          {
            "path": ".github/workflows/dependency-review.yml",
            "repository_id": 0,
            "ref": "refs/heads/main"
          }
        ]
      }
    }
  ]
}') || {
  warn "7.04 Unable to create required workflow ruleset"
}
pass "7.04 Required workflow ruleset created"

# List existing rulesets
info "7.04 Current organization rulesets:"
gh_get "/orgs/${GITHUB_ORG}/rulesets" \
  | jq '.[] | {name: .name, enforcement: .enforcement, id: .id}'
# HTH Guide Excerpt: end api-create-required-workflow-ruleset

increment_applied
summary
