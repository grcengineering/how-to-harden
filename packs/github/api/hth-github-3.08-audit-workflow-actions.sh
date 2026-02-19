#!/usr/bin/env bash
# HTH GitHub Control 3.08: Audit Unapproved Workflow Actions
# Profile: L2 | NIST: SA-12
# https://howtoharden.com/guides/github/#31-restrict-third-party-github-actions
source "$(dirname "$0")/common.sh"

banner "3.08: Audit Workflow Actions"
should_apply 2 || { increment_skipped; summary; exit 0; }

# HTH Guide Excerpt: begin api-audit-actions
# Scan all org repos for non-allowed actions
info "3.08 Scanning org workflows for unapproved actions..."
REPOS=$(gh_get "/orgs/${GITHUB_ORG}/repos?per_page=100" | jq -r '.[].name') || {
  fail "3.08 Unable to list repositories"
  increment_failed
  summary
  exit 0
}

for repo in ${REPOS}; do
  WORKFLOWS=$(gh_get "/repos/${GITHUB_ORG}/${repo}/actions/workflows" \
    | jq -r '.workflows[].path' 2>/dev/null) || continue
  for workflow in ${WORKFLOWS}; do
    CONTENT=$(gh_get "/repos/${GITHUB_ORG}/${repo}/contents/${workflow}" \
      | jq -r '.content' 2>/dev/null | base64 -d 2>/dev/null) || continue
    UNAPPROVED=$(echo "${CONTENT}" | grep -oP 'uses:\s+\K[^\s]+' \
      | grep -v '^actions/' | grep -v '^github/' || true)
    if [ -n "${UNAPPROVED}" ]; then
      warn "3.08 ${repo}/${workflow}: ${UNAPPROVED}"
    fi
  done
done
# HTH Guide Excerpt: end api-audit-actions

pass "3.08 Workflow action audit complete"
increment_applied

summary
