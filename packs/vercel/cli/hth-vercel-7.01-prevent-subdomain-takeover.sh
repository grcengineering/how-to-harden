#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 7.1: Prevent Subdomain Takeover
# Profile Level: L1 (Baseline)
# Frameworks: NIST CM-8, SC-20
# Source: https://howtoharden.com/guides/vercel/#71-prevent-subdomain-takeover
# =============================================================================

set -euo pipefail

# HTH Guide Excerpt: begin cli

# --- List all domains configured in the Vercel team ---
echo "=== Vercel Domain Inventory ==="
vercel domains ls

# --- Check for dangling CNAME records pointing to Vercel ---
echo ""
echo "=== Checking for Dangling DNS Records ==="
DOMAINS=$(vercel domains ls 2>/dev/null | awk 'NR>2 {print $1}' | grep -v '^$')

for domain in ${DOMAINS}; do
  echo "Checking: ${domain}"
  # Check if CNAME points to Vercel
  cname=$(dig +short CNAME "${domain}" 2>/dev/null || true)
  if echo "${cname}" | grep -qi "vercel\|now\.sh"; then
    # Verify the domain resolves to an active deployment
    http_code=$(curl -s -o /dev/null -w "%{http_code}" "https://${domain}" 2>/dev/null || echo "000")
    if [ "${http_code}" = "000" ] || [ "${http_code}" = "404" ]; then
      echo "  WARNING: ${domain} has CNAME to Vercel but returns ${http_code} -- possible takeover risk!"
    else
      echo "  OK: ${domain} -> ${cname} (HTTP ${http_code})"
    fi
  fi
done

# --- Remove a domain no longer in use ---
# Uncomment and customize:
# vercel domains rm "unused-subdomain.example.com"

# HTH Guide Excerpt: end cli
