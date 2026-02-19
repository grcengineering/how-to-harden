#!/usr/bin/env bash
# HTH Docker Hub Control 2.2: Image Signing (Content Trust)
# Profile: L2 | NIST: SI-7
# https://howtoharden.com/guides/dockerhub/#22-image-signing-content-trust

# HTH Guide Excerpt: begin cli-content-trust
# Enable content trust
export DOCKER_CONTENT_TRUST=1

# Sign and push image
docker push myorg/myimage:latest
# HTH Guide Excerpt: end cli-content-trust
