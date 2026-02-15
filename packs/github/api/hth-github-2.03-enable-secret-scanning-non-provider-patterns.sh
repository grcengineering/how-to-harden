#!/usr/bin/env bash
# HTH GitHub Control 2.03: Enable Secret Scanning Non-Provider Patterns
# Profile: L3 | NIST: IA-5, SC-28
# https://howtoharden.com/guides/github/#23-enable-secret-scanning-non-provider-patterns
source "$(dirname "$0")/common.sh"

banner "2.03: Enable Secret Scanning Non-Provider Patterns"
should_apply 3 || { increment_skipped; summary; exit 0; }

REPO="${GITHUB_REPO:-how-to-harden}"
info "2.03 Checking non-provider pattern scanning on ${GITHUB_ORG}/${REPO}..."

# Idempotency check -- verify non-provider patterns are enabled
REPO_DATA=$(gh_get "/repos/${GITHUB_ORG}/${REPO}") || {
  fail "2.03 Unable to retrieve repo settings for ${GITHUB_ORG}/${REPO}"
  increment_failed
  summary
  exit 0
}

NPP_STATUS=$(echo "${REPO_DATA}" | jq -r '.security_and_analysis.secret_scanning_non_provider_patterns.status // "disabled"')

if [ "${NPP_STATUS}" = "enabled" ]; then
  pass "2.03 Secret scanning non-provider patterns are already enabled"
  increment_applied
  summary
  exit 0
fi

warn "2.03 Non-provider patterns scanning is ${NPP_STATUS}"

# HTH Guide Excerpt: begin api-enable-non-provider-patterns
# Enable secret scanning for non-provider patterns (generic secrets, passwords, keys)
info "2.03 Enabling non-provider pattern scanning..."
RESPONSE=$(gh_patch "/repos/${GITHUB_ORG}/${REPO}" '{
  "security_and_analysis": {
    "secret_scanning_non_provider_patterns": { "status": "enabled" }
  }
}') || {
  fail "2.03 Failed to enable non-provider patterns -- may require GHAS license"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-enable-non-provider-patterns

RESULT=$(echo "${RESPONSE}" | jq -r '.security_and_analysis.secret_scanning_non_provider_patterns.status // "disabled"')
if [ "${RESULT}" = "enabled" ]; then
  pass "2.03 Secret scanning non-provider patterns enabled"
  increment_applied
else
  fail "2.03 Non-provider patterns not confirmed after update (got: ${RESULT})"
  increment_failed
fi

summary
