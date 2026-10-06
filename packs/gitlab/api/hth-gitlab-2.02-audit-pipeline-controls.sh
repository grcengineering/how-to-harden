#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: gitlab-2.2
#   guide:   https://howtoharden.com/guides/gitlab/#22-implement-pipeline-security-controls
#   profile: L1
#   mode:    read-only
#   requires: GITLAB_TOKEN(personal access token, read_api scope; Maintainer role on the project), PROJECT_ID
# =============================================================================
# HTH GitLab Control 2.2: Implement Pipeline Security Controls
# Profile: L1 | NIST: CM-7, SI-7
# https://howtoharden.com/guides/gitlab/#22-implement-pipeline-security-controls
#
# Read-only audit. Every call is a GET:
#   GET /projects/:id                  merge gates, minimum role for pipeline
#                                      variables, fork pipelines in the parent
#                                      (docs.gitlab.com/api/projects)
#   GET /projects/:id/job_token_scope  inbound allowlist (docs.gitlab.com/api/project_job_token_scopes)
#
# Console labels (Settings > Merge requests > Merge checks): "Pipelines must
# succeed", "Skipped pipelines are considered successful", "All threads must be
# resolved". The API field for the last one is still named
# only_allow_merge_if_all_discussions_are_resolved.
#
# ci_allow_fork_pipelines_to_run_in_parent_project is returned only to the Owner
# role or an administrator, and has no console setting. When it is true (the
# default) the pack warns rather than fails: a parent-project member must still
# trigger the pipeline and accept a warning. So a Maintainer token that cannot
# read it hides at most a warning, never a finding.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition (a call failed or a
# required field was not returned, so the project was not fully audited).
# =============================================================================
source "$(dirname "$0")/common.sh"

PROJECT_ID="${PROJECT_ID:-${1:-}}"
: "${PROJECT_ID:?Set PROJECT_ID or pass as first argument}"

banner "2.2: Implement Pipeline Security Controls (Project: ${PROJECT_ID})"
should_apply 1 || { increment_skipped; summary; exit 0; }

STATE_UNKNOWN=0
FINDINGS=0

# HTH Guide Excerpt: begin api-audit-pipeline-controls
PROJECT=$(gl_get "/projects/${PROJECT_ID}") || {
  fail "2.2 GET /projects/${PROJECT_ID} failed -- check PROJECT_ID and token"; summary; exit 2; }

# Merge gates: a merge request cannot merge until its pipeline succeeds (a
# skipped pipeline does not count) and every thread is resolved.
check_setting() {  # <json field> <required value> <description>
  local actual
  actual=$(printf '%s' "${PROJECT}" | jq -r ".$1")
  if [ "${actual}" = "$2" ]; then
    pass "2.2 $3"
  else
    fail "2.2 $3 -- expected $1=$2, found ${actual}"
    FINDINGS=$((FINDINGS + 1))
  fi
}
check_setting only_allow_merge_if_pipeline_succeeds true "Pipelines must succeed before merge"
check_setting allow_merge_on_skipped_pipeline false "Skipped pipelines do not satisfy the pipeline gate"
check_setting only_allow_merge_if_all_discussions_are_resolved true "All threads must be resolved before merge"

# Minimum role to use pipeline variables (Settings > CI/CD > Variables).
VAR_ROLE=$(printf '%s' "${PROJECT}" | jq -r '.ci_pipeline_variables_minimum_override_role // empty')
case "${VAR_ROLE}" in
  no_one_allowed|owner|maintainer)
    pass "2.2 Minimum role to use pipeline variables: ${VAR_ROLE}" ;;
  developer)
    fail "2.2 Developers can run pipelines with pipeline variables -- set the minimum role to no_one_allowed or maintainer"
    FINDINGS=$((FINDINGS + 1)) ;;
  "")
    fail "2.2 ci_pipeline_variables_minimum_override_role was not returned (GitLab 17.1+) -- pipeline variable restriction unknown"
    STATE_UNKNOWN=1 ;;
  *)
    fail "2.2 Unrecognized ci_pipeline_variables_minimum_override_role '${VAR_ROLE}'"
    FINDINGS=$((FINDINGS + 1)) ;;
esac

# Fork pipelines in the parent project (API only; Owner role to read).
FORK_IN_PARENT=$(printf '%s' "${PROJECT}" | jq -r '.ci_allow_fork_pipelines_to_run_in_parent_project | if . == null then empty else tostring end')
case "${FORK_IN_PARENT}" in
  false) pass "2.2 Fork merge request pipelines cannot run in this project" ;;
  true)  warn "2.2 Members can run fork merge request pipelines in this project (after a warning) -- review fork changes first, or set ci_allow_fork_pipelines_to_run_in_parent_project=false" ;;
  *)     info "2.2 ci_allow_fork_pipelines_to_run_in_parent_project not returned (Owner role required) -- fork pipeline setting not audited" ;;
esac

# Job token scope: only allowlisted groups and projects may use a CI/CD job
# token to reach this project.
if SCOPE=$(gl_get "/projects/${PROJECT_ID}/job_token_scope"); then
  if [ "$(printf '%s' "${SCOPE}" | jq -r '.inbound_enabled')" = "true" ]; then
    pass "2.2 CI/CD job token allowlist is enforced for inbound access"
  else
    fail "2.2 CI/CD job token allowlist is off -- jobs in any project can reach this one"
    FINDINGS=$((FINDINGS + 1))
  fi
else
  fail "2.2 Could not read the job token scope (HTTP status above; a 403 means the Maintainer role is required)"
  STATE_UNKNOWN=1
fi
# HTH Guide Excerpt: end api-audit-pipeline-controls

if [ "${FINDINGS}" -gt 0 ]; then
  fail "2.2 ${FINDINGS} pipeline control finding(s) -- fix in Settings > Merge requests and Settings > CI/CD"
  increment_failed
else
  increment_applied
fi

summary
[ "${STATE_UNKNOWN}" -eq 0 ] || exit 2
[ "${FINDINGS}" -eq 0 ] || exit 1
