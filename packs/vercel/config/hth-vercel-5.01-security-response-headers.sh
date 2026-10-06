#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 5.1: Configure Security Response Headers
# Profile Level: L1 (Crawl)
# Frameworks: NIST SI-10, SC-28
# Source: https://howtoharden.com/guides/vercel/#51-configure-security-response-headers
# Type: config -- emits the vercel.json "headers" block, then checks a deployed
#       domain for each header. Does not call the vercel CLI or any Vercel API.
# Usage: ./hth-vercel-5.01-security-response-headers.sh [your-domain.com]
# Exit: 0 every header present with X-XSS-Protection 0 (or no domain given: the
#       config was only emitted); 1 a header missing or X-XSS-Protection set to
#       anything but 0; 2 the check did not run -- the temp file, jq, or the
#       request to the domain failed -- so nothing was checked.
# =============================================================================

set -euo pipefail

# HTH Guide Excerpt: begin config

# Any failed step (temp file, jq, curl) exits 2, never 1: 1 means "finding".
trap 'echo "ERROR: the header check stopped before a verdict; nothing was checked (exit 2)." >&2; exit 2' ERR

# --- Emit the vercel.json headers block to a private temp file ---
HEADERS_FILE="${HTH_HEADERS_OUT:-$(mktemp "${TMPDIR:-/tmp}/hth-vercel-headers.XXXXXX")}"
cat > "${HEADERS_FILE}" << 'HEADERS_EOF'
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
          "value": "0"
        }
      ]
    }
  ]
}
HEADERS_EOF

jq -e . "${HEADERS_FILE}" >/dev/null
echo "Security headers config written to ${HEADERS_FILE}"
echo "Merge it into your project's vercel.json, then deploy."

# --- Validate deployed headers: every header above must be present ---
DOMAIN="${1:-}"
if [ -z "${DOMAIN}" ]; then
  echo "Usage: $0 <your-domain.com>   (to check a deployed domain)"
  exit 0
fi

echo ""
echo "=== Validating Security Headers for ${DOMAIN} ==="
RESPONSE_HEADERS="$(curl -fsSI "https://${DOMAIN}" | tr -d '\r')"
PROBLEMS=0
CHECKED=0
for header in $(jq -r '.headers[0].headers[].key' "${HEADERS_FILE}"); do
  CHECKED=$((CHECKED + 1))
  if printf '%s\n' "${RESPONSE_HEADERS}" | grep -qi "^${header}:"; then
    echo "  present: ${header}"
  else
    echo "  MISSING: ${header}"
    PROBLEMS=1
  fi
done
# A failed jq inside the for-list is invisible to set -e: zero names read must
# not pass as "all present".
if [ "${CHECKED}" -eq 0 ]; then
  echo "ERROR: no header names read from ${HEADERS_FILE}; nothing was checked (exit 2)." >&2
  exit 2
fi

# --- X-XSS-Protection must switch the legacy XSS auditor OFF: "1; mode=block"
#     can itself introduce XSS in otherwise safe pages (OWASP HTTP Headers
#     Cheat Sheet); the CSP above is the protection. ---
XXSS="$(printf '%s\n' "${RESPONSE_HEADERS}" | grep -i '^x-xss-protection:' | head -1 | cut -d: -f2- | sed 's/^ *//; s/ *$//')" || true
if [ -n "${XXSS}" ] && [ "${XXSS}" != "0" ]; then
  echo "  WRONG VALUE: X-XSS-Protection is '${XXSS}' -- set it to 0"
  PROBLEMS=1
fi
exit "${PROBLEMS}"

# HTH Guide Excerpt: end config
