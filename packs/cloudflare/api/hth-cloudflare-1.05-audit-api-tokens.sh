#!/usr/bin/env bash
# HTH Cloudflare Control 1.5: Retire the Global API Key and Enforce Scoped API Tokens
# Profile: L1 | NIST: AC-6(1), IA-5 | CIS: 5.4, 6.8
# https://howtoharden.com/guides/cloudflare/#15-retire-the-global-api-key-and-enforce-scoped-api-tokens
#
# Read-only audit of API tokens: the calling user's tokens (GET /user/tokens)
# and the account's tokens (GET /accounts/{id}/tokens). Every active token
# should carry an expiry (expires_on) and a client IP restriction
# (condition.request_ip.in). The API cannot show where a Global API Key is
# used -- search for X-Auth-Email / X-Auth-Key headers as the guide describes.
# Token permissions needed: "API Tokens Read" (user) and "Account API Tokens
# Read" (account). Every page of both lists is read (result_info); if either
# list, or any page of it, cannot be read the audit FAILs.
source "$(dirname "$0")/common.sh"

banner "1.5: Retire the Global API Key and Enforce Scoped API Tokens"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.5 Auditing API token expiry and IP restrictions..."

# HTH Guide Excerpt: begin api-audit-tokens
# Flag active tokens that never expire or accept requests from any IP
FINDINGS=0
FETCH_ERR=0
for scope in "/user/tokens" "/accounts/${CF_ACCOUNT_ID}/tokens"; do
  TOKENS=$(cf_get_all "${scope}") || {
    fail "1.5 Unable to list tokens at ${scope}"
    FETCH_ERR=1
    continue
  }
  ACTIVE=$(echo "${TOKENS}" | jq '[.result[] | select(.status == "active")] | length')
  NO_EXPIRY=$(echo "${TOKENS}" | jq -r '.result[] | select(.status == "active") | select((.expires_on // "") == "") | .name')
  NO_IP=$(echo "${TOKENS}" | jq -r '.result[] | select(.status == "active") | select(((.condition.request_ip.in // []) | length) == 0) | .name')
  info "1.5 ${scope}: ${ACTIVE} active token(s)"
  while IFS= read -r name; do
    [ -z "${name}" ] && continue
    warn "1.5 Token '${name}' has no expiry (TTL)"
    FINDINGS=$((FINDINGS + 1))
  done < <(printf '%s\n' "${NO_EXPIRY}")
  while IFS= read -r name; do
    [ -z "${name}" ] && continue
    warn "1.5 Token '${name}' has no client IP restriction"
    FINDINGS=$((FINDINGS + 1))
  done < <(printf '%s\n' "${NO_IP}")
done
# HTH Guide Excerpt: end api-audit-tokens

if [ "${FETCH_ERR}" = "1" ]; then
  fail "1.5 Audit incomplete -- one or more token lists could not be read"
  increment_failed
elif [ "${FINDINGS}" = "0" ]; then
  pass "1.5 Every active token has an expiry and a client IP restriction"
  increment_applied
else
  fail "1.5 ${FINDINGS} token finding(s)"
  increment_failed
fi

summary
