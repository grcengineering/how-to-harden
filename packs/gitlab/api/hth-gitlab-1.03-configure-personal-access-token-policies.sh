#!/usr/bin/env bash
# HTH GitLab Control 1.3: Configure Personal Access Token Policies
# Profile: L1 | NIST: IA-5, AC-2 | SOC 2: CC6.1
# https://howtoharden.com/guides/gitlab/#13-configure-personal-access-token-policies
#
# Exit codes: 0 compliant | 1 finding | 2 precondition (an API call failed, so nothing was audited)
# Scope: an administrator token lists every user's tokens; any other token lists only
# its own (docs.gitlab.com/api/personal_access_tokens). GitLab.com has no customer
# administrator role, so on GitLab.com this audits the calling user's tokens only.
source "$(dirname "$0")/common.sh"

banner "1.3: Configure Personal Access Token Policies"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.3 Auditing active personal access tokens..."

# HTH Guide Excerpt: begin api-audit-pat-policies
# List all active personal access tokens and flag risky configurations.
# A failed page stops the audit: an empty list must mean "no tokens", never "the call failed".
info "1.3 Retrieving active personal access tokens..."
PAGE=1
ALL_PATS="[]"
while true; do
  RESPONSE=$(gl_get "/personal_access_tokens?state=active&per_page=100&page=${PAGE}") || {
    fail "1.3 GET /personal_access_tokens (page ${PAGE}) failed -- check GITLAB_URL, token validity and read_api scope"
    increment_failed; summary; exit 2
  }
  COUNT=$(printf '%s' "${RESPONSE}" | jq 'length') || {
    fail "1.3 Unparseable response on page ${PAGE}"
    increment_failed; summary; exit 2
  }
  [ "${COUNT}" -eq 0 ] && break
  ALL_PATS=$(printf '%s %s' "${ALL_PATS}" "${RESPONSE}" | jq -s 'add')
  [ "${COUNT}" -lt 100 ] && break
  PAGE=$((PAGE + 1))
done

TOTAL=$(printf '%s' "${ALL_PATS}" | jq 'length')
info "1.3 Found ${TOTAL} active personal access token(s)"

# Flag tokens with overly broad 'api' scope
API_SCOPE_PATS=$(printf '%s' "${ALL_PATS}" | jq '[.[] | select((.scopes // []) | index("api"))]')
API_SCOPE_COUNT=$(printf '%s' "${API_SCOPE_PATS}" | jq 'length')

if [ "${API_SCOPE_COUNT}" -gt 0 ]; then
  warn "1.3 Found ${API_SCOPE_COUNT} token(s) with full 'api' scope (overly permissive)"
  printf '%s' "${API_SCOPE_PATS}" | jq -r '.[] | "  - \(.name // "unnamed") (user: \(.user_id // "unknown"), created: \(.created_at // "unknown"))"'
fi

# Flag tokens with no expiration date
NO_EXPIRY_PATS=$(printf '%s' "${ALL_PATS}" | jq '[.[] | select(.expires_at == null)]')
NO_EXPIRY_COUNT=$(printf '%s' "${NO_EXPIRY_PATS}" | jq 'length')

if [ "${NO_EXPIRY_COUNT}" -gt 0 ]; then
  warn "1.3 Found ${NO_EXPIRY_COUNT} token(s) with no expiration date"
  printf '%s' "${NO_EXPIRY_PATS}" | jq -r '.[] | "  - \(.name // "unnamed") (user: \(.user_id // "unknown"), scopes: \((.scopes // []) | join(", ")))"'
fi

# Flag tokens with write_repository scope (supply chain risk)
WRITE_REPO_PATS=$(printf '%s' "${ALL_PATS}" | jq '[.[] | select((.scopes // []) | index("write_repository"))]')
WRITE_REPO_COUNT=$(printf '%s' "${WRITE_REPO_PATS}" | jq 'length')

if [ "${WRITE_REPO_COUNT}" -gt 0 ]; then
  warn "1.3 Found ${WRITE_REPO_COUNT} token(s) with 'write_repository' scope"
  printf '%s' "${WRITE_REPO_PATS}" | jq -r '.[] | "  - \(.name // "unnamed") (user: \(.user_id // "unknown"), expires: \(.expires_at // "never"))"'
fi
# HTH Guide Excerpt: end api-audit-pat-policies

if [ "${API_SCOPE_COUNT}" -gt 0 ] || [ "${NO_EXPIRY_COUNT}" -gt 0 ]; then
  fail "1.3 Found risky PAT configurations -- review tokens above and enforce expiration + least-privilege scopes"
  increment_failed
else
  pass "1.3 All ${TOTAL} active PAT(s) visible to this token avoid 'api' scope and have expiration dates"
  increment_applied
fi

summary
[ "${CONTROLS_FAILED}" -eq 0 ] || exit 1
