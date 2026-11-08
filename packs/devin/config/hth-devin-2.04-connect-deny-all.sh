#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-2.4
#   guide: https://howtoharden.com/guides/devin/#24-constrain-devin-connect-routes-and-gateway-identity
#   profile: L3
#   mode: read-only
#   requires: jq; confirmed Tunnel endpoint, gateway ID and mounted token-file path
# Source: https://docs.devin.ai/enterprise/deployment/devin-connect (2026-11-05)
# HTH Guide Excerpt: begin connect-deny-all
set +x
set -Eeuo pipefail
umask 077
unknown() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
case "${HTH_PROFILE_LEVEL:-1}" in 3|4) ;; *) unknown 'HTH_PROFILE_LEVEL=3..4 required before generation' ;; esac
command -v jq >/dev/null || unknown 'jq is required'
[[ "${DEVIN_CONNECT_ENDPOINT:-}" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]+:443$ ]] || unknown 'supply the confirmed host:443 Tunnel endpoint (without a scheme)'
[[ "${DEVIN_CONNECT_GATEWAY_ID:-}" =~ ^[a-zA-Z0-9_-]+$ ]] || unknown 'supply the confirmed gateway ID'
[[ "${DEVIN_CONNECT_TOKEN_FILE:-}" =~ ^/[a-zA-Z0-9_./-]+$ ]] || unknown 'supply the protected absolute token-file path, never the token'
# JSON strings are valid YAML scalars. Empty routes intentionally deny all.
printf 'schema_version: 1\nadmin_listen: "127.0.0.1:9090"\nroutes: []\ntunnel:\n'
printf '  endpoint: %s\n' "$(jq -Rn --arg v "$DEVIN_CONNECT_ENDPOINT" '$v')"
printf '  gateway_id: %s\n' "$(jq -Rn --arg v "$DEVIN_CONNECT_GATEWAY_ID" '$v')"
printf '  auth_token_file: %s\n' "$(jq -Rn --arg v "$DEVIN_CONNECT_TOKEN_FILE" '$v')"
printf 'EMITTED ONLY: no enrollment, daemon start or policy deployment; add reviewed exact routes and ports before approved use.\n' >&2
# HTH Guide Excerpt: end connect-deny-all
