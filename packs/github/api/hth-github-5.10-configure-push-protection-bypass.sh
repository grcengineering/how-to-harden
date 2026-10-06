#!/usr/bin/env bash
# HTH GitHub Control 5.10: Configure Push Protection Delegated Bypass
# Profile: L2 | NIST: IA-5, CM-3
# https://howtoharden.com/guides/github/#53-configure-push-protection-with-delegated-bypass
#
# Usage: bash <pack>                      -> list bypass requests (read-only)
#        SECURITY_TEAM_ID=<id> bash <pack> -> also create a security configuration with
#                                            push protection + delegated bypass
source "$(dirname "$0")/common.sh"

banner "5.10: Configure Push Protection Delegated Bypass"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "5.10 Reviewing push protection bypass requests for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-list-bypass-requests
# List push protection bypass requests for the organization
gh_get "/orgs/${GITHUB_ORG}/bypass-requests/secret-scanning?per_page=100" \
  | jq '.[] | {repository: .repository.full_name, requester: .requester.actor_name, status, created_at}' || {
  fail "5.10 Unable to list bypass requests (requires delegated bypass and the bypass-requests read permission)"
  increment_failed
}
# HTH Guide Excerpt: end api-list-bypass-requests

# HTH Guide Excerpt: begin api-configure-delegated-bypass
# Push protection whose bypasses must be approved by the security team
if [ -n "${SECURITY_TEAM_ID:-}" ]; then
  BODY=$(jq -n --argjson team "${SECURITY_TEAM_ID}" '{
    name: "HTH push protection with delegated bypass",
    description: "Push protection; bypass requires security-team review",
    secret_scanning: "enabled",
    secret_scanning_push_protection: "enabled",
    secret_scanning_delegated_bypass: "enabled",
    secret_scanning_delegated_bypass_options: {reviewers: [{reviewer_id: $team, reviewer_type: "TEAM"}]}
  }')
  if gh_post "/orgs/${GITHUB_ORG}/code-security/configurations" "${BODY}" >/dev/null; then
    pass "5.10 Security configuration with delegated bypass created (attach it to repositories next)"
  else
    fail "5.10 Unable to create the security configuration"
    increment_failed
  fi
fi
# HTH Guide Excerpt: end api-configure-delegated-bypass

if [ "${CONTROLS_FAILED}" -eq 0 ]; then
  increment_applied
fi
summary
