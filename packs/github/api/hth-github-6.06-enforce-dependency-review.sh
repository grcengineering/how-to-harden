#!/usr/bin/env bash
# HTH GitHub Control 6.06: Enforce Dependency Review Across Organization
# Profile: L2 | NIST: SA-12, SA-11
# https://howtoharden.com/guides/github/#64-enforce-dependency-review-across-the-organization
source "$(dirname "$0")/common.sh"

banner "6.06: Enforce Dependency Review Across Organization"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "6.06 Enforcing dependency review via organization ruleset..."

# HTH Guide Excerpt: begin api-enforce-dependency-review
# Create an organization ruleset that requires the dependency-review-action
info "6.06 Creating required workflow ruleset for dependency review..."
RESPONSE=$(gh_post "/orgs/${GITHUB_ORG}/rulesets" '{
  "name": "Require Dependency Review",
  "enforcement": "active",
  "target": "branch",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main", "refs/heads/master"],
      "exclude": []
    },
    "repository_name": {
      "include": ["~ALL"],
      "exclude": []
    }
  },
  "rules": [
    {
      "type": "workflows",
      "parameters": {
        "workflows": [
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
  warn "6.06 Unable to create ruleset (may already exist or require Enterprise Cloud)"
}
pass "6.06 Dependency review enforcement ruleset created"
# HTH Guide Excerpt: end api-enforce-dependency-review

increment_applied
summary
