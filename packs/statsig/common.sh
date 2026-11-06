#!/usr/bin/env bash
# Structural helper. All transports are fixed-origin reads; no key creation/deletion.
set +x
set -Eeuo pipefail
statsig_unknown() { printf 'UNKNOWN: %s\n' "$1" >&2; exit 2; }
statsig_init() {
  local minimum="$1" profile="${HTH_PROFILE_LEVEL:-1}"
  [[ "$profile" =~ ^[1-4]$ ]] || statsig_unknown 'HTH_PROFILE_LEVEL must be 1–4'
  (( profile >= minimum )) || statsig_unknown 'profile is lower than this pack requires'
  command -v bun >/dev/null 2>&1 || statsig_unknown 'Bun is required'
  command -v jq >/dev/null 2>&1 || statsig_unknown 'jq is required'
  [[ "${STATSIG_OUTPUT:-}" == /* ]] || statsig_unknown 'set a new absolute STATSIG_OUTPUT outside source control'
  [[ ! -e "$STATSIG_OUTPUT" && ! -L "$STATSIG_OUTPUT" ]] || statsig_unknown 'output already exists'
  umask 077
  STATSIG_TEMP=$(mktemp -d) || statsig_unknown 'cannot create private temporary directory'
  trap 'rm -rf "$STATSIG_TEMP"' EXIT
  trap 'statsig_unknown "operation failed; incomplete evidence discarded"' ERR
  STATSIG_HELPER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.ts"
}
statsig_api_init() {
  statsig_init "$1"
  command -v curl >/dev/null 2>&1 || statsig_unknown 'curl is required'
  STATSIG_KEY_KIND="$2"
  case "$STATSIG_KEY_KIND" in
    console) STATSIG_CREDENTIAL="${STATSIG_CONSOLE_KEY:-}"; [[ "$STATSIG_CREDENTIAL" == console-* ]] || statsig_unknown 'inject an approved Console API key' ;;
    server) STATSIG_CREDENTIAL="${STATSIG_SERVER_KEY:-}" ;;
    *) statsig_unknown 'unsupported credential class' ;;
  esac
  [[ "$STATSIG_CREDENTIAL" =~ ^[A-Za-z0-9._~-]+$ && ${#STATSIG_CREDENTIAL} -ge 16 && ${#STATSIG_CREDENTIAL} -le 4096 ]] || statsig_unknown 'invalid credential representation'
  [[ -z "${STATSIG_BASE_URL:-}" ]] || statsig_unknown 'origin overrides are not supported'
}
statsig_request() {
  local method="$1" path="$2" out="$3" body="${4:-}" origin status
  local -a options=(--header 'STATSIG-API-VERSION: 20240601' --header 'Accept: application/json')
  case "$STATSIG_KEY_KIND:$method:$path" in
    console:GET:/console/v1/settings/project|console:GET:/console/v1/settings/reviews) origin='https://statsigapi.net' ;;
    console:GET:/console/v1/keys\?limit=100\&page=*)
      [[ "$path" =~ ^/console/v1/keys\?limit=100\&page=[0-9]{1,3}$ ]] || statsig_unknown 'invalid key-list page'
      origin='https://statsigapi.net' ;;
    server:POST:/v1/get_delete_user_data_request_status)
      [[ -f "$body" ]] || statsig_unknown 'missing status request'
      origin='https://api.statsig.com'
      options+=(--header 'Content-Type: application/json' --data-binary "@$body") ;;
    *) statsig_unknown 'unsupported operation' ;;
  esac
  if ! status=$(printf 'header = "STATSIG-API-KEY: %s"\n' "$STATSIG_CREDENTIAL" |
    curl -q --config - --silent --request "$method" --proto '=https' --tlsv1.2 \
      --connect-timeout 15 --max-time 60 --max-filesize 20971520 \
      --output "$out" --write-out '%{http_code}' "${options[@]}" "$origin$path" 2> "$STATSIG_TEMP/transport-error"); then
    statsig_unknown 'transport failed or response exceeded bounds'
  fi
  [[ "$status" == 200 ]] || statsig_unknown "HTTP $status; check project, role, key and feature eligibility"
}
statsig_finish() {
  bun "$STATSIG_HELPER" save "$1"
  printf 'COLLECTED: private evidence; no compliance or enforcement verdict.\n'
}
