#!/usr/bin/env bash
# GET-only transport. Credentials use curl stdin config, never process arguments.
set -euo pipefail
openai_require_admin() { : "${OPENAI_ADMIN_KEY:?Inject an Admin API key through your approved secret manager}"; }
openai_checked_base() {
  local base="${OPENAI_BASE_URL:-https://api.openai.com/v1}" port
  case "$base" in
    https://api.openai.com/v1|https://us.api.openai.com/v1|https://eu.api.openai.com/v1) ;;
    *)
      if [[ "${HTH_FIXTURE_LOOPBACK:-}" == 1 && "$base" =~ ^http://127\.0\.0\.1:([0-9]{1,5})/v1$ ]]; then
        port=$((10#${BASH_REMATCH[1]})); ((port >= 1 && port <= 65535)) || return 2
      else echo 'Refusing an unapproved API base URL' >&2; return 2; fi ;;
  esac
  printf '%s' "$base"
}
openai_http_to_file() {
  local path="$1" output="$2" base token quoted protocol status bytes LC_ALL=C
  shift 2
  base=$(openai_checked_base) || return 2
  token="${OPENAI_ADMIN_KEY:-${OPENAI_API_KEY:-}}"
  if [[ -z "$token" || ${#token} -gt 8192 || "$token" == *[[:cntrl:]]* ]]; then
    echo 'Missing or unsafe API credential representation' >&2; return 2
  fi
  quoted=${token//\\/\\\\}; quoted=${quoted//\"/\\\"}
  protocol='=https'; [[ "$base" != http:* ]] || protocol='=http'
  # -q must be first: ignore curlrc. No redirects or raw vendor errors.
  if ! status=$(printf 'header = "Authorization: Bearer %s"\n' "$quoted" |
    curl -q --config - --proto "$protocol" --proto-redir '=https' \
      --connect-timeout 5 --max-time 30 --max-filesize 8388608 --silent \
      --get "${base}${path}" --output "$output" --write-out '%{http_code}' "$@" 2>/dev/null); then
    echo 'API transport failed; response body withheld' >&2; return 1
  fi
  bytes=$(wc -c < "$output")
  if [[ ! "$status" =~ ^[0-9]{3}$ ]] || ((bytes > 8388608)); then
    echo 'Invalid or oversized API response' >&2; return 1
  fi
  printf '%s' "$status"
}
openai_get() (
  umask 077
  work=$(mktemp -d) || exit 1
  trap 'rm -rf "$work"' EXIT
  status=$(openai_http_to_file "$1" "$work/body" "${@:2}") || exit 1
  [[ "$status" == 200 ]] || { echo "API request failed: HTTP $status; response body withheld" >&2; exit 1; }
  cat "$work/body"
)
openai_list() (
  umask 077
  work=$(mktemp -d) || exit 1
  trap 'rm -rf "$work"' EXIT
  : > "$work/rows"; : > "$work/cursors"
  path="$1"; cursor=''; count=0
  shift
  while :; do
    count=$((count + 1))
    ((count <= 10000)) || { echo 'Pagination safety limit reached' >&2; exit 1; }
    args=(--data-urlencode 'limit=100')
    [[ -z "$cursor" ]] || args+=(--data-urlencode "after=$cursor")
    response=$(openai_get "$path" "${args[@]}" "$@") || exit 1
    jq -e '(.data|type == "array") and (.has_more|type == "boolean")' <<<"$response" >/dev/null 2>&1 || {
      echo 'Unexpected API list schema; no rows emitted' >&2; exit 1;
    }
    jq -c '.data[]' <<<"$response" >> "$work/rows"
    bytes=$(wc -c < "$work/rows")
    ((bytes <= 67108864)) || { echo 'Export exceeds 64 MiB safety bound; no rows emitted' >&2; exit 1; }
    [[ $(jq -r '.has_more' <<<"$response") == true ]] || break
    cursor=$(jq -er '.data[-1].id | select(type == "string" and length > 0 and length <= 1024)' <<<"$response") || exit 1
    [[ "$cursor" != *[[:cntrl:]]* ]] || exit 1
    if grep -Fqx -- "$cursor" "$work/cursors"; then echo 'Repeated pagination cursor; no rows emitted' >&2; exit 1; fi
    printf '%s\n' "$cursor" >> "$work/cursors"
  done
  # Stage all pages privately; a late-page failure produces zero stdout.
  cat "$work/rows"
)
