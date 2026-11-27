#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: glean-2.1
#   guide: https://howtoharden.com/guides/glean/#21-verify-custom-datasource-access-before-rollout
#   profile: L1
#   mode: read-only
#   requires: glean-indexing-sdk and custom datasource-scoped index token
# HTH glean 2.1: Verify custom datasource access before rollout
# Profile: L1 (Crawl)
# Guide: https://howtoharden.com/guides/glean/
# Reference: https://developers.glean.com/libraries/indexing-sdk/status-and-debugging
# HTH Guide Excerpt: begin check-custom-document-access
set -euo pipefail
set +x
: "${GLEAN_SERVER_URL:?Set the approved Glean backend URL}"
: "${GLEAN_INDEXING_API_TOKEN:?Use a datasource-scoped test token}"
: "${GLEAN_DATASOURCE:?Set the exact custom datasource}"
: "${GLEAN_OBJECT_TYPE:?Set the indexed object type}"
: "${GLEAN_DOCUMENT_ID:?Set the synthetic document ID}"
: "${GLEAN_TEST_USER:?Set the approved test identity}"
[[ "$GLEAN_SERVER_URL" =~ ^https://[A-Za-z0-9][A-Za-z0-9-]*-be\.glean\.com/?$ ]] ||
  { printf '%s\n' 'Use a verified Glean-hosted backend; this sample rejects custom domains.' >&2; exit 2; }
glean-idx document access --datasource "$GLEAN_DATASOURCE" \
  --object-type "$GLEAN_OBJECT_TYPE" --id "$GLEAN_DOCUMENT_ID" --user "$GLEAN_TEST_USER"
# HTH Guide Excerpt: end check-custom-document-access
