#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: google-vertex-ai-1.1
#   guide: https://howtoharden.com/guides/google-vertex-ai/#11-allow-only-approved-model-garden-model-actions
#   profile: L1
#   mode: read-only
#   requires: Google Cloud CLI or Google Terraform provider, target-scoped IAM access
# HTH google-vertex-ai 1.1: Allow only approved Model Garden model actions
# Profile: L1 (Crawl)
# Guide: https://howtoharden.com/guides/google-vertex-ai/
# Reference: https://docs.cloud.google.com/sdk/gcloud/reference/org-policies/describe
# HTH Guide Excerpt: begin read-effective-model-policy
set -euo pipefail
: "${GOOGLE_CLOUD_PROJECT:?Set the project to assess}"
gcloud org-policies describe vertexai.allowedModels --effective \
  --project="$GOOGLE_CLOUD_PROJECT" --format=json
# HTH Guide Excerpt: end read-effective-model-policy
