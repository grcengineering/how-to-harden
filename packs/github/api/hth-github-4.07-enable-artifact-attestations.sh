#!/usr/bin/env bash
# HTH GitHub Control 4.07: Enable Artifact Attestations
# Profile: L2 | NIST: SA-12, SI-7, CM-14
# https://howtoharden.com/guides/github/#44-enable-artifact-attestations-for-supply-chain-provenance
source "$(dirname "$0")/common.sh"

banner "4.07: Enable Artifact Attestations"
should_apply 2 || { increment_skipped; summary; exit 0; }

REPO="${GITHUB_REPO:-how-to-harden}"
info "4.07 Checking artifact attestations for ${GITHUB_ORG}/${REPO}..."

# HTH Guide Excerpt: begin api-list-attestations
# List existing artifact attestations for a specific artifact digest
# Replace DIGEST with the actual artifact digest (sha256:...)
DIGEST="${1:-sha256:example}"
gh api "/orgs/${GITHUB_ORG}/attestations/${DIGEST}" \
  --jq '.attestations[] | {bundle_media_type: .bundle.mediaType, verified: .bundle.verificationMaterial}'
# HTH Guide Excerpt: end api-list-attestations

# HTH Guide Excerpt: begin api-verify-attestation
# Verify artifact attestation using the GitHub CLI
# Replace IMAGE with the container image or artifact path
IMAGE="${1:?Usage: $0 <image_or_artifact>}"
gh attestation verify "${IMAGE}" \
  --owner "${GITHUB_ORG}"
# HTH Guide Excerpt: end api-verify-attestation

increment_applied
summary
