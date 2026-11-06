#!/usr/bin/env bash
# Shared ChatGPT workspace Compliance GET helpers, not a standalone pack.
# Current source fetched 2026-11-05:
# https://developers.openai.com/downloads/compliance-api/download_compliance_files.sh
# No API Platform organization/audit API, no write operation, no key creation.
set -euo pipefail
umask 077
hth_die() { echo "PRECONDITION: $*" >&2; exit 2; }
hth_require() {
  command -v curl >/dev/null || hth_die 'curl required'
  command -v jq >/dev/null || hth_die 'jq required'
  [[ -n "${CHATGPT_ADMIN_KEY:-}" ]] || hth_die 'set workspace-scoped CHATGPT_ADMIN_KEY'
  [[ ! "$CHATGPT_ADMIN_KEY" =~ [[:cntrl:]] && "$CHATGPT_ADMIN_KEY" != *$'\n'* && "$CHATGPT_ADMIN_KEY" != *$'\r'* && "$CHATGPT_ADMIN_KEY" != *'"'* && "$CHATGPT_ADMIN_KEY" != *'\'* ]] || hth_die 'invalid credential characters'
  [[ "${CHATGPT_WORKSPACE_ID:-}" =~ ^[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}$ ]] || hth_die 'CHATGPT_WORKSPACE_ID must be workspace UUID'
}
hth_safe_id() { [[ "$1" =~ ^[A-Za-z0-9_-]+$ ]] || hth_die 'unsafe log ID'; }
hth_auth() { printf 'header = "Authorization: Bearer %s"\n' "$CHATGPT_ADMIN_KEY"; }
hth_get() {
  local path="$1" output="$2" code
  shift 2
  # Curl drops Authorization on cross-origin redirects; never use --location-trusted.
  code="$(hth_auth | curl -q -sS -G -L --proto '=https' --proto-redir '=https' --path-as-is -K - \
    --connect-timeout 15 --max-time 120 --retry 3 --retry-max-time 180 --max-filesize 104857600 \
    -o "$output" -w '%{http_code}' "https://api.chatgpt.com/v1${path}" "$@")" || hth_die "transport failed for ${path}; checkpoint unchanged"
  [[ "$code" = 200 ]] || hth_die "HTTP ${code} for ${path}; inspect scope/plan/rate limits; checkpoint unchanged"
}
