#!/usr/bin/env bash
# =============================================================================
# HTH GitLab Control 3.1: Isolate CI/CD Runners
# Profile: L1 | NIST: SC-7
# https://howtoharden.com/guides/gitlab/#31-isolate-cicd-runners
# =============================================================================
#
# MUTATING: creates a project runner in GitLab, then registers this host to it.
# Uses the runner creation workflow: the runner's scope, tags, and protection
# are fixed when it is created, and `gitlab-runner register --token` takes only
# the glrt- runner authentication token. Registration tokens are legacy and not
# recommended (docs.gitlab.com/ci/runners/new_creation_workflow).
#
# Inputs, all required up front so nothing runs half-configured:
#   GITLAB_URL    e.g. https://gitlab.com
#   GITLAB_TOKEN  access token with the create_runner scope (Maintainer or Owner)
#   PROJECT_ID    the project the runner is dedicated to
# The runner authentication token is captured from the API response and passed
# straight to gitlab-runner; it is never printed.
set -euo pipefail
: "${GITLAB_URL:?Set GITLAB_URL (e.g., https://gitlab.com)}"
: "${GITLAB_TOKEN:?Set GITLAB_TOKEN (create_runner scope)}"
: "${PROJECT_ID:?Set PROJECT_ID}"

# HTH Guide Excerpt: begin cli-register-runner
# 1. Create a project runner: tagged, not picking up untagged jobs, locked to
#    this project, and running only on protected branches and tags
#    (POST /user/runners, docs.gitlab.com/api/users).
RUNNER_AUTH_TOKEN=$(curl -sf --request POST \
  --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
  --data "runner_type=project_type" \
  --data "project_id=${PROJECT_ID}" \
  --data "description=isolated-security-sensitive" \
  --data "tag_list=isolated,security-sensitive" \
  --data "run_untagged=false" \
  --data "locked=true" \
  --data "access_level=ref_protected" \
  "${GITLAB_URL}/api/v4/user/runners" | jq -er '.token')

# 2. Register this host with the runner authentication token only
gitlab-runner register --non-interactive \
  --url "${GITLAB_URL}" \
  --token "${RUNNER_AUTH_TOKEN}" \
  --executor "docker" \
  --docker-image "alpine:3.24"
# HTH Guide Excerpt: end cli-register-runner

# Secure runner configuration -- printed for you to merge into the new
# runner's entry in /etc/gitlab-runner/config.toml (this script does not
# overwrite that file). Check the result with
# `gitlab-runner lint --config /etc/gitlab-runner/config.toml`.
cat <<'TOML'
# HTH Guide Excerpt: begin cli-runner-config
[[runners]]
  name = "secure-runner"
  executor = "docker"
  [runners.docker]
    image = "alpine:3.24"
    privileged = false  # Never enable unless absolutely required
    disable_entrypoint_overwrite = true
    volumes = ["/cache"]
    # Drop Linux capabilities from the job container
    cap_drop = ["ALL"]
# HTH Guide Excerpt: end cli-runner-config
TOML
