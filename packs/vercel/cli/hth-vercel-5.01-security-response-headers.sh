#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 5.1: Configure Security Response Headers
# Profile Level: L1 (Baseline)
# Frameworks: NIST SI-10, SC-28
# Source: https://howtoharden.com/guides/vercel/#51-configure-security-response-headers
# =============================================================================

set -euo pipefail

# HTH Guide Excerpt: begin cli

# --- Deploy vercel.json with security headers ---
# Add this configuration to your project's vercel.json:
cat > /tmp/hth-vercel-headers.json << 'HEADERS_EOF'
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Content-Security-Policy",
          "value": "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'"
        },
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "Referrer-Policy",
          "value": "strict-origin-when-cross-origin"
        },
        {
          "key": "Permissions-Policy",
          "value": "camera=(), microphone=(), geolocation=(), interest-cohort=()"
        },
        {
          "key": "Strict-Transport-Security",
          "value": "max-age=63072000; includeSubDomains; preload"
        },
        {
          "key": "X-XSS-Protection",
          "value": "1; mode=block"
        }
      ]
    }
  ]
}
HEADERS_EOF

echo "Security headers config written to /tmp/hth-vercel-headers.json"
echo "Merge this into your project's vercel.json, then deploy:"
echo "  vercel deploy --prod"

# --- Validate deployed headers ---
echo ""
echo "=== Validating Security Headers ==="
DOMAIN="${1:-}"
if [ -n "${DOMAIN}" ]; then
  echo "Checking headers for: ${DOMAIN}"
  curl -sI "https://${DOMAIN}" | grep -iE \
    "content-security-policy|x-frame-options|x-content-type|referrer-policy|permissions-policy|strict-transport|x-xss"
else
  echo "Usage: $0 <your-domain.com>"
fi

# HTH Guide Excerpt: end cli
