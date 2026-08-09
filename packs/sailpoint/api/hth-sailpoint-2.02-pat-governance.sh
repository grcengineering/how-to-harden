#!/usr/bin/env bash
# HTH SailPoint Control 2.2: Govern API Clients and Personal Access Tokens
# Profile: L1 | CIS Controls: 5.2, 6.8 | NIST 800-53: IA-5, AC-6, AU-2
# https://howtoharden.com/guides/sailpoint/#22-govern-api-clients-and-personal-access-tokens
#
# Interface: Identity Security Cloud v3 Personal Access Tokens API.
#   API reference: https://developer.sailpoint.com/docs/api/v3/list-personal-access-tokens
#   OpenAPI spec:  https://github.com/sailpoint-oss/api-specs (idn/v3, /personal-access-tokens)
# Listing all tenant tokens requires the idn:all-personal-access-tokens:read
# right. A PAT whose expirationDate is null NEVER expires — those are the
# tokens this script exists to find.
#
# Environment:
#   SAIL_BASE_URL      e.g. https://{tenant}.api.identitynow.com
#   SAIL_CLIENT_ID     OAuth client / PAT client ID
#   SAIL_CLIENT_SECRET OAuth client / PAT secret

set -euo pipefail
: "${SAIL_BASE_URL:?Set SAIL_BASE_URL, e.g. https://tenant.api.identitynow.com}"
: "${SAIL_CLIENT_ID:?Set SAIL_CLIENT_ID}"
: "${SAIL_CLIENT_SECRET:?Set SAIL_CLIENT_SECRET}"

# HTH Guide Excerpt: begin api-get-token
# Client-credentials token from the tenant's documented OAuth token endpoint.
ACCESS_TOKEN=$(curl -sf -X POST "${SAIL_BASE_URL}/oauth/token" \
  --data-urlencode "grant_type=client_credentials" \
  --data-urlencode "client_id=${SAIL_CLIENT_ID}" \
  --data-urlencode "client_secret=${SAIL_CLIENT_SECRET}" | jq -r '.access_token')
# HTH Guide Excerpt: end api-get-token

# HTH Guide Excerpt: begin api-inventory-pats
# Org-wide PAT inventory: owner, created, lastUsed, expiration, managed flag.
# lastUsed is refreshed at most once a day and is the documented signal for
# identifying tokens that are no longer actively used.
curl -sf "${SAIL_BASE_URL}/v3/personal-access-tokens" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" |
  jq -r '.[] | [.id, .name, .owner.name, .created,
                (.lastUsed // "never-used"),
                (.expirationDate // "NEVER-EXPIRES"),
                (if .managed then "managed" else "non-managed" end)] | @tsv'
# HTH Guide Excerpt: end api-inventory-pats

# HTH Guide Excerpt: begin api-flag-never-expiring-pats
# Policy violation list: non-managed tokens with no expiration date.
# Per the API spec, expirationDate null/empty means the token never expires.
curl -sf "${SAIL_BASE_URL}/v3/personal-access-tokens" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" |
  jq -r '[.[] | select(.expirationDate == null and .managed == false)]
         | if length == 0 then "OK: no never-expiring non-managed PATs"
           else .[] | "VIOLATION never-expiring PAT: \(.id) \(.name) owner=\(.owner.name)" end'
# HTH Guide Excerpt: end api-flag-never-expiring-pats

# HTH Guide Excerpt: begin api-find-stale-pats
# Server-side filtering is documented for lastUsed with the "le" and
# "isnull" operators: tokens unused since a cutoff, and tokens never used.
CUTOFF="2026-05-01T00:00:00.000Z"
curl -sf -G "${SAIL_BASE_URL}/v3/personal-access-tokens" \
  --data-urlencode "filters=lastUsed le ${CUTOFF}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" | jq -r '.[] | [.id, .name, .owner.name, .lastUsed] | @tsv'

curl -sf -G "${SAIL_BASE_URL}/v3/personal-access-tokens" \
  --data-urlencode "filters=lastUsed isnull" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" | jq -r '.[] | [.id, .name, .owner.name, .created] | @tsv'
# HTH Guide Excerpt: end api-find-stale-pats

# HTH Guide Excerpt: begin api-revoke-pat
# Revoke a specific token by ID (DELETE /v3/personal-access-tokens/{id}).
# PAT_ID=86f1dc6fe8f54414950454cbb11278fa
# curl -sf -X DELETE "${SAIL_BASE_URL}/v3/personal-access-tokens/${PAT_ID}" \
#   -H "Authorization: Bearer ${ACCESS_TOKEN}"
# HTH Guide Excerpt: end api-revoke-pat
