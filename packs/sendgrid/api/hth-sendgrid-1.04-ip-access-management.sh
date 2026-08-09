#!/usr/bin/env bash
# =============================================================================
# HTH SendGrid Control 1.4: Configure IP Access Management
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 13.5 | NIST 800-53 AC-17
# Source: https://howtoharden.com/guides/sendgrid/#14-configure-ip-access-management
# Interface: SendGrid v3 REST API — IP Access Management
#   https://www.twilio.com/docs/sendgrid/api-reference/ip-access-management/retrieve-a-list-of-currently-allowed-ips
#   https://www.twilio.com/docs/sendgrid/api-reference/ip-access-management/add-one-or-more-ips-to-the-allow-list
# Auth: Authorization: Bearer <API key>
# Notes:
#   - The allowlist governs the web UI, the API, and the SMTP relay. An IP
#     added here must cover EVERY egress path your integrations send from.
#   - Maximum 1,000 allowed IP addresses per account.
#   - EU regional subusers use https://api.eu.sendgrid.com instead.
# =============================================================================

set -euo pipefail

: "${SENDGRID_API_KEY:?Set SENDGRID_API_KEY to a key authorized for access settings}"

# HTH Guide Excerpt: begin api-audit-allowlist

# --- Audit: which IPs are currently allowed to access the account? ---
# Review every entry against your inventory of offices, VPN egress, and
# CI/CD ranges; anything unrecognized is either stale or an implant.
echo "=== Current IP allowlist ==="
curl -s -X GET "https://api.sendgrid.com/v3/access_settings/whitelist" \
  --header "Authorization: Bearer ${SENDGRID_API_KEY}" | \
  jq '.result[] | {id, ip, created_at, updated_at}'

# HTH Guide Excerpt: end api-audit-allowlist

# HTH Guide Excerpt: begin api-add-allowed-ips

# --- Enforce: add approved networks to the allowlist ---
# Supports single IPs and CIDR blocks. Add YOUR CURRENT IP and every
# integration's egress range BEFORE enabling enforcement, or you lock
# yourself and your senders out the moment it takes effect.
curl -s -X POST "https://api.sendgrid.com/v3/access_settings/whitelist" \
  --header "Authorization: Bearer ${SENDGRID_API_KEY}" \
  --header "Content-Type: application/json" \
  --data '{
    "ips": [
      {"ip": "203.0.113.10"},
      {"ip": "198.51.100.0/24"}
    ]
  }'

# HTH Guide Excerpt: end api-add-allowed-ips
