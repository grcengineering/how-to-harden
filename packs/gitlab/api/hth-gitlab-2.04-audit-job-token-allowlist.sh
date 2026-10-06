#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: gitlab-2.4
#   guide:   https://howtoharden.com/guides/gitlab/#24-apply-fine-grained-cicd-job-token-permissions
#   profile: L2
#   mode:    read-only
#   requires: GITLAB_TOKEN(personal access token, read_api scope; Maintainer role on the project), PROJECT_ID
# =============================================================================
# HTH GitLab Control 2.4: Apply Fine-Grained CI/CD Job Token Permissions
# Profile: L2 | NIST: AC-6, AC-3
# https://howtoharden.com/guides/gitlab/#24-apply-fine-grained-cicd-job-token-permissions
#
# Read-only audit of the CI/CD job token allowlist (docs.gitlab.com/api/project_job_token_scopes):
#   GET /projects/:id/job_token_scope                   is the allowlist enforced?
#   GET /projects/:id/job_token_scope/allowlist         which projects are on it
#   GET /projects/:id/job_token_scope/groups_allowlist  which groups are on it
# The REST API does not return each entry's fine-grained permission scopes, so
# the pack lists every entry for review on Settings > CI/CD > Job token
# permissions, where those scopes are set.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition (a call failed).
# =============================================================================
source "$(dirname "$0")/common.sh"

PROJECT_ID="${PROJECT_ID:-${1:-}}"
: "${PROJECT_ID:?Set PROJECT_ID or pass as first argument}"

banner "2.4: Fine-Grained CI/CD Job Token Permissions (Project: ${PROJECT_ID})"
should_apply 2 || { increment_skipped; summary; exit 0; }

# Walk every page of a list endpoint; a failed page is fatal, never "empty".
gl_get_all() {
  local path="$1" page=1 all="[]" resp count
  while true; do
    resp=$(gl_get "${path}?per_page=100&page=${page}") || return 1
    count=$(printf '%s' "${resp}" | jq 'length') || return 1
    [ "${count}" -eq 0 ] && break
    all=$(printf '%s %s' "${all}" "${resp}" | jq -s 'add')
    [ "${count}" -lt 100 ] && break
    page=$((page + 1))
  done
  printf '%s' "${all}"
}

# HTH Guide Excerpt: begin api-audit-job-token-allowlist
SCOPE=$(gl_get "/projects/${PROJECT_ID}/job_token_scope") || {
  fail "2.4 Could not read the job token scope (HTTP status above; a 403 means the Maintainer role is required)"; summary; exit 2; }
ALLOW_PROJECTS=$(gl_get_all "/projects/${PROJECT_ID}/job_token_scope/allowlist") || {
  fail "2.4 Could not list the project allowlist"; summary; exit 2; }
# (Not named GROUPS: that is a read-only bash builtin, and assigning to it is silently ignored.)
ALLOW_GROUPS=$(gl_get_all "/projects/${PROJECT_ID}/job_token_scope/groups_allowlist") || {
  fail "2.4 Could not list the group allowlist"; summary; exit 2; }

INBOUND=$(printf '%s' "${SCOPE}" | jq -r '.inbound_enabled')
if [ "${INBOUND}" = "true" ]; then
  pass "2.4 CI/CD job token allowlist is enforced"
else
  fail "2.4 CI/CD job token allowlist is OFF -- a job token from any project can reach this project"
fi

# Every entry is a standing grant; review each one's permission scopes and
# remove entries with no working pipeline dependency.
info "2.4 Allowlisted projects: $(printf '%s' "${ALLOW_PROJECTS}" | jq 'length'), groups: $(printf '%s' "${ALLOW_GROUPS}" | jq 'length')"
printf '%s' "${ALLOW_PROJECTS}" | jq -r '.[] | "  - project: \(.path_with_namespace)"'
printf '%s' "${ALLOW_GROUPS}" | jq -r '.[] | "  - group:   \(.full_path // .name)"'
# HTH Guide Excerpt: end api-audit-job-token-allowlist

if [ "${INBOUND}" = "true" ]; then
  increment_applied
  summary
  exit 0
fi
increment_failed
summary
exit 1
