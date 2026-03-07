#!/usr/bin/env bash
# HTH GitHub Control 2.09: Configure Push Rules in Repository Rulesets
# Profile: L2 | NIST: CM-3, SI-7
# https://howtoharden.com/guides/github/#25-configure-push-rules-in-rulesets
source "$(dirname "$0")/common.sh"

banner "2.09: Configure Push Rules in Rulesets"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "2.09 Configuring push rules for ${GITHUB_ORG}..."

# Idempotency check -- list existing push rulesets
EXISTING=$(gh_get "/orgs/${GITHUB_ORG}/rulesets") || {
  fail "2.09 Unable to retrieve rulesets (may require admin permissions)"
  increment_failed
  summary
  exit 0
}

EXISTING_NAMES=$(echo "${EXISTING}" | jq -r '.[].name')
if echo "${EXISTING_NAMES}" | grep -q "File Protection Push Rules"; then
  pass "2.09 'File Protection Push Rules' ruleset already exists"
  increment_applied
  summary
  exit 0
fi

# HTH Guide Excerpt: begin api-create-push-rules
# Create organization push ruleset to restrict dangerous file types
info "2.09 Creating push rules ruleset..."
RESPONSE=$(gh_post "/orgs/${GITHUB_ORG}/rulesets" '{
  "name": "File Protection Push Rules",
  "enforcement": "active",
  "target": "push",
  "bypass_actors": [
    {"actor_id": 1, "actor_type": "OrganizationAdmin", "bypass_mode": "always"}
  ],
  "conditions": {
    "repository_name": {
      "include": ["~ALL"],
      "exclude": []
    }
  },
  "rules": [
    {
      "type": "file_extension_restriction",
      "parameters": {
        "restricted_file_extensions": [".exe", ".dll", ".so", ".dylib", ".bin", ".jar", ".war", ".class"]
      }
    },
    {
      "type": "max_file_size",
      "parameters": {
        "max_file_size": 10
      }
    },
    {
      "type": "file_path_restriction",
      "parameters": {
        "restricted_file_paths": [".github/workflows/**"]
      }
    }
  ]
}') || {
  fail "2.09 Failed to create push rules ruleset"
  increment_failed
  summary
  exit 0
}

# List rulesets to confirm creation
info "2.09 Current rulesets:"
gh_get "/orgs/${GITHUB_ORG}/rulesets" \
  | jq '.[] | {name: .name, enforcement: .enforcement, target: .target}'
# HTH Guide Excerpt: end api-create-push-rules

RULESET_ID=$(echo "${RESPONSE}" | jq -r '.id // empty')
if [ -n "${RULESET_ID}" ]; then
  pass "2.09 Push rules ruleset created with id ${RULESET_ID}"
  increment_applied
else
  fail "2.09 Push rules ruleset creation response did not contain an id"
  increment_failed
fi

summary
