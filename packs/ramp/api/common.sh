#!/usr/bin/env bash
# Shared bash+curl transport. No live calls occur until ramp_collect is invoked.
set +x
set -euo pipefail
umask 077
ramp_error() { printf '%s\n' "Ramp pack: $*" >&2; exit 1; }
[[ $# == 0 ]] || ramp_error 'Unexpected arguments.'
command -v python3 >/dev/null || ramp_error 'python3 is required.'
command -v curl >/dev/null || ramp_error 'curl is required.'
# Bearer token alphabet per RFC 6750: blocks header/config injection.
[[ ${RAMP_ACCESS_TOKEN:-} =~ ^[A-Za-z0-9._~+/-]+=*$ ]] || ramp_error 'Missing or invalid RAMP_ACCESS_TOKEN.'
[[ ${RAMP_API_ORIGIN:-https://api.ramp.com} == https://api.ramp.com ]] || ramp_error 'Only the production API origin is supported.'
RAMP_PAGE_LIMIT=${RAMP_MAX_PAGES:-1000}
[[ $RAMP_PAGE_LIMIT =~ ^[1-9][0-9]{0,3}$ ]] && ((RAMP_PAGE_LIMIT <= 1000)) || ramp_error 'RAMP_MAX_PAGES must be 1 through 1000.'
RAMP_HELPER="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/response.py"
RAMP_TMP=$(mktemp -d)
trap 'rm -rf -- "$RAMP_TMP"' EXIT
printf 'header = "Authorization: Bearer %s"\n' "$RAMP_ACCESS_TOKEN" > "$RAMP_TMP/auth"
unset RAMP_ACCESS_TOKEN
ramp_collect() {
  local kind=$1 path=$2 query=${3:-} paged=$4 url status count=0
  url="https://api.ramp.com${path}${query}"
  : > "$RAMP_TMP/$kind.ndjson"
  : > "$RAMP_TMP/seen"
  while [[ -n $url ]]; do
    ((count+=1))
    ((count <= RAMP_PAGE_LIMIT)) || ramp_error 'Pagination limit exceeded; narrow the query.'
    if grep -Fxq -- "$url" "$RAMP_TMP/seen"; then ramp_error 'Pagination loop.'; fi
    printf '%s\n' "$url" >> "$RAMP_TMP/seen"
    # -q first disables ~/.curlrc. No redirects, proxy, retries, verbose output or token argv.
    if ! status=$(curl -q --silent --proto '=https' --noproxy '*' \
      --connect-timeout 15 --max-time 60 --max-filesize 20971520 \
      --config "$RAMP_TMP/auth" --request GET --header 'Accept: application/json' \
      --output "$RAMP_TMP/page" --write-out '%{http_code}' --url "$url" 2>/dev/null); then
      ramp_error 'Transport failed; no report emitted.'
    fi
    [[ $status == 200 ]] || ramp_error 'Unexpected HTTP status; no report emitted.'
    python3 "$RAMP_HELPER" page "$kind" "$path" "$query" "$paged" "$RAMP_TMP" || ramp_error 'Invalid response or unsafe pagination; no report emitted.'
    url=$(cat "$RAMP_TMP/next")
  done
}
ramp_report() {
  python3 "$RAMP_HELPER" report "$RAMP_TMP" "$@" || ramp_error 'Report failed.'
}
