#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 7.2: Harden TLS and Certificate Configuration
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-8, SC-13
# Source: https://howtoharden.com/guides/vercel/#72-harden-tls-and-certificate-configuration
# =============================================================================

set -euo pipefail

# HTH Guide Excerpt: begin cli

DOMAIN="${1:-}"
if [ -z "${DOMAIN}" ]; then
  echo "Usage: $0 <your-domain.com>"
  exit 1
fi

# --- Verify TLS configuration ---
echo "=== TLS Verification for ${DOMAIN} ==="

# Check TLS version and cipher
echo "--- TLS Protocol and Cipher ---"
echo | openssl s_client -connect "${DOMAIN}:443" -servername "${DOMAIN}" 2>/dev/null | \
  grep -E "Protocol|Cipher|Server certificate"

# Verify HSTS header
echo ""
echo "--- HSTS Header ---"
curl -sI "https://${DOMAIN}" | grep -i "strict-transport-security" || \
  echo "WARNING: No HSTS header found!"

# Verify HTTP to HTTPS redirect
echo ""
echo "--- HTTP Redirect Check ---"
redirect=$(curl -sI -o /dev/null -w "%{http_code}" "http://${DOMAIN}" 2>/dev/null || echo "000")
if [ "${redirect}" = "308" ] || [ "${redirect}" = "301" ]; then
  echo "OK: HTTP redirects to HTTPS (${redirect})"
else
  echo "WARNING: HTTP returned ${redirect} -- expected 308 redirect"
fi

# --- Issue custom certificate (L3) ---
# Uncomment for custom certificate management:
# vercel certs issue "${DOMAIN}"

# --- List existing certificates ---
echo ""
echo "=== Certificate Inventory ==="
vercel certs ls

# HTH Guide Excerpt: end cli
