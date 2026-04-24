#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 6.4: Block NEXT_PUBLIC_ Secret Leaks
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-28, SA-15, SA-11
# Source: https://howtoharden.com/guides/vercel/#64-block-next-public-secret-leaks
# Rationale: Any env var prefixed NEXT_PUBLIC_ is inlined into the client
# JavaScript bundle by Next.js. Cremit research (2025) identified live API keys
# in 0.45% of public Vercel deployments via this vector.
# Use: run in pre-commit hook and CI to fail builds that introduce the pattern.
# Reference: https://www.cremit.io/blog/vercel-secret-exposure-case-study
# =============================================================================

set -euo pipefail

# HTH Guide Excerpt: begin cli

# Names that commonly hold secrets. If any are prefixed NEXT_PUBLIC_, fail.
# Patterns match variable NAMES (pre-equals or pre-colon), not values.
SECRET_NAME_PATTERNS=(
  "SECRET"
  "PRIVATE"
  "API_KEY"
  "APIKEY"
  "TOKEN"
  "PASSWORD"
  "PASSWD"
  "CREDENTIAL"
  "CLIENT_SECRET"
  "WEBHOOK_SECRET"
  "SIGNING_KEY"
  "PRIVATE_KEY"
  "DATABASE_URL"
  "DB_URL"
  "DB_PASSWORD"
  "AWS_SECRET_ACCESS_KEY"
  "SERVICE_ACCOUNT"
  "OAUTH_SECRET"
  "SESSION_SECRET"
  "JWT_SECRET"
  "ENCRYPTION_KEY"
  "STRIPE_SECRET"
  "SENDGRID_API_KEY"
  "OPENAI_API_KEY"
  "ANTHROPIC_API_KEY"
)

# Build a single case-insensitive alternation
IFS='|' PATTERN="$(printf '%s|' "${SECRET_NAME_PATTERNS[@]}")"
PATTERN="${PATTERN%|}"

# Search files that typically declare env vars
TARGETS=(
  '.env*'
  '*.env'
  'next.config.*'
  'vercel.json'
  'turbo.json'
  '*.tf'
  '.github/workflows/*.yml'
  '.github/workflows/*.yaml'
)

EXIT_CODE=0

echo "=== Scanning for NEXT_PUBLIC_ prefix on secret-shaped names ==="
# Ripgrep if available (faster); fall back to grep
if command -v rg >/dev/null 2>&1; then
  SEARCH_CMD=(rg --no-heading --line-number -i -e "NEXT_PUBLIC_[A-Z0-9_]*(${PATTERN})")
else
  SEARCH_CMD=(grep -rn -iE "NEXT_PUBLIC_[A-Z0-9_]*(${PATTERN})")
fi

# Run against working-tree; in CI, also consider the diff.
if matches="$("${SEARCH_CMD[@]}" . 2>/dev/null)"; then
  if [ -n "${matches}" ]; then
    echo "BLOCK: NEXT_PUBLIC_<secret-name> pattern detected — these values ship to the browser:"
    echo "${matches}"
    EXIT_CODE=1
  fi
fi

# --- Audit the current build output for any NEXT_PUBLIC_* that resembles a secret ---
if [ -d ".next" ]; then
  echo ""
  echo "=== Scanning compiled .next bundle for secret-shaped NEXT_PUBLIC_ values ==="
  if bundle_matches="$(grep -rho "NEXT_PUBLIC_[A-Z0-9_]*" .next 2>/dev/null | sort -u)"; then
    echo "NEXT_PUBLIC_ variables found in client bundle:"
    echo "${bundle_matches}"
    if echo "${bundle_matches}" | grep -qiE "(${PATTERN})"; then
      echo "BLOCK: secret-shaped NEXT_PUBLIC_ variable present in built bundle."
      EXIT_CODE=1
    fi
  fi
fi

if [ "${EXIT_CODE}" -eq 0 ]; then
  echo "OK: no NEXT_PUBLIC_<secret> patterns detected."
fi

exit "${EXIT_CODE}"

# HTH Guide Excerpt: end cli
