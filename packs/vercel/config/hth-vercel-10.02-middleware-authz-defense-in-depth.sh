#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 10.2: Verify Authorization Defense in Depth
# Profile Level: L1 (Crawl)
# Frameworks: NIST AC-3, SI-10
# Source: https://howtoharden.com/guides/vercel/#102-middleware-authz-defense-in-depth
# Rationale: CVE-2025-29927 proved that middleware is not a security boundary.
# Authorization must also be enforced inside Route Handlers, Server Components,
# and Server Actions. This script scans the repo for middleware-only authz
# patterns and flags them for review. Next.js 16 renamed middleware.ts to
# proxy.ts (https://nextjs.org/docs/app/api-reference/file-conventions/proxy);
# both names are checked.
# Type: config -- a repository audit; it does not call the vercel CLI.
# Exit: 0 clean, 1 finding, 2 the Server Action scan failed.
# =============================================================================

set -euo pipefail

# HTH Guide Excerpt: begin config

ROOT="${1:-.}"
EXIT_CODE=0

echo "=== Scanning for middleware-only authorization patterns in ${ROOT} ==="

# 1. Locate the middleware / proxy file
MIDDLEWARE=""
for base in middleware proxy; do
  for candidate in "${ROOT}/${base}.ts" "${ROOT}/${base}.js" \
                   "${ROOT}/src/${base}.ts" "${ROOT}/src/${base}.js"; do
    if [ -f "${candidate}" ]; then
      MIDDLEWARE="${candidate}"
      break 2
    fi
  done
done

if [ -z "${MIDDLEWARE}" ]; then
  echo "(no middleware.* or proxy.* file found — no middleware-only risk to flag)"
  exit 0
fi

echo "Found: ${MIDDLEWARE}"

# 2. Does it reference auth/session/token checks?
if ! grep -qiE "(auth|session|token|cookie|jwt|role|permission)" "${MIDDLEWARE}"; then
  echo "OK: ${MIDDLEWARE} does not appear to perform authorization."
  exit 0
fi

echo "NOTE: ${MIDDLEWARE} appears to gate auth. Verifying route-level defense in depth..."

# 3. Matched paths: array form  matcher: ['/a/:path*', '/b']  or string form  matcher: '/a/:path*'
MATCHER_PATHS="$( { grep -oE "matcher:[[:space:]]*\[[^]]+\]" "${MIDDLEWARE}" || true; } | \
  tr -d "'\"[]" | sed 's/^matcher:[[:space:]]*//' | tr ',' '\n' | awk 'NF {print $1}')"
if [ -z "${MATCHER_PATHS}" ]; then
  MATCHER_PATHS="$( { grep -oE "matcher:[[:space:]]*['\"][^'\"]+['\"]" "${MIDDLEWARE}" || true; } | \
    sed -E "s/^matcher:[[:space:]]*['\"]//; s/['\"]$//")"
fi
if [ -z "${MATCHER_PATHS}" ]; then
  echo "WARN: cannot detect matcher paths — cannot verify coverage."
  EXIT_CODE=1
else
  echo "Matcher paths:"
  printf '%s\n' "${MATCHER_PATHS}" | sed 's/^/  /'
fi

# 4. Every Route Handler under app/ must also check auth itself
if [ -d "${ROOT}/app" ] || [ -d "${ROOT}/src/app" ]; then
  APP_DIR="${ROOT}/app"
  [ -d "${ROOT}/src/app" ] && APP_DIR="${ROOT}/src/app"

  # One path per line, read verbatim: an unquoted $(find) list would split
  # "app/my reports/route.ts" at the space and treat a dynamic segment such as
  # app/users/[id]/route.ts as a glob (matching app/users/d/route.ts instead).
  HANDLERS="$(find "${APP_DIR}" -type f \( -name 'route.ts' -o -name 'route.js' \))"
  while IFS= read -r handler; do
    [ -n "${handler}" ] || continue
    if ! grep -qiE "(auth|session|getServerSession|getUser|token|cookie|unauthorized|redirect)" "${handler}"; then
      echo "WARN: ${handler} has no apparent in-handler authorization check."
      EXIT_CODE=1
    fi
  done < <(printf '%s\n' "${HANDLERS}")
fi

# 5. Server Actions ('use server' / "use server") that lack auth checks.
#    grep is the fallback when rg is absent -- the scan never silently skips.
USE_SERVER_RE="[\"']use server[\"']"
rc=0
if command -v rg >/dev/null 2>&1; then
  ACTION_FILES="$(rg -l --glob '!node_modules/**' --glob '!.next/**' -e "${USE_SERVER_RE}" "${ROOT}")" || rc=$?
else
  ACTION_FILES="$(grep -rlE --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=.git "${USE_SERVER_RE}" "${ROOT}")" || rc=$?
fi
if [ "${rc}" -gt 1 ]; then
  echo "ERROR: Server Action scan failed (exit ${rc})." >&2
  exit 2
fi
while IFS= read -r action_file; do
  [ -n "${action_file}" ] || continue
  if ! grep -qiE "(auth|session|getServerSession|getUser|unauthorized|throw)" "${action_file}"; then
    echo "WARN: Server Action file ${action_file} lacks authorization check."
    EXIT_CODE=1
  fi
done < <(printf '%s\n' "${ACTION_FILES}")

if [ "${EXIT_CODE}" -eq 0 ]; then
  echo "OK: route-level defense in depth appears present."
else
  echo ""
  echo "Per CVE-2025-29927, middleware CAN be bypassed. Enforce authz a second"
  echo "time inside Route Handlers, Server Components, and Server Actions."
fi

exit "${EXIT_CODE}"

# HTH Guide Excerpt: end config
