#!/usr/bin/env bash
# =============================================================================
# HTH Postman Control 3.4: Enable Secret Scanner
# Profile: L1 | CIS Controls: 16.4 | NIST 800-53: IA-5
# https://howtoharden.com/guides/postman/#34-enable-secret-scanner
#
# Exports unresolved Secret Scanner findings so exposed credentials can be
# rotated and fed into your secret-response workflow. The findings API
# requires Postman Enterprise with the Advanced Security Administration
# add-on. Endpoint per the Postman API OpenAPI reference:
#   POST https://api.postman.com/detected-secrets-queries
#   https://learning.postman.com/api-docs/api-reference/
# Request body filters: resolved, secretTypes, statuses (FALSE_POSITIVE |
# ACCEPTED_RISK | REVOKED), workspaceIds, workspaceVisibilities (team|public).
# =============================================================================
set -euo pipefail

: "${POSTMAN_API_KEY:?Set POSTMAN_API_KEY to a Postman API key}"
POSTMAN_API_BASE="${POSTMAN_API_BASE:-https://api.postman.com}"

# HTH Guide Excerpt: begin api-export-secret-findings
# Page through every unresolved detected secret ("resolved": false) and emit
# one tab-separated row per finding for triage or SIEM ingestion.
echo -e "detectedAt\tsecretId\tsecretType\tresolution\tworkspaceId\toccurrences\tobfuscatedSecret"
CURSOR=""
while :; do
  RESPONSE=$(curl -sf \
    "${POSTMAN_API_BASE}/detected-secrets-queries?limit=50${CURSOR:+&cursor=${CURSOR}}" \
    -H "X-API-Key: ${POSTMAN_API_KEY}" \
    -H "Content-Type: application/json" \
    -d '{"resolved": false}')

  printf '%s' "${RESPONSE}" | jq -r '.data[]
    | [.detectedAt, .secretId, .secretType, .resolution, .workspaceId,
       (.occurrences | tostring), .obfuscatedSecret] | @tsv'

  CURSOR=$(printf '%s' "${RESPONSE}" | jq -r '.meta.nextCursor // empty')
  [ -n "${CURSOR}" ] || break
done
# HTH Guide Excerpt: end api-export-secret-findings
