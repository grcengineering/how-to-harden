#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: humanlayer-3.1
#   guide: https://howtoharden.com/guides/humanlayer/#31-approve-model-routing-on-every-daemon-host
#   profile: L2
#   mode: read-only
#   requires: HUMANLAYER_CODEX_GATEWAY_URL(reviewed HTTPS Responses endpoint), jq
# HTH HumanLayer 3.1 — NIST AC-4, IA-5
# Source: https://docs.humanlayer.com/guide/llm-gateways (available; checked 2026-11-05)
# Emits a candidate shell fragment, does not read a token or launch a daemon.
# Intentionally accepts HTTPS only, even though the vendor also supports HTTP loopback.
set +x
set -Eeuo pipefail
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# HTH Guide Excerpt: begin build-codex-gateway-environment
hl_level 2
hl_jq
hl_url="${HUMANLAYER_CODEX_GATEWAY_URL:-}"
[[ "$hl_url" =~ ^https://[A-Za-z0-9][A-Za-z0-9.-]*(:[0-9]{1,5})?(/[A-Za-z0-9._~/-]*)?$ && ${#hl_url} -le 2048 ]] ||
  hl_unknown 'provide a reviewed HTTPS endpoint without credentials, query, fragment or shell syntax'
hl_authority="${hl_url#https://}"
hl_authority="${hl_authority%%/*}"
if [[ "$hl_authority" == *:* ]]; then
  hl_port="${hl_authority##*:}"
  (( 10#$hl_port >= 1 && 10#$hl_port <= 65535 )) || hl_unknown 'endpoint port must be 1..65535'
fi
printf 'export CODELAYER_CODEX_BASE_URL=%s\n' "$(jq -rn --arg url "$hl_url" '$url | @sh')"
# shellcheck disable=SC2016 # This credential reference must remain literal in generated configuration.
printf '%s\n' 'export CODELAYER_CODEX_API_KEY="${HUMANLAYER_GATEWAY_TOKEN:?inject the approved gateway credential first}"'
# HTH Guide Excerpt: end build-codex-gateway-environment
