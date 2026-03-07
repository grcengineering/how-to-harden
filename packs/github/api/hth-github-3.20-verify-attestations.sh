#!/usr/bin/env bash
# HTH GitHub Control 3.20: Verify Artifact Attestations
# Profile: L2 | SLSA: Build L2/L3
# https://howtoharden.com/guides/github/#35-generate-and-verify-artifact-attestations
source "$(dirname "$0")/common.sh"

banner "3.20: Verify Artifact Attestations"
should_apply 2 || { increment_skipped; summary; exit 0; }

REPO="${GITHUB_REPO:-how-to-harden}"
info "3.20 Checking artifact attestations for ${GITHUB_ORG}/${REPO}..."

# HTH Guide Excerpt: begin api-verify-attestation
# Verify a binary artifact attestation using the GitHub CLI
# Usage: Replace PATH/TO/ARTIFACT with your build artifact
gh attestation verify PATH/TO/ARTIFACT \
  -R "${GITHUB_ORG}/${REPO}"

# Verify a container image attestation
gh attestation verify oci://ghcr.io/${GITHUB_ORG}/${REPO}:latest \
  -R "${GITHUB_ORG}/${REPO}"

# Verify with specific SBOM predicate type (SPDX)
gh attestation verify PATH/TO/ARTIFACT \
  -R "${GITHUB_ORG}/${REPO}" \
  --predicate-type https://spdx.dev/Document/v2.3
# HTH Guide Excerpt: end api-verify-attestation

pass "3.20 Attestation verification commands shown above"
increment_applied

summary
