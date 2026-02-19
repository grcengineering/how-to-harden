#!/usr/bin/env bash
# HTH GitHub Control 5.09: Monitor Secret Access and Rotation
# Profile: L1 | NIST: SC-12
# https://howtoharden.com/guides/github/#51-use-github-actions-secrets-with-environment-protection
source "$(dirname "$0")/common.sh"

banner "5.09: Monitor Secret Access and Rotation"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "5.09 Monitoring secret access for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-track-secret-rotation
gh secret list --json name,updatedAt
# HTH Guide Excerpt: end api-track-secret-rotation

# HTH Guide Excerpt: begin api-audit-secret-access
# Check audit log for secret access
gh api /orgs/{org}/audit-log?phrase=secrets.read
# HTH Guide Excerpt: end api-audit-secret-access

increment_applied
summary
