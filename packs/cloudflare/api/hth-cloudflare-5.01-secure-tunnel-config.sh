#!/usr/bin/env bash
# HTH Cloudflare Control 5.1: Secure Cloudflare Tunnel Configuration
# Profile: L1 | NIST: SC-7, SC-8 | CIS: 12.1
# https://howtoharden.com/guides/cloudflare/#51-secure-cloudflare-tunnel-configuration
#
# Read-only audit. Flags tunnels that are locally managed (config_src "local",
# so their ingress rules cannot be audited from the API) and tunnels that are
# not healthy. The final PASS is printed only when at least one tunnel was
# checked and none was flagged.
source "$(dirname "$0")/common.sh"

banner "5.1: Secure Cloudflare Tunnel Configuration"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "5.1 Auditing Cloudflare Tunnel configurations..."

# HTH Guide Excerpt: begin api-audit-tunnels
# List all tunnels and check configuration
TUNNELS=$(cf_get_all "/accounts/${CF_ACCOUNT_ID}/cfd_tunnel?is_deleted=false") || {
  fail "5.1 Unable to retrieve tunnel list"
  increment_failed
  summary
  exit 0
}

TUNNEL_COUNT=$(echo "${TUNNELS}" | jq '.result | length')
info "5.1 Found ${TUNNEL_COUNT} active tunnel(s)"

FLAGGED=0
while IFS= read -r tunnel; do
  TUNNEL_NAME=$(echo "${tunnel}" | jq -r '.name')
  TUNNEL_STATUS=$(echo "${tunnel}" | jq -r '.status // "unknown"')
  REMOTE_CONFIG=$(echo "${tunnel}" | jq -r 'if .remote_config == true or .config_src == "cloudflare" then "true" else "false" end')
  CONNS=$(echo "${tunnel}" | jq '.connections // [] | length')

  info "5.1 Tunnel '${TUNNEL_NAME}': status=${TUNNEL_STATUS}, connections=${CONNS}"
  if [ "${REMOTE_CONFIG}" != "true" ]; then
    warn "5.1 Tunnel '${TUNNEL_NAME}' is locally managed -- its ingress rules cannot be audited here"
    FLAGGED=$((FLAGGED + 1))
  fi
  if [ "${TUNNEL_STATUS}" != "healthy" ]; then
    warn "5.1 Tunnel '${TUNNEL_NAME}' is ${TUNNEL_STATUS} -- remove unused tunnels and their credentials"
    FLAGGED=$((FLAGGED + 1))
  fi
done < <(echo "${TUNNELS}" | jq -c '.result[]')
# HTH Guide Excerpt: end api-audit-tunnels

if [ "${TUNNEL_COUNT}" = "0" ]; then
  info "5.1 No tunnels configured -- nothing was checked"
  increment_skipped
elif [ "${FLAGGED}" = "0" ]; then
  pass "5.1 All ${TUNNEL_COUNT} tunnel(s) are dashboard-managed and healthy"
  increment_applied
else
  fail "5.1 ${FLAGGED} tunnel finding(s)"
  increment_failed
fi

summary
