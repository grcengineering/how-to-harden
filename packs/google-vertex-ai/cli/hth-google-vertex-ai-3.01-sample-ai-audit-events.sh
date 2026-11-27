#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: google-vertex-ai-3.1
#   guide: https://howtoharden.com/guides/google-vertex-ai/#31-verify-security-audit-coverage-for-vertex-ai
#   profile: L2
#   mode: read-only
#   requires: Google Cloud CLI or Google Terraform provider, target-scoped IAM access
# HTH google-vertex-ai 3.1: Verify security audit coverage for Vertex AI
# Profile: L2 (Walk)
# Guide: https://howtoharden.com/guides/google-vertex-ai/
# Reference: https://docs.cloud.google.com/sdk/gcloud/reference/logging/read
# HTH Guide Excerpt: begin sample-ai-audit-events
set -euo pipefail
: "${GOOGLE_CLOUD_PROJECT:?Set the project to assess}"
gcloud logging read 'protoPayload.serviceName="aiplatform.googleapis.com" AND log_id("cloudaudit.googleapis.com/data_access")' \
  --project="$GOOGLE_CLOUD_PROJECT" --freshness=1d --limit=25 \
  --format='table(timestamp,protoPayload.methodName,insertId)'
# HTH Guide Excerpt: end sample-ai-audit-events
