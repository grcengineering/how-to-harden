#!/usr/bin/env bash
# =============================================================================
# HTH GitLab Control 3.2: Rotate Runner Authentication Tokens
# Profile: L1 | NIST: IA-5(1)
# https://howtoharden.com/guides/gitlab/#32-rotate-runner-tokens
# =============================================================================
#
# MUTATING: rotates the runner authentication token (glrt-) of one runner on
# this host. `gitlab-runner reset-token` calls the Runners API with the
# runner's current token and writes the new token into config.toml, so the
# token never passes through this script (docs.gitlab.com/runner/commands).
# The old token stops working as soon as the reset succeeds.
#
# For routine rotation, prefer an automatic interval (Admin > Settings > CI/CD >
# Continuous Integration and Deployment > Runners expiration). If a token was
# EXPOSED, follow the guide instead: delete the runner and create a new one,
# because whoever holds the exposed token can reset it too.
#
# Input: RUNNER_NAME -- the runner's name as written in config.toml.
set -euo pipefail
: "${RUNNER_NAME:?Set RUNNER_NAME (the runner name in config.toml)}"

# HTH Guide Excerpt: begin cli-rotate-runner-token
# Rotate the runner's authentication token in place (config.toml is updated)
gitlab-runner reset-token --name "${RUNNER_NAME}"

# Confirm the runner still authenticates with the new token. `verify` exits 0
# even when the check fails, so test its output for "is alive". Capture a
# non-zero exit too, so the output is printed before the script stops.
VERIFY_RC=0
VERIFY_OUT=$(gitlab-runner verify --name "${RUNNER_NAME}" 2>&1) || VERIFY_RC=$?
printf '%s\n' "${VERIFY_OUT}"
case "${VERIFY_RC}:${VERIFY_OUT}" in
  0:*"is alive"*) echo "Runner ${RUNNER_NAME} rotated and verified" ;;
  *) echo "Runner ${RUNNER_NAME} did not verify after rotation (verify exit ${VERIFY_RC})" >&2; exit 1 ;;
esac
# HTH Guide Excerpt: end cli-rotate-runner-token
