#!/usr/bin/env bash
# HTH Cloudflare Control 5.2: Protect Tunnels with Access Policies
# Profile: L1 | NIST: AC-3 | CIS: 6.4
# https://howtoharden.com/guides/cloudflare/#52-protect-tunnels-with-access-policies
source "$(dirname "$0")/common.sh"

banner "5.2: Protect Tunnels with Access Policies"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "5.2 Verifying tunnel endpoints have Access protection..."

# HTH Guide Excerpt: begin api-verify-tunnel-access
# Cross-reference tunnel hostnames with Access applications
TUNNELS=$(cf_get "/accounts/${CF_ACCOUNT_ID}/cfd_tunnel?is_deleted=false") || {
  fail "5.2 Unable to retrieve tunnels"
  increment_failed
  summary
  exit 0
}

APPS=$(cf_get "/accounts/${CF_ACCOUNT_ID}/access/apps") || {
  fail "5.2 Unable to retrieve Access applications"
  increment_failed
  summary
  exit 0
}

ACCESS_DOMAINS=$(echo "${APPS}" | jq -r '.result[].domain // empty')
UNPROTECTED=0

while IFS= read -r tunnel; do
  TUNNEL_NAME=$(echo "${tunnel}" | jq -r '.name')
  TUNNEL_ID=$(echo "${tunnel}" | jq -r '.id')

  # Get tunnel config to find hostnames
  CONFIG=$(cf_get "/accounts/${CF_ACCOUNT_ID}/cfd_tunnel/${TUNNEL_ID}/configurations") 2>/dev/null || continue
  HOSTNAMES=$(echo "${CONFIG}" | jq -r '.result.config.ingress[]?.hostname // empty' 2>/dev/null || true)

  for hostname in ${HOSTNAMES}; do
    [ -z "${hostname}" ] && continue
    if echo "${ACCESS_DOMAINS}" | grep -q "${hostname}"; then
      pass "5.2 Tunnel '${TUNNEL_NAME}' hostname '${hostname}' has Access protection"
    else
      warn "5.2 Tunnel '${TUNNEL_NAME}' hostname '${hostname}' has NO Access policy"
      UNPROTECTED=$((UNPROTECTED + 1))
    fi
  done
done < <(echo "${TUNNELS}" | jq -c '.result[]')
# HTH Guide Excerpt: end api-verify-tunnel-access

if [ "${UNPROTECTED}" = "0" ]; then
  pass "5.2 All tunnel endpoints have Access protection"
else
  warn "5.2 ${UNPROTECTED} tunnel endpoint(s) without Access policies -- create policies before exposing"
fi

increment_applied
summary
