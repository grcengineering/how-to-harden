#!/usr/bin/env bash
# HTH GitHub Control 5.09: Monitor Secret Changes and Rotation
# Profile: L1 | NIST: SC-12
# https://howtoharden.com/guides/github/#51-use-github-actions-secrets-with-environment-protection
#
# Uses the gh CLI. GitHub does not log secret READS; the audit log records secret
# writes (create/update/remove), which is what this pack reports. The audit-log
# queries require GitHub Enterprise Cloud.
set -euo pipefail
: "${GITHUB_ORG:?Set GITHUB_ORG (your GitHub organization name)}"

# HTH Guide Excerpt: begin api-track-secret-rotation
# Organization secrets with their last update time (rotation age)
gh secret list --org "${GITHUB_ORG}" --json name,updatedAt,visibility
# HTH Guide Excerpt: end api-track-secret-rotation

# HTH Guide Excerpt: begin api-audit-secret-access
# Audit-log history of organization secret writes
for action in org.create_actions_secret org.update_actions_secret org.remove_actions_secret; do
  gh api "/orgs/${GITHUB_ORG}/audit-log?phrase=action:${action}&per_page=100" \
    --jq '.[] | {action, actor, created_at}'
done
# HTH Guide Excerpt: end api-audit-secret-access
