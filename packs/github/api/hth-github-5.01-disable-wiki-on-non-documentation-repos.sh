#!/usr/bin/env bash
# HTH GitHub Control 5.01: Disable Wiki on Non-Documentation Repos
# Profile: L2 | NIST: CM-7
# https://howtoharden.com/guides/github/#51-disable-wiki-on-non-documentation-repos
source "$(dirname "$0")/common.sh"

banner "5.01: Disable Wiki on Non-Documentation Repos"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "5.01 Auditing wiki settings across ${GITHUB_ORG} repositories..."

# If a specific repo is set, only check that repo
if [ -n "${GITHUB_REPO}" ]; then
  REPO="${GITHUB_REPO}"
  REPO_DATA=$(gh_get "/repos/${GITHUB_ORG}/${REPO}") || {
    fail "5.01 Unable to retrieve repo settings for ${GITHUB_ORG}/${REPO}"
    increment_failed
    summary
    exit 0
  }

  HAS_WIKI=$(echo "${REPO_DATA}" | jq -r '.has_wiki // false')

  if [ "${HAS_WIKI}" = "false" ]; then
    pass "5.01 Wiki is already disabled on ${REPO}"
    increment_applied
    summary
    exit 0
  fi

  warn "5.01 Wiki is enabled on ${REPO}"

  # HTH Guide Excerpt: begin api-disable-wiki
  # Disable wiki on the repository
  info "5.01 Disabling wiki on ${REPO}..."
  RESPONSE=$(gh_patch "/repos/${GITHUB_ORG}/${REPO}" '{
    "has_wiki": false
  }') || {
    fail "5.01 Failed to disable wiki on ${REPO}"
    increment_failed
    summary
    exit 0
  }
  # HTH Guide Excerpt: end api-disable-wiki

  RESULT=$(echo "${RESPONSE}" | jq -r '.has_wiki // true')
  if [ "${RESULT}" = "false" ]; then
    pass "5.01 Wiki disabled on ${REPO}"
    increment_applied
  else
    fail "5.01 Wiki not confirmed as disabled on ${REPO}"
    increment_failed
  fi

  summary
  exit 0
fi

# Org-wide: find all repos with wikis enabled
REPOS_WITH_WIKI=$(gh_get "/orgs/${GITHUB_ORG}/repos?per_page=100" \
  | jq -r '.[] | select(.has_wiki == true) | .name' 2>/dev/null) || {
  fail "5.01 Unable to list org repositories"
  increment_failed
  summary
  exit 0
}

WIKI_COUNT=$(echo "${REPOS_WITH_WIKI}" | grep -c . 2>/dev/null || echo "0")

if [ "${WIKI_COUNT}" = "0" ]; then
  pass "5.01 No repositories have wikis enabled"
  increment_applied
  summary
  exit 0
fi

warn "5.01 ${WIKI_COUNT} repository(ies) have wikis enabled"

# HTH Guide Excerpt: begin api-disable-wiki-bulk
# Disable wiki on all repositories that have it enabled
for REPO_NAME in ${REPOS_WITH_WIKI}; do
  info "5.01 Disabling wiki on ${REPO_NAME}..."
  gh_patch "/repos/${GITHUB_ORG}/${REPO_NAME}" '{"has_wiki": false}' > /dev/null 2>&1 && {
    pass "5.01 Wiki disabled on ${REPO_NAME}"
  } || {
    warn "5.01 Failed to disable wiki on ${REPO_NAME}"
  }
done
# HTH Guide Excerpt: end api-disable-wiki-bulk

increment_applied
summary
