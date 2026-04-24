#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 10.2: Verify Authorization Defense in Depth
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-3, SI-10
# Source: https://howtoharden.com/guides/vercel/#102-middleware-authz-defense-in-depth
# Rationale: CVE-2025-29927 proved that middleware is not a security boundary.
# Authorization must also be enforced inside Route Handlers, Server Components,
# and Server Actions. This script scans the repo for middleware-only authz
# patterns and flags them for review.
# =============================================================================

set -euo pipefail

# HTH Guide Excerpt: begin cli

ROOT="${1:-.}"
EXIT_CODE=0

echo "=== Scanning for middleware-only authorization patterns in ${ROOT} ==="

# 1. Locate a middleware file
MIDDLEWARE=""
for candidate in \
  "${ROOT}/middleware.ts" "${ROOT}/middleware.js" \
  "${ROOT}/src/middleware.ts" "${ROOT}/src/middleware.js"; do
  if [ -f "${candidate}" ]; then
    MIDDLEWARE="${candidate}"
    break
  fi
done

if [ -z "${MIDDLEWARE}" ]; then
  echo "(no middleware file found — no middleware-only risk to flag)"
  exit 0
fi

echo "Found middleware: ${MIDDLEWARE}"

# 2. Does middleware reference auth/session/token checks?
if ! grep -qiE "(auth|session|token|cookie|jwt|role|permission)" "${MIDDLEWARE}"; then
  echo "OK: middleware does not appear to perform authorization."
  exit 0
fi

echo "NOTE: middleware appears to gate auth. Verifying route-level defense in depth..."

# 3. Find protected route handlers (app/*/route.ts, app/*/page.tsx under matched paths)
MATCHER_PATHS=$(grep -oE "matcher:\s*\[[^]]+\]" "${MIDDLEWARE}" | tr -d "'\"[]" | tr ',' '\n' | awk 'NF')
if [ -z "${MATCHER_PATHS}" ]; then
  echo "WARN: cannot detect middleware matcher paths — cannot verify coverage."
  EXIT_CODE=1
fi

# 4. For each Route Handler under app/, ensure it also checks auth
if [ -d "${ROOT}/app" ] || [ -d "${ROOT}/src/app" ]; then
  APP_DIR="${ROOT}/app"
  [ -d "${ROOT}/src/app" ] && APP_DIR="${ROOT}/src/app"

  while IFS= read -r handler; do
    if ! grep -qiE "(auth|session|getServerSession|getUser|token|cookie|unauthorized|redirect)" "${handler}"; then
      echo "WARN: ${handler} has no apparent in-handler authorization check."
      EXIT_CODE=1
    fi
  done < <(find "${APP_DIR}" -type f \( -name 'route.ts' -o -name 'route.js' \) 2>/dev/null)
fi

# 5. Flag Server Actions ("use server") that lack auth checks
if command -v rg >/dev/null 2>&1; then
  while IFS= read -r action_file; do
    if ! grep -qiE "(auth|session|getServerSession|getUser|unauthorized|throw)" "${action_file}"; then
      echo "WARN: Server Action file ${action_file} lacks authorization check."
      EXIT_CODE=1
    fi
  done < <(rg -l '"use server"' "${ROOT}" 2>/dev/null || true)
fi

if [ "${EXIT_CODE}" -eq 0 ]; then
  echo "OK: route-level defense in depth appears present."
else
  echo ""
  echo "Per CVE-2025-29927, middleware CAN be bypassed. Enforce authz a second"
  echo "time inside Route Handlers, Server Components, and Server Actions."
fi

exit "${EXIT_CODE}"

# HTH Guide Excerpt: end cli
