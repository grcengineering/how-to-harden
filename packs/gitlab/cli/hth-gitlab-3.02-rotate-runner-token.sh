#!/usr/bin/env bash
# =============================================================================
# HTH GitLab Control 3.2: Rotate Runner Registration Token
# Profile: L1 | NIST: IA-5(1)
# =============================================================================

# HTH Guide Excerpt: begin cli-rotate-runner-token
# Reset project runner token
curl -X POST -H "PRIVATE-TOKEN: ${ADMIN_TOKEN}" \
  "https://gitlab.company.com/api/v4/projects/${PROJECT_ID}/runners/reset_registration_token"

# Re-register runner
gitlab-runner unregister --all-runners
gitlab-runner register --non-interactive \
  --url "https://gitlab.company.com" \
  --registration-token "${NEW_TOKEN}" \
  --executor "docker"
# HTH Guide Excerpt: end cli-rotate-runner-token
