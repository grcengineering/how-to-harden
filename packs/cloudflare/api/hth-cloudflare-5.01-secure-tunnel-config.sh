#!/usr/bin/env bash
# HTH Cloudflare Control 5.1: Secure Cloudflare Tunnel Configuration
# Profile: L1 | NIST: SC-7, SC-8 | CIS: 12.1
# https://howtoharden.com/guides/cloudflare/#51-secure-cloudflare-tunnel-configuration
source "$(dirname "$0")/common.sh"

banner "5.1: Secure Cloudflare Tunnel Configuration"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "5.1 Auditing Cloudflare Tunnel configurations..."

# HTH Guide Excerpt: begin api-audit-tunnels
# List all tunnels and check configuration
TUNNELS=$(cf_get "/accounts/${CF_ACCOUNT_ID}/cfd_tunnel?is_deleted=false") || {
  fail "5.1 Unable to retrieve tunnel list"
  increment_failed
  summary
  exit 0
}

TUNNEL_COUNT=$(echo "${TUNNELS}" | jq '.result | length')
info "5.1 Found ${TUNNEL_COUNT} active tunnel(s)"

while IFS= read -r tunnel; do
  TUNNEL_ID=$(echo "${tunnel}" | jq -r '.id')
  TUNNEL_NAME=$(echo "${tunnel}" | jq -r '.name')
  TUNNEL_STATUS=$(echo "${tunnel}" | jq -r '.status')
  REMOTE_CONFIG=$(echo "${tunnel}" | jq -r '.remote_config // false')

  echo -e "  Tunnel: ${TUNNEL_NAME} (${TUNNEL_STATUS})"
  echo -e "  Config: $([ "${REMOTE_CONFIG}" = "true" ] && echo "dashboard-managed" || echo "local config")"

  # Check tunnel connections
  CONNS=$(echo "${tunnel}" | jq '.connections | length')
  echo -e "  Connections: ${CONNS}"
  echo ""
done < <(echo "${TUNNELS}" | jq -c '.result[]')
# HTH Guide Excerpt: end api-audit-tunnels

if [ "${TUNNEL_COUNT}" -gt 0 ]; then
  pass "5.1 Tunnel configuration audited"
else
  info "5.1 No tunnels configured"
fi

increment_applied
summary
