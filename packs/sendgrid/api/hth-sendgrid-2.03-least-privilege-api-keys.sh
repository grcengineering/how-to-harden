#!/usr/bin/env bash
# =============================================================================
# HTH SendGrid Control 2.3: Implement Least Privilege API Access
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 5.4 | NIST 800-53 AC-6
# Source: https://howtoharden.com/guides/sendgrid/#23-implement-least-privilege-api-access
# Interface: SendGrid v3 REST API — API Keys
#   https://www.twilio.com/docs/sendgrid/api-reference/api-keys/retrieve-all-api-keys-belonging-to-the-authenticated-user
#   https://www.twilio.com/docs/sendgrid/api-reference/api-keys/retrieve-an-existing-api-key
#   https://www.twilio.com/docs/sendgrid/api-reference/api-keys/create-api-keys
#   https://www.twilio.com/docs/sendgrid/api-reference/api-keys/delete-api-keys
# Auth: Authorization: Bearer <API key>
# Notes:
#   - Creating a key WITHOUT a scopes array yields Full Access. Always pass
#     an explicit scopes list for integration keys.
#   - The api_key secret is returned once at creation (201) — vault it then.
#   - EU regional subusers use https://api.eu.sendgrid.com instead.
# =============================================================================

set -euo pipefail

: "${SENDGRID_API_KEY:?Set SENDGRID_API_KEY to a key authorized for API key management}"

# HTH Guide Excerpt: begin api-audit-key-scopes

# --- Audit: enumerate every API key and its granted scopes ---
# The list endpoint returns id + name; each key must be fetched individually
# to see its scopes. Flag keys with broad grants for replacement.
echo "=== API keys and their scopes ==="
for KEY_ID in $(curl -s -X GET "https://api.sendgrid.com/v3/api_keys" \
    --header "Authorization: Bearer ${SENDGRID_API_KEY}" | \
    jq -r '.result[].api_key_id'); do
  curl -s -X GET "https://api.sendgrid.com/v3/api_keys/${KEY_ID}" \
    --header "Authorization: Bearer ${SENDGRID_API_KEY}" | \
    jq '{api_key_id, name, scope_count: (.scopes | length), scopes}'
done

# HTH Guide Excerpt: end api-audit-key-scopes

# HTH Guide Excerpt: begin api-create-scoped-key

# --- Enforce: create a purpose-scoped key for one integration ---
# This example issues a transactional-send-only key. The scopes array is the
# entire grant: nothing outside it is reachable with this key.
curl -s -X POST "https://api.sendgrid.com/v3/api_keys" \
  --header "Authorization: Bearer ${SENDGRID_API_KEY}" \
  --header "Content-Type: application/json" \
  --data '{"name": "transactional-sender", "scopes": ["mail.send"]}'

# --- Retire: delete an over-privileged or unused key ---
# Cut the owning integration over to its scoped replacement first.
curl -s -X DELETE "https://api.sendgrid.com/v3/api_keys/${SENDGRID_OLD_KEY_ID:?Set SENDGRID_OLD_KEY_ID}" \
  --header "Authorization: Bearer ${SENDGRID_API_KEY}"

# HTH Guide Excerpt: end api-create-scoped-key
