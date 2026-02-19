#!/usr/bin/env bash
# HTH CircleCI Control 4.01: Self-Hosted Runner Hardening — Runner Security Configuration
# Profile: L2 | NIST: SC-7
# https://howtoharden.com/guides/circleci/#41-self-hosted-runner-hardening
#
# Deploy: Run on runner host machine

# HTH Guide Excerpt: begin api-runner-security-setup
# Runner machine hardening
# - Run as non-root user
# - Enable audit logging
# - Network isolation
# - Ephemeral storage

# Example Docker runner setup
docker run -d \
  --name circleci-runner \
  --security-opt no-new-privileges \
  --read-only \
  --tmpfs /tmp \
  -e CIRCLECI_RESOURCE_CLASS="company/secure-runner" \
  -e CIRCLECI_RUNNER_API_AUTH_TOKEN="${RUNNER_TOKEN}" \
  circleci/runner:latest
# HTH Guide Excerpt: end api-runner-security-setup
