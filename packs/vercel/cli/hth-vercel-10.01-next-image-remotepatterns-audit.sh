#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 10.1: Audit /_next/image remotePatterns Allowlist
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-7, SI-10
# Source: https://howtoharden.com/guides/vercel/#101-audit-next-image-remotepatterns
# Rationale: The /_next/image endpoint performs server-side fetch() against
# URLs matching remotePatterns. Wildcards in remotePatterns enable SSRF
# (CVE-2025-57822, CVE-2025-6087). Treat remotePatterns as an explicit allowlist.
# =============================================================================

set -euo pipefail

# HTH Guide Excerpt: begin cli

CONFIG_FILE=""
for candidate in next.config.js next.config.mjs next.config.ts next.config.cjs; do
  if [ -f "${candidate}" ]; then
    CONFIG_FILE="${candidate}"
    break
  fi
done

if [ -z "${CONFIG_FILE}" ]; then
  echo "No next.config.* detected — skipping /_next/image audit."
  exit 0
fi

echo "=== Auditing ${CONFIG_FILE} for permissive remotePatterns ==="

FOUND_ISSUES=0

# Rule 1: hostname wildcards like '**' or 'https://*'
if grep -nE "hostname:\s*['\"](\*\*|\*)['\"]" "${CONFIG_FILE}"; then
  echo "BLOCK: bare hostname wildcard in remotePatterns."
  FOUND_ISSUES=1
fi

# Rule 2: protocol-only wildcards like protocol: '*'
if grep -nE "protocol:\s*['\"]\*['\"]" "${CONFIG_FILE}"; then
  echo "BLOCK: wildcard protocol in remotePatterns."
  FOUND_ISSUES=1
fi

# Rule 3: any http:// (non-TLS) remote pattern
if grep -nE "protocol:\s*['\"]http['\"]" "${CONFIG_FILE}"; then
  echo "WARN: http:// protocol in remotePatterns — prefer https:// only."
  FOUND_ISSUES=1
fi

# Rule 4: missing pathname (allows any path under a host)
if grep -qE "remotePatterns" "${CONFIG_FILE}" && ! grep -qE "pathname:" "${CONFIG_FILE}"; then
  echo "WARN: remotePatterns present but no pathname: restriction — any path is allowed."
  FOUND_ISSUES=1
fi

# Rule 5: images.domains (deprecated, no pattern granularity)
if grep -nE "^\s*domains:\s*\[" "${CONFIG_FILE}"; then
  echo "WARN: images.domains is deprecated and wildcard-prone. Migrate to remotePatterns."
  FOUND_ISSUES=1
fi

if [ "${FOUND_ISSUES}" -eq 0 ]; then
  echo "OK: ${CONFIG_FILE} /_next/image configuration is restrictive."
else
  echo ""
  echo "Recommended shape:"
  cat <<'TEMPLATE'
  images: {
    remotePatterns: [
      { protocol: 'https', hostname: 'cdn.example.com', pathname: '/images/**' },
      { protocol: 'https', hostname: 'avatars.example.com', pathname: '/users/**' },
    ],
  }
TEMPLATE
  exit 1
fi

# HTH Guide Excerpt: end cli
