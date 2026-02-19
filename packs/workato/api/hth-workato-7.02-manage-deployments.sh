#!/usr/bin/env bash
# HTH Workato Control 7.02: Configure Recipe Lifecycle Management (RLCM)
# Profile: L2 | NIST: CM-3, SA-10
# https://howtoharden.com/guides/workato/#72-configure-recipe-lifecycle-management-rlcm

# HTH Guide Excerpt: begin api-list-deployments
# List deployment packages
curl -s "https://www.workato.com/api/deployments" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {id, name, state, created_at}'
# HTH Guide Excerpt: end api-list-deployments

# HTH Guide Excerpt: begin api-export-package
# Create a deployment package
curl -s -X POST "https://www.workato.com/api/packages/export/MANIFEST_ID" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" \
  -H "Content-Type: application/json"
# HTH Guide Excerpt: end api-export-package

# HTH Guide Excerpt: begin api-import-package
# Import a package into target environment
curl -s -X POST "https://www.workato.com/api/packages/import/FOLDER_ID" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @package.zip
# HTH Guide Excerpt: end api-import-package
