#!/usr/bin/env bash
# =============================================================================
# HTH GitLab Control 3.1: Isolate CI/CD Runners
# Profile: L1 | NIST: SC-7
# =============================================================================

# HTH Guide Excerpt: begin cli-register-runner
# Register runner with specific tags
gitlab-runner register \
  --url "https://gitlab.company.com" \
  --registration-token "${RUNNER_TOKEN}" \
  --executor "docker" \
  --docker-image "alpine:3.18" \
  --tag-list "isolated,security-sensitive" \
  --run-untagged="false" \
  --locked="true"
# HTH Guide Excerpt: end cli-register-runner

# Secure runner configuration (/etc/gitlab-runner/config.toml)
# HTH Guide Excerpt: begin cli-runner-config
[[runners]]
  name = "secure-runner"
  executor = "docker"
  [runners.docker]
    image = "alpine:3.18"
    privileged = false  # Never enable unless absolutely required
    disable_entrypoint_overwrite = true
    volumes = ["/cache"]
    # Limit network access
    network_mode = "bridge"
    # Read-only root filesystem
    read_only = true
    # Drop capabilities
    cap_drop = ["ALL"]
# HTH Guide Excerpt: end cli-runner-config
