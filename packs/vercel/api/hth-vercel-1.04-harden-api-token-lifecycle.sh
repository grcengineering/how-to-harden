#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 1.4: Harden API Token Lifecycle
# Profile Level: L1 (Crawl)
# Frameworks: NIST IA-5, IA-4
# Source: https://howtoharden.com/guides/vercel/#14-harden-api-token-lifecycle
# API: GET /v6/user/tokens?limit=100 (listAuthTokens; `limit` as sent by the
#      first-party `vercel tokens ls --limit`, 1-100); GET /v9/projects/{idOrName}
#      (getProject -> oidcTokenConfig, which is a PROJECT setting). Read-only.
# Exit: 2 when the token list has a second page (the audit would be partial).
# =============================================================================

set -euo pipefail

: "${VERCEL_TOKEN:?Set VERCEL_TOKEN}"
: "${VERCEL_TEAM_ID:?Set VERCEL_TEAM_ID}"

# HTH Guide Excerpt: begin api

# curl -f: an HTTP 4xx/5xx (bad token, missing scope) aborts the audit instead
# of piping an error body into jq and printing nulls as if they were findings.
vercel_get() {
  curl -fsS -H "Authorization: Bearer ${VERCEL_TOKEN}" "https://api.vercel.com$1"
}

# --- Audit existing tokens (name, type, age, expiry -- never token material) ---
echo "=== Auditing Vercel API Tokens ==="
TOKENS_JSON="$(vercel_get "/v6/user/tokens?limit=100")"
# listAuthTokens answers with pagination{count,next,prev}, but the spec documents
# no parameter that requests the next page (the first-party CLI also stops at
# `--limit` 100). A second page therefore cannot be audited: fail closed rather
# than report a partial token list as complete.
if [ "$(printf '%s' "${TOKENS_JSON}" | jq -r '.pagination.next // empty')" != "" ]; then
  echo "ERROR: /v6/user/tokens returned more than one page -- the token audit would be partial (exit 2)." >&2
  exit 2
fi
echo "${TOKENS_JSON}" | jq '.tokens[] | {id, name, type, origin, scopes, activeAt, expiresAt}'

# --- Tokens with no expiration (security risk) ---
echo ""
echo "=== Tokens Without Expiration (ACTION REQUIRED) ==="
echo "${TOKENS_JSON}" | jq '.tokens[] | select(.expiresAt == null) | {id, name, createdAt}'

# --- Tokens Vercel has flagged as leaked ---
echo ""
echo "=== Tokens Flagged as Leaked (revoke immediately) ==="
echo "${TOKENS_JSON}" | jq '.tokens[] | select(.leakedAt != null) | {id, name, leakedAt}'

# --- OIDC federation is configured per PROJECT (oidcTokenConfig) ---
if [ -n "${VERCEL_PROJECT_ID:-}" ]; then
  echo ""
  echo "=== OIDC Federation Status for ${VERCEL_PROJECT_ID} ==="
  vercel_get "/v9/projects/${VERCEL_PROJECT_ID}?teamId=${VERCEL_TEAM_ID}" | \
    jq '{oidcTokenConfig}'
fi

# HTH Guide Excerpt: end api
