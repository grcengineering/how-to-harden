#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: google-vertex-ai-2.1
#   guide: https://howtoharden.com/guides/google-vertex-ai/#21-stage-a-service-perimeter-for-supported-vertex-ai-workloads
#   profile: L2
#   mode: read-only
#   requires: Google Cloud CLI or Google Terraform provider, target-scoped IAM access
# HTH google-vertex-ai 2.1: Stage a service perimeter for supported Vertex AI workloads
# Profile: L2 (Walk)
# Guide: https://howtoharden.com/guides/google-vertex-ai/
# Reference: https://docs.cloud.google.com/sdk/gcloud/reference/access-context-manager/perimeters/list
# HTH Guide Excerpt: begin list-service-perimeters
set -euo pipefail
: "${GOOGLE_ACCESS_POLICY:?Set the Access Context Manager policy ID}"
gcloud access-context-manager perimeters list --policy="$GOOGLE_ACCESS_POLICY" --format=json
# HTH Guide Excerpt: end list-service-perimeters
