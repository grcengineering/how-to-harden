#!/usr/bin/env bash
# HTH GitHub Control 3.11: Require CODEOWNERS Approval for Workflow Changes
# Profile: L2 | NIST: CM-3, CM-5
# https://howtoharden.com/guides/github/#311-require-codeowners-approval-for-workflow-changes
#
# Writes a CODEOWNERS file that routes every CI/CD-surface change through
# the security/platform teams. Pair with branch protection requiring
# review from Code Owners.

set -euo pipefail

REPO_ROOT="${1:-.}"
mkdir -p "${REPO_ROOT}/.github"

# HTH Guide Excerpt: begin config-codeowners-cicd
cat > "${REPO_ROOT}/.github/CODEOWNERS" << 'CODEOWNERS'
# Security/Platform team must approve all CI/CD changes
.github/workflows/    @org/security-team @org/platform-team
.github/actions/      @org/security-team @org/platform-team

# Also protect Dependabot and Renovate configs
.github/dependabot.yml  @org/security-team
renovate.json           @org/security-team
CODEOWNERS
# HTH Guide Excerpt: end config-codeowners-cicd

echo "CODEOWNERS written to ${REPO_ROOT}/.github/CODEOWNERS"
