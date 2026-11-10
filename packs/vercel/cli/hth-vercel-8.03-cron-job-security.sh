#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 8.3: Cron Job Security
# Profile Level: L1 (Crawl)
# Frameworks: NIST AC-3, SI-10
# Source: https://howtoharden.com/guides/vercel/#83-cron-job-security
# CLI: vercel env add (reads the value from stdin). The secret is never
#      printed. Writing it is MUTATING and runs only with HTH_CONFIRM_ENV_WRITE=1;
#      the endpoint probe is read-only.
# Usage: [HTH_CONFIRM_ENV_WRITE=1] ./hth-vercel-8.03-cron-job-security.sh <domain> [/api/cron-path]
# =============================================================================

set -euo pipefail

# HTH Guide Excerpt: begin cli

DOMAIN="${1:-}"
CRON_PATH="${2:-/api/cron}"

# Validate the destination BEFORE any mutation. Never accept URL credentials,
# query strings, fragments, or a second origin in these hostname/path inputs.
if ! [[ "${DOMAIN}" =~ ^[A-Za-z0-9][A-Za-z0-9.-]*$ ]] ||
   ! [[ "${CRON_PATH}" =~ ^/[A-Za-z0-9/_~.-]*$ ]]; then
  echo "Usage: $0 <your-domain.com> [/api/cron-path]" >&2
  exit 2
fi

# --- Generate a strong CRON_SECRET and store it as a production env var ---
if [ "${HTH_CONFIRM_ENV_WRITE:-0}" = "1" ]; then
  : "${VERCEL_TOKEN:?Set VERCEL_TOKEN}"
  : "${VERCEL_TEAM_ID:?Set VERCEL_TEAM_ID}"
  : "${VERCEL_PROJECT_ID:?Set VERCEL_PROJECT_ID}"
  # `vercel env add` writes to the project named by VERCEL_ORG_ID + VERCEL_PROJECT_ID
  # when BOTH are set, refuses when only one is, and otherwise writes to whatever
  # project the current directory is linked to. Name the target explicitly.
  export VERCEL_ORG_ID="${VERCEL_TEAM_ID}"
  echo "=== Setting CRON_SECRET (production) on ${VERCEL_PROJECT_ID} ==="
  CRON_SECRET="$(openssl rand -hex 32)"
  printf '%s' "${CRON_SECRET}" | vercel env add CRON_SECRET production --type secret
  echo "CRON_SECRET stored in Vercel (value not displayed). Redeploy for it to take effect."
else
  echo "Skipping env write: set HTH_CONFIRM_ENV_WRITE=1 to generate and store CRON_SECRET."
fi

# --- Verify the cron endpoint rejects unauthenticated requests ---
if [ -z "${DOMAIN}" ]; then
  echo "Usage: $0 <your-domain.com> [/api/cron-path]" >&2
  exit 2
fi

echo ""
echo "=== Testing Cron Endpoint Security: https://${DOMAIN}${CRON_PATH} ==="
# curl prints 000 itself when it cannot connect, so its exit status is ignored
# rather than appending a second 000.
http_code="$(curl --max-time 15 -s -o /dev/null -w "%{http_code}" "https://${DOMAIN}${CRON_PATH}" 2>/dev/null)" || true
[ -n "${http_code}" ] || http_code="000"
if [ "${http_code}" = "000" ]; then
  echo "ERROR: endpoint could not be reached." >&2
  exit 2
fi
if [ "${http_code}" != "401" ]; then
  echo "FAIL: unauthenticated request returned ${http_code} -- expected 401."
  exit 1
fi
echo "OK: unauthenticated request returns 401"

# An authenticated GET executes the cron handler. Opt in only on an approved
# test endpoint or when executing the production job is intended.
if [ "${HTH_RUN_AUTHENTICATED_CRON:-0}" = "1" ]; then
  : "${CRON_SECRET:?Set the currently deployed CRON_SECRET}"
  http_code="$(curl --max-time 15 -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer ${CRON_SECRET}" \
    "https://${DOMAIN}${CRON_PATH}" 2>/dev/null)" || true
  [ -n "${http_code}" ] || http_code="000"
  case "${http_code}" in
    2??) echo "Authenticated cron job executed successfully (HTTP ${http_code})." ;;
    000) echo "ERROR: authenticated probe could not complete." >&2; exit 2 ;;
    *) echo "FAIL: authenticated request returned HTTP ${http_code}." >&2; exit 1 ;;
  esac
fi

# HTH Guide Excerpt: end cli
