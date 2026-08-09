#!/usr/bin/env bash
# =============================================================================
# HTH Postman Control 2.4: Restrict Public Workspaces
# Profile: L2 | CIS Controls: 3.3 | NIST 800-53: AC-3
# https://howtoharden.com/guides/postman/#24-restrict-public-workspaces
#
# Audits the team for workspaces whose visibility is "public" (discoverable by
# anyone on the internet). Requires a Postman API key sent in the X-API-Key
# header. Endpoint per the Postman API OpenAPI reference:
#   GET https://api.postman.com/workspaces?type=public
#   https://learning.postman.com/api-docs/api-reference/
# EU data-residency teams use https://api.eu.postman.com instead.
# =============================================================================
set -euo pipefail

: "${POSTMAN_API_KEY:?Set POSTMAN_API_KEY to a Postman API key}"
POSTMAN_API_BASE="${POSTMAN_API_BASE:-https://api.postman.com}"

# HTH Guide Excerpt: begin api-audit-public-workspaces
# List every workspace visible to this API key whose visibility is "public".
# Valid values for the type query parameter: personal, team, private, public,
# partner.
PUBLIC_WORKSPACES=$(curl -sf "${POSTMAN_API_BASE}/workspaces?type=public" \
  -H "X-API-Key: ${POSTMAN_API_KEY}")

COUNT=$(printf '%s' "${PUBLIC_WORKSPACES}" | jq '.workspaces | length')

if [ "${COUNT}" -eq 0 ]; then
  echo "PASS: no public workspaces found"
else
  echo "WARN: ${COUNT} public workspace(s) exposed to the internet:"
  printf '%s' "${PUBLIC_WORKSPACES}" | jq -r '.workspaces[]
    | "  \(.id)\t\(.name)\tvisibility=\(.visibility)\tcreatedBy=\(.createdBy // "unknown")"'
  echo "Review each workspace and convert to private/team unless deliberately published (control 2.4)."
fi
# HTH Guide Excerpt: end api-audit-public-workspaces
