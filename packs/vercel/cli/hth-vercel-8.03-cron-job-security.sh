#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 8.3: Cron Job Security
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-3, SI-10
# Source: https://howtoharden.com/guides/vercel/#83-cron-job-security
# =============================================================================

set -euo pipefail

# HTH Guide Excerpt: begin cli

# --- Generate a strong CRON_SECRET ---
echo "=== Generate CRON_SECRET ==="
CRON_SECRET=$(openssl rand -hex 32)
echo "Generated CRON_SECRET: ${CRON_SECRET}"

# --- Set CRON_SECRET as production environment variable ---
echo ""
echo "=== Setting CRON_SECRET Environment Variable ==="
vercel env add CRON_SECRET production <<< "${CRON_SECRET}"

# --- Verify cron endpoint rejects unauthenticated requests ---
echo ""
echo "=== Testing Cron Endpoint Security ==="
DOMAIN="${1:-}"
CRON_PATH="${2:-/api/cron}"

if [ -n "${DOMAIN}" ]; then
  # Test without auth (should return 401)
  echo "Testing without auth header..."
  http_code=$(curl -s -o /dev/null -w "%{http_code}" \
    "https://${DOMAIN}${CRON_PATH}" 2>/dev/null || echo "000")
  if [ "${http_code}" = "401" ]; then
    echo "  OK: Returns 401 without auth"
  else
    echo "  WARNING: Returns ${http_code} -- expected 401 for unauthenticated request!"
  fi

  # Test with correct auth (should return 200)
  echo "Testing with bearer token..."
  http_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer ${CRON_SECRET}" \
    "https://${DOMAIN}${CRON_PATH}" 2>/dev/null || echo "000")
  echo "  Auth response: HTTP ${http_code}"
else
  echo "Usage: $0 <your-domain.com> [/api/cron-path]"
fi

# HTH Guide Excerpt: end cli
