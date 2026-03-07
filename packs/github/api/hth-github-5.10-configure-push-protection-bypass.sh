#!/usr/bin/env bash
# HTH GitHub Control 5.10: Configure Push Protection Delegated Bypass
# Profile: L2 | NIST: IA-5, CM-3
# https://howtoharden.com/guides/github/#53-configure-push-protection-delegated-bypass
source "$(dirname "$0")/common.sh"

banner "5.10: Configure Push Protection Delegated Bypass"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "5.10 Configuring push protection delegated bypass for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-list-bypass-requests
# List push protection bypass requests for the organization
info "5.10 Listing push protection bypass requests..."
REPOS=$(gh_get "/orgs/${GITHUB_ORG}/repos?per_page=100&type=all") || {
  fail "5.10 Unable to list repositories"
  increment_failed
  summary
  exit 0
}

echo "${REPOS}" | jq -r '.[].name' | while read -r REPO; do
  BYPASSES=$(gh_get "/repos/${GITHUB_ORG}/${REPO}/secret-scanning/push-protection-bypasses?per_page=10" 2>/dev/null) || continue
  COUNT=$(echo "${BYPASSES}" | jq 'length' 2>/dev/null || echo "0")
  if [ "${COUNT}" -gt 0 ]; then
    warn "5.10 ${REPO}: ${COUNT} push protection bypass(es) found"
    echo "${BYPASSES}" | jq '.[] | {placeholder_id: .placeholder_id, reason: .reason, actor: .actor.login, created_at: .created_at}'
  fi
done
# HTH Guide Excerpt: end api-list-bypass-requests

# HTH Guide Excerpt: begin api-configure-delegated-bypass
# Configure delegated bypass via organization ruleset
# This requires the push protection bypass to be routed to designated reviewers
info "5.10 Creating ruleset with delegated bypass configuration..."
RESPONSE=$(gh_post "/orgs/${GITHUB_ORG}/rulesets" '{
  "name": "Secret Scanning Push Protection",
  "enforcement": "active",
  "target": "branch",
  "conditions": {
    "ref_name": {
      "include": ["~ALL"],
      "exclude": []
    }
  },
  "bypass_actors": [
    {
      "actor_id": 1,
      "actor_type": "OrganizationAdmin",
      "bypass_mode": "always"
    }
  ],
  "rules": [
    {
      "type": "secret_scanning"
    }
  ]
}') || {
  warn "5.10 Unable to create push protection ruleset (may already exist)"
}
# HTH Guide Excerpt: end api-configure-delegated-bypass

increment_applied
summary
