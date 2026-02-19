#!/usr/bin/env bash
# HTH GitHub Control 2.05: Configure Repository Rulesets
# Profile: L2 | NIST: CM-3
# https://howtoharden.com/guides/github/#23-configure-repository-rulesets
source "$(dirname "$0")/common.sh"

banner "2.05: Configure Organization Rulesets"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "2.05 Checking organization rulesets for ${GITHUB_ORG}..."

# Idempotency check -- list existing rulesets first
EXISTING=$(gh_get "/orgs/${GITHUB_ORG}/rulesets") || {
  fail "2.05 Unable to retrieve rulesets (may require admin permissions)"
  increment_failed
  summary
  exit 0
}

EXISTING_NAMES=$(echo "${EXISTING}" | jq -r '.[].name')
if echo "${EXISTING_NAMES}" | grep -q "Production Branch Protection"; then
  pass "2.05 'Production Branch Protection' ruleset already exists"
  increment_applied
  summary
  exit 0
fi

# HTH Guide Excerpt: begin api-create-ruleset
# Create organization ruleset via API
info "2.05 Creating production branch protection ruleset..."
RESPONSE=$(gh_post "/orgs/${GITHUB_ORG}/rulesets" '{
  "name": "Production Branch Protection",
  "enforcement": "active",
  "target": "branch",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main", "refs/heads/master", "refs/heads/release/*"],
      "exclude": []
    }
  },
  "rules": [
    {"type": "deletion"},
    {"type": "non_fast_forward"},
    {"type": "pull_request", "parameters": {"required_approving_review_count": 2, "dismiss_stale_reviews_on_push": true, "require_code_owner_review": true}},
    {"type": "required_signatures"}
  ]
}') || {
  fail "2.05 Failed to create ruleset -- may already exist or require admin permissions"
  increment_failed
  summary
  exit 0
}

# List existing rulesets
info "2.05 Current rulesets:"
gh_get "/orgs/${GITHUB_ORG}/rulesets" \
  | jq '.[] | {name: .name, enforcement: .enforcement}'
# HTH Guide Excerpt: end api-create-ruleset

RULESET_ID=$(echo "${RESPONSE}" | jq -r '.id // empty')
if [ -n "${RULESET_ID}" ]; then
  pass "2.05 Ruleset created with id ${RULESET_ID}"
  increment_applied
else
  fail "2.05 Ruleset creation response did not contain an id"
  increment_failed
fi

summary
