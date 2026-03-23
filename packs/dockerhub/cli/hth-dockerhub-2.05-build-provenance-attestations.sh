#!/usr/bin/env bash
# HTH Docker Hub Control 2.5: Build Provenance and SBOM Attestations
# Profile: L2 | NIST: SA-12, SI-7
# https://howtoharden.com/guides/dockerhub/#25-generate-build-provenance-and-sbom-attestations

# HTH Guide Excerpt: begin cli-build-provenance-attestations
# Build with maximum provenance (SLSA Build L2+)
docker buildx build \
  --provenance=mode=max \
  --sbom=true \
  -t myorg/myimage:v1 \
  --push .

# Inspect provenance of an image
docker buildx imagetools inspect myorg/myimage:v1 \
  --format '{{ json .Provenance }}'

# Inspect SBOM of an image
docker buildx imagetools inspect myorg/myimage:v1 \
  --format '{{ json .SBOM }}'

# Verify build provenance with cosign
cosign verify-attestation myorg/myimage@sha256:<digest> \
  --type slsaprovenance \
  --certificate-identity-regexp='.*@myorg\.com' \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com

# GitHub Actions: build with attestations
# - uses: docker/build-push-action@v5
#   with:
#     push: true
#     tags: myorg/myimage:${{ github.sha }}
#     provenance: mode=max
#     sbom: true
# HTH Guide Excerpt: end cli-build-provenance-attestations
