#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: poke-3.2
#   guide: https://howtoharden.com/guides/poke/#32-bound-local-development-tunnels
#   profile: L2
#   mode: mutating
#   requires: trusted preinstalled poke; reviewed loopback MCP service; explicit --start
# Source: https://poke.com/docs/mcp-servers (2026-11-05)
# HTH Guide Excerpt: begin attended-tunnel
set +x
set -Eeuo pipefail
unknown() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
case "${HTH_PROFILE_LEVEL:-1}" in 2|3|4) ;; *) unknown 'HTH_PROFILE_LEVEL=2..4 required before preview or tunnel start' ;; esac
[[ $# == 2 || ( $# == 3 && "$3" == --start ) ]] || unknown 'usage: attended-tunnel.sh http://127.0.0.1:PORT/mcp NAME [--start]'
# Intentionally supported subset; no URL credentials, query secrets or arbitrary hosts.
[[ "$1" =~ ^http://(127\.0\.0\.1|localhost):([0-9]{1,5})/[A-Za-z0-9_/-]+$ ]] || unknown 'only a reviewed HTTP loopback endpoint without query/fragment is accepted'
port="${BASH_REMATCH[2]}"
(( 10#$port >= 1 && 10#$port <= 65535 )) || unknown 'port out of range'
[[ "$2" =~ ^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$ ]] || unknown 'invalid tunnel name'
[[ ${3:-} == --start ]] || { printf 'PREVIEW ONLY: npx --no-install poke tunnel %s -n %s\n' "$1" "$2"; exit 0; }
command -v npx >/dev/null || unknown 'approved local poke package and npx required'
printf 'Starting attended tunnel; Ctrl+C stops it. MCP server must already be independently secured.\n' >&2
exec env npm_config_offline=true npm_config_yes=false npx --no-install poke tunnel "$1" -n "$2"
# HTH Guide Excerpt: end attended-tunnel
