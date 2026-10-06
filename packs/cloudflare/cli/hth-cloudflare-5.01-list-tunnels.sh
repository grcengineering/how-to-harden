#!/usr/bin/env bash
# HTH Cloudflare Control 5.1: Secure Cloudflare Tunnel Configuration
# Profile: L1 | NIST: SC-7, SC-8 | CIS: 12.1
# https://howtoharden.com/guides/cloudflare/#51-secure-cloudflare-tunnel-configuration
#
# Read-only inventory with the first-party cloudflared CLI. `cloudflared tunnel
# list` authenticates with the origin certificate created by
# `cloudflared tunnel login` (TUNNEL_ORIGIN_CERT or --origincert). Tunnels
# with no active connections are a [FAIL] (exit 1): an idle tunnel still has
# valid credentials in circulation and should be deleted. An account with no
# tunnels is a [SKIP] (exit 0), never a pass -- nothing was checked.
# Reference: developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/local-management/tunnel-useful-commands/
set -euo pipefail

command -v cloudflared >/dev/null 2>&1 || { echo "[FAIL] 5.1 cloudflared is not installed"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "[FAIL] 5.1 jq is not installed"; exit 1; }

# HTH Guide Excerpt: begin cli-list-tunnels
# List active tunnels as JSON and flag any with no live connections
TUNNELS=$(cloudflared tunnel list --output json) || {
  echo "[FAIL] 5.1 cloudflared tunnel list failed (run 'cloudflared tunnel login' or set TUNNEL_ORIGIN_CERT)"
  exit 1
}

# Anything but a JSON list of tunnel objects means the listing cannot be trusted
COUNT=$(echo "${TUNNELS}" | jq 'if type == "array" and all(.[]; type == "object")
  then length else error("not a list of tunnels") end' 2>/dev/null) || {
  echo "[FAIL] 5.1 cloudflared tunnel list did not return a JSON list of tunnels"
  exit 1
}
if [ "${COUNT}" -eq 0 ]; then
  echo "[SKIP] 5.1 No tunnels in this account -- nothing was checked"
  exit 0
fi

echo "${TUNNELS}" | jq -r '.[] | "  - \(.name) (\(.id)): \((.connections // []) | length) connection(s)"'
IDLE=$(echo "${TUNNELS}" | jq '[.[] | select(((.connections // []) | length) == 0)] | length')
# HTH Guide Excerpt: end cli-list-tunnels

if [ "${IDLE}" -gt 0 ]; then
  echo "[FAIL] 5.1 ${IDLE} of ${COUNT} tunnel(s) have no active connections -- delete unused tunnels: cloudflared tunnel delete <NAME>"
  exit 1
fi
echo "[PASS] 5.1 ${COUNT} tunnel(s), all with active connections"
