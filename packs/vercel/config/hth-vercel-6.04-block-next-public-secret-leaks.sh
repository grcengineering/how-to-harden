#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 6.4: Block NEXT_PUBLIC_ Secret Leaks
# Profile Level: L1 (Crawl)
# Frameworks: NIST SC-28, SA-15, SA-11
# Source: https://howtoharden.com/guides/vercel/#64-block-next-public-secret-leaks
# Rationale: Any env var prefixed NEXT_PUBLIC_ is inlined into the client
# JavaScript bundle by Next.js. Cremit research (2025) identified live API keys
# in 0.45% of public Vercel deployments via this vector.
# Use: run in pre-commit hook and CI to fail builds that introduce the pattern.
# Reference: https://www.cremit.io/blog/vercel-secret-exposure-case-study
# Type: config -- a repository audit; it does not call the vercel CLI.
# Exit: 0 clean, 1 finding, 2 the scan itself failed.
# =============================================================================

set -euo pipefail

# HTH Guide Excerpt: begin config

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
PATTERN="$(printf '%s|' "${SECRET_NAME_PATTERNS[@]}")"
PATTERN="${PATTERN%|}"
REGEX="NEXT_PUBLIC_[A-Z0-9_]*(${PATTERN})"

EXIT_CODE=0

echo "=== Scanning for NEXT_PUBLIC_ prefix on secret-shaped names ==="
# The files that declare env vars are mostly HIDDEN or git-ignored (.env*,
# .github/workflows/), so both scanners are told to include them explicitly.
if command -v rg >/dev/null 2>&1; then
  SEARCH_CMD=(rg --hidden --no-ignore --no-heading --line-number -i
    --glob '!.git/**' --glob '!node_modules/**' --glob '!.next/**' -e "${REGEX}" .)
else
  SEARCH_CMD=(grep -rn -iE --exclude-dir=.git --exclude-dir=node_modules
    --exclude-dir=.next "${REGEX}" .)
fi

rc=0
matches="$("${SEARCH_CMD[@]}")" || rc=$?
case "${rc}" in
  0)
    echo "BLOCK: NEXT_PUBLIC_<secret-name> pattern detected — these values ship to the browser:"
    echo "${matches}"
    EXIT_CODE=1
    ;;
  1) ;;
  *)
    echo "ERROR: ${SEARCH_CMD[0]} exited ${rc}; the scan did not complete." >&2
    exit 2
    ;;
esac

# --- Audit the current build output for any NEXT_PUBLIC_* that resembles a secret ---
if [ -d ".next" ]; then
  echo ""
  echo "=== Scanning compiled .next bundle for secret-shaped NEXT_PUBLIC_ values ==="
  # grep exits 1 for "no match" and 2 when it could not read the bundle; only
  # the first means clean.
  brc=0
  bundle_matches="$(grep -rho "NEXT_PUBLIC_[A-Z0-9_]*" .next)" || brc=$?
  case "${brc}" in
    0)
      bundle_matches="$(printf '%s\n' "${bundle_matches}" | sort -u)"
      echo "NEXT_PUBLIC_ variables found in client bundle:"
      echo "${bundle_matches}"
      if echo "${bundle_matches}" | grep -qiE "(${PATTERN})"; then
        echo "BLOCK: secret-shaped NEXT_PUBLIC_ variable present in built bundle."
        EXIT_CODE=1
      fi
      ;;
    1) ;;
    *)
      echo "ERROR: grep exited ${brc} reading .next; the bundle scan did not complete." >&2
      exit 2
      ;;
  esac
fi

if [ "${EXIT_CODE}" -eq 0 ]; then
  echo "OK: no NEXT_PUBLIC_<secret> patterns detected."
fi

exit "${EXIT_CODE}"

# HTH Guide Excerpt: end config
