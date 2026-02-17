#!/usr/bin/env bash
# HTH GitLab Control 1.3: Configure Personal Access Token Policies
# Profile: L1 | NIST: IA-5, AC-2 | SOC 2: CC6.1
# https://howtoharden.com/guides/gitlab/#13-configure-personal-access-token-policies
source "$(dirname "$0")/common.sh"

banner "1.3: Configure Personal Access Token Policies"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.3 Auditing active personal access tokens..."

# HTH Guide Excerpt: begin api-audit-pat-policies
# List all active personal access tokens and flag risky configurations
info "1.3 Retrieving active personal access tokens..."
PAGE=1
ALL_PATS="[]"
while true; do
  RESPONSE=$(gl_get "/personal_access_tokens?state=active&per_page=100&page=${PAGE}" 2>/dev/null) || break
  COUNT=$(echo "${RESPONSE}" | jq 'length' 2>/dev/null || echo "0")
  [ "${COUNT}" -eq 0 ] && break
  ALL_PATS=$(echo "${ALL_PATS} ${RESPONSE}" | jq -s 'add')
  PAGE=$((PAGE + 1))
done

TOTAL=$(echo "${ALL_PATS}" | jq 'length' 2>/dev/null || echo "0")
info "1.3 Found ${TOTAL} active personal access token(s)"

# Flag tokens with overly broad 'api' scope
API_SCOPE_PATS=$(echo "${ALL_PATS}" | jq '[.[] | select(.scopes | index("api"))]' 2>/dev/null || echo "[]")
API_SCOPE_COUNT=$(echo "${API_SCOPE_PATS}" | jq 'length' 2>/dev/null || echo "0")

if [ "${API_SCOPE_COUNT}" -gt 0 ]; then
  warn "1.3 Found ${API_SCOPE_COUNT} token(s) with full 'api' scope (overly permissive)"
  echo "${API_SCOPE_PATS}" | jq -r '.[] | "  - \(.name // "unnamed") (user: \(.user_id // "unknown"), created: \(.created_at // "unknown"))"' 2>/dev/null || true
fi

# Flag tokens with no expiration date
NO_EXPIRY_PATS=$(echo "${ALL_PATS}" | jq '[.[] | select(.expires_at == null)]' 2>/dev/null || echo "[]")
NO_EXPIRY_COUNT=$(echo "${NO_EXPIRY_PATS}" | jq 'length' 2>/dev/null || echo "0")

if [ "${NO_EXPIRY_COUNT}" -gt 0 ]; then
  warn "1.3 Found ${NO_EXPIRY_COUNT} token(s) with no expiration date"
  echo "${NO_EXPIRY_PATS}" | jq -r '.[] | "  - \(.name // "unnamed") (user: \(.user_id // "unknown"), scopes: \(.scopes | join(", ")))"' 2>/dev/null || true
fi

# Flag tokens with write_repository scope (supply chain risk)
WRITE_REPO_PATS=$(echo "${ALL_PATS}" | jq '[.[] | select(.scopes | index("write_repository"))]' 2>/dev/null || echo "[]")
WRITE_REPO_COUNT=$(echo "${WRITE_REPO_PATS}" | jq 'length' 2>/dev/null || echo "0")

if [ "${WRITE_REPO_COUNT}" -gt 0 ]; then
  warn "1.3 Found ${WRITE_REPO_COUNT} token(s) with 'write_repository' scope"
  echo "${WRITE_REPO_PATS}" | jq -r '.[] | "  - \(.name // "unnamed") (user: \(.user_id // "unknown"), expires: \(.expires_at // "never"))"' 2>/dev/null || true
fi
# HTH Guide Excerpt: end api-audit-pat-policies

if [ "${API_SCOPE_COUNT}" -gt 0 ] || [ "${NO_EXPIRY_COUNT}" -gt 0 ]; then
  fail "1.3 Found risky PAT configurations -- review tokens above and enforce expiration + least-privilege scopes"
  increment_failed
else
  pass "1.3 All active PATs follow least-privilege and have expiration dates"
  increment_applied
fi

summary
