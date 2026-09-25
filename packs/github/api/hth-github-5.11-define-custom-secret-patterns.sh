#!/usr/bin/env bash
# HTH GitHub Control 5.11: Define Custom Secret Scanning Patterns
# Profile: L2 | NIST: IA-5, SI-4
# https://howtoharden.com/guides/github/#54-define-custom-secret-scanning-patterns
source "$(dirname "$0")/common.sh"

banner "5.11: Define Custom Secret Scanning Patterns"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "5.11 Managing custom secret scanning patterns for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-list-custom-patterns
# List existing custom secret scanning patterns for the organization
info "5.11 Listing custom secret scanning patterns..."
PATTERNS=$(gh_get "/orgs/${GITHUB_ORG}/secret-scanning/custom-patterns") || {
  fail "5.11 Unable to list custom patterns (requires GitHub Secret Protection)"
  increment_failed
  summary
  exit 0
}
echo "${PATTERNS}" | jq '.[] | {name, pattern, state, push_protection_enabled}'
# HTH Guide Excerpt: end api-list-custom-patterns

# HTH Guide Excerpt: begin api-create-custom-pattern
# Create a custom secret scanning pattern for internal API keys
info "5.11 Creating custom secret scanning pattern..."
# The endpoint bulk-creates: the body is {"patterns": [ ... ]}
if gh_post "/orgs/${GITHUB_ORG}/secret-scanning/custom-patterns" '{
  "patterns": [
    {"name": "Internal API Key", "pattern": "internal_api_key_[a-zA-Z0-9]{32}"}
  ]
}' >/dev/null; then
  pass "5.11 Custom secret scanning pattern created"
else
  fail "5.11 Unable to create custom pattern (requires GitHub Secret Protection)"
  increment_failed
fi
# HTH Guide Excerpt: end api-create-custom-pattern

increment_applied
summary
