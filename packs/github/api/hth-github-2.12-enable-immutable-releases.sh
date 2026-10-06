#!/usr/bin/env bash
# HTH GitHub Control 2.12: Enable Immutable Releases
# Profile: L2 | NIST: SI-7, CM-5
# https://howtoharden.com/guides/github/#27-enable-immutable-releases
#
# Enforces release immutability for every repository in the organization.
# Immutability applies only to releases published after it is enabled.
source "$(dirname "$0")/common.sh"

banner "2.12: Enable Immutable Releases"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "2.12 Checking immutable release policy for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-enable-immutable-releases
# Read the organization's immutable release policy (all | none | selected)
CUR=$(gh_get "/orgs/${GITHUB_ORG}/settings/immutable-releases" | jq -r '.enforced_repositories') || {
  fail "2.12 Unable to read the immutable release policy (requires org admin)"
  increment_failed
  summary
  exit 0
}
echo "enforced_repositories: ${CUR}"

# Enforce immutability for all repositories
if [ "${CUR}" != "all" ]; then
  gh_put "/orgs/${GITHUB_ORG}/settings/immutable-releases" '{"enforced_repositories":"all"}' >/dev/null || {
    fail "2.12 Unable to set the immutable release policy"
    increment_failed
    summary
    exit 0
  }
fi
# HTH Guide Excerpt: end api-enable-immutable-releases

pass "2.12 Immutable releases enforced for all repositories"
increment_applied
summary
