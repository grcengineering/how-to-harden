#!/usr/bin/env bash
# HTH Docker Hub Control 2.4: Verify Images with Cosign/Sigstore
# Profile: L2 | NIST: SI-7, SA-12
# https://howtoharden.com/guides/dockerhub/#24-verify-images-with-cosignsigstore

# HTH Guide Excerpt: begin cli-cosign-image-verification
# Install cosign
# brew install cosign  (macOS)
# go install github.com/sigstore/cosign/v2/cmd/cosign@latest  (Go)

# Sign an image (keyless, uses OIDC identity from CI)
cosign sign myorg/myimage@sha256:<digest>

# Sign with a key pair (for air-gapped environments)
cosign generate-key-pair
cosign sign --key cosign.key myorg/myimage@sha256:<digest>

# Verify an image signature with identity pinning
cosign verify myorg/myimage@sha256:<digest> \
  --certificate-identity-regexp='.*@myorg\.com' \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com

# Verify in CI/CD before deployment
cosign verify aquasec/trivy@sha256:<digest> \
  --certificate-identity-regexp='.*aquasecurity.*' \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  || { echo "ALERT: Image signature verification failed!"; exit 1; }

# GitHub Actions workflow for build + sign + verify
# name: Build and Sign
# on: push
# permissions:
#   id-token: write  # Required for keyless signing
#   packages: write
# jobs:
#   build:
#     runs-on: ubuntu-latest
#     steps:
#       - uses: actions/checkout@v4
#       - uses: sigstore/cosign-installer@v3
#       - run: |
#           docker build -t ghcr.io/${{ github.repository }}:${{ github.sha }} .
#           docker push ghcr.io/${{ github.repository }}:${{ github.sha }}
#           cosign sign ghcr.io/${{ github.repository }}@$(docker inspect --format='{{index .RepoDigests 0}}' ghcr.io/${{ github.repository }}:${{ github.sha }} | cut -d@ -f2)
# HTH Guide Excerpt: end cli-cosign-image-verification
