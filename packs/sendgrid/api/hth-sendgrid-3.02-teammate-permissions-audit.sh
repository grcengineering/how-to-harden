#!/usr/bin/env bash
# =============================================================================
# HTH SendGrid Control 3.2: Configure Teammate Permissions
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 5.4 | NIST 800-53 AC-6
# Source: https://howtoharden.com/guides/sendgrid/#32-configure-teammate-permissions
# Interface: SendGrid v3 REST API — Teammates
#   https://www.twilio.com/docs/sendgrid/api-reference/teammates/retrieve-all-teammates
# Auth: Authorization: Bearer <API key>
# Notes:
#   - user_type is one of "admin", "owner", or "teammate"; is_admin flags the
#     ALL-scopes grant. Every admin is a full-account credential — keep the
#     population minimal and justified.
#   - EU regional subusers use https://api.eu.sendgrid.com instead.
# =============================================================================

set -euo pipefail

: "${SENDGRID_API_KEY:?Set SENDGRID_API_KEY to a key authorized to read teammates}"

# HTH Guide Excerpt: begin api-audit-teammates

# --- Audit: list every teammate with their access level ---
# (SendGrid's reference shows the array as "results" in the example response
# and "result" in the schema — accept either.)
echo "=== All teammates ==="
curl -s -G -X GET "https://api.sendgrid.com/v3/teammates?limit=500&offset=0" \
  --header "Authorization: Bearer ${SENDGRID_API_KEY}" | \
  jq '(.results // .result)[] | {username, email, user_type, is_admin}'

# --- Flag: administrators (full-account credentials — should be 2-3 people) ---
echo ""
echo "=== Teammates holding the Administrator grant (review each) ==="
curl -s -G -X GET "https://api.sendgrid.com/v3/teammates?limit=500&offset=0" \
  --header "Authorization: Bearer ${SENDGRID_API_KEY}" | \
  jq '[(.results // .result)[] | select(.is_admin == true) | {username, email, user_type}]
      | {admin_count: length, admins: .}'

# HTH Guide Excerpt: end api-audit-teammates
