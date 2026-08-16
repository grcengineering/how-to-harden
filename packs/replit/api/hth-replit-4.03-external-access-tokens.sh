#!/usr/bin/env bash
# Control: 4.3 Govern External Access Tokens (the private-app bypass credential)
# Profile Level: L2 (Walk) | Plans: Core, Pro (Enterprise requires Replit opt-in)
# Frameworks: NIST 800-53 IA-5/AC-6 | CIS Controls v8 6.1/16.9
# Guide: https://howtoharden.com/guides/replit/#43-govern-external-access-tokens-the-private-app-bypass-credential
# Interface: External access tokens — https://docs.replit.com/features/deployment-customization/external-access-tokens
#   Tokens are CREATED in the console: Publishing tool -> Adjust settings -> Security ->
#   External access tokens -> Create access token. There is no documented token-management
#   API; this pack covers correct USAGE and CI hygiene, not token issuance.
set -euo pipefail

: "${REPLIT_EXTERNAL_TOKEN:?Set REPLIT_EXTERNAL_TOKEN from your secret manager — never inline it}"
: "${REPLIT_APP_URL:?Set REPLIT_APP_URL (e.g. https://myapp.replit.app)}"

# HTH Guide Excerpt: begin token-bearer-usage
# CORRECT: send the token as an Authorization Bearer header.
# The docs also permit ?project-protection-bypass=<token>, but a credential in a URL leaks to
# server logs, proxy logs, browser history, and Referer headers — use the header form only.
curl -fsS "${REPLIT_APP_URL}/healthz" \
  -H "Authorization: Bearer ${REPLIT_EXTERNAL_TOKEN}" \
  -H "Accept: application/json"
# HTH Guide Excerpt: end token-bearer-usage

# HTH Guide Excerpt: begin token-ci-hygiene-scan
# CI hygiene gate: fail the build if any tracked file uses the query-parameter form or
# hardcodes a token. Run this in the pipeline that deploys Replit-hosted apps.
FAIL=0
if git grep -nE 'project-protection-bypass=' -- . >/dev/null 2>&1; then
  echo "FAIL 4.3: query-parameter token form found (credential will leak to logs):"
  git grep -nE 'project-protection-bypass=' -- .
  FAIL=1
fi
# Replit external tokens are opaque; catch obvious inline Bearer literals in tracked files.
if git grep -nE 'Authorization:[[:space:]]*Bearer[[:space:]]+[A-Za-z0-9._-]{20,}' -- . >/dev/null 2>&1; then
  echo "FAIL 4.3: hardcoded Bearer literal found — move it to a secret manager:"
  git grep -nE 'Authorization:[[:space:]]*Bearer[[:space:]]+[A-Za-z0-9._-]{20,}' -- .
  FAIL=1
fi
[ "${FAIL}" -eq 0 ] && echo "PASS 4.3: no query-param tokens or inline Bearer literals in tracked files."
exit "${FAIL}"
# HTH Guide Excerpt: end token-ci-hygiene-scan

# HTH Guide Excerpt: begin token-rotation-notes
# Operational rules transcribed from the docs — encode these in your runbook:
#   * One token = one environment: Development (*.replit.dev) OR Production
#     (*.replit.app + custom domains). Production tokens bind to a specific deployment.
#   * PRODUCTION TOKENS ARE INVALIDATED ON REPUBLISH — plan re-issuance into the deploy job.
#   * Expiry choices: 1 hour, 24 hours, 7 days, 30 days, 3 months, 1 year, 5 years.
#     There is no permanent option; prefer <= 30 days for CI. Do not pick 5 years.
#   * Revocation is immediate and irreversible, and ONLY the token's creator can revoke it.
#     Removing a collaborator auto-revokes their tokens — verify this during offboarding.
# HTH Guide Excerpt: end token-rotation-notes
