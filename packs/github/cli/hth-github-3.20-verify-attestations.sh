#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: github-3.5
#   guide: https://howtoharden.com/guides/github/#35-generate-and-verify-artifact-attestations
#   profile: L2
#   mode: read-only
#   requires: gh with attestation verify source/signer flags; authenticated read access
# Source: https://cli.github.com/manual/gh_attestation_verify (2026-11-12)
# Valid provenance is not proof that the build was authorized or non-malicious.
set -euo pipefail
# HTH Guide Excerpt: begin verify-release-identity
: "${HTH_PROFILE_LEVEL:=1}"
[[ "$HTH_PROFILE_LEVEL" =~ ^[234]$ ]] || { echo 'Requires HTH_PROFILE_LEVEL=2 or higher' >&2; exit 2; }
: "${ARTIFACT:?Set a local artifact path or digest-pinned oci:// URI}"
: "${GITHUB_REPOSITORY:?Set owner/repository}"
: "${EXPECTED_SIGNER_WORKFLOW:?Set owner/repo/.github/workflows/release.yml}"
: "${EXPECTED_SOURCE_REF:?Set approved refs/heads/... or refs/tags/...}"
: "${EXPECTED_SOURCE_SHA:?Set the independently approved source commit SHA}"
[[ "$GITHUB_REPOSITORY" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || exit 2
[[ "$EXPECTED_SOURCE_REF" == refs/heads/* || "$EXPECTED_SOURCE_REF" == refs/tags/* ]] || exit 2
[[ "$EXPECTED_SOURCE_SHA" =~ ^[0-9a-fA-F]{40}$ ]] || exit 2
if [[ "$ARTIFACT" == oci://* ]]; then
  [[ "$ARTIFACT" =~ @sha256:[0-9a-fA-F]{64}$ ]] || { echo 'OCI artifacts must be pinned by digest, not mutable tag' >&2; exit 2; }
else
  [[ -f "$ARTIFACT" ]] || { echo 'Artifact does not exist' >&2; exit 2; }
fi
command -v gh >/dev/null || { echo 'Install the official GitHub CLI' >&2; exit 2; }
# For reusable workflows, EXPECTED_SIGNER_WORKFLOW is the reusable builder,
# not its caller. Do not derive expected values from the untrusted artifact.
gh attestation verify \
  --repo "$GITHUB_REPOSITORY" \
  --signer-workflow "$EXPECTED_SIGNER_WORKFLOW" \
  --source-ref "$EXPECTED_SOURCE_REF" \
  --source-digest "$EXPECTED_SOURCE_SHA" \
  --predicate-type https://slsa.dev/provenance/v1 \
  --format json -- "$ARTIFACT"
# Nonzero verification status propagates; success is evidence, not malware review.
# HTH Guide Excerpt: end verify-release-identity
