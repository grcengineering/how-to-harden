#!/usr/bin/env bash
# Ads GET helper. Secret headers are stdin config, never process arguments.
set -euo pipefail
ads_require_key() { : "${OPENAI_ADS_API_KEY:?Inject the intended ad account key from an approved secret manager}"; }
ads_checked_base() {
  local base="$1" production="$2" port suffix
  if [[ "$base" != "$production" ]]; then
    suffix=''; [[ "$production" != */v1 ]] || suffix='/v1'
    if [[ "${HTH_FIXTURE_LOOPBACK:-}" == 1 && "$base" =~ ^http://127\.0\.0\.1:([0-9]{1,5})(/v1)?$ && "${BASH_REMATCH[2]:-}" == "$suffix" ]]; then
      port=$((10#${BASH_REMATCH[1]})); ((port >= 1 && port <= 65535)) || return 2
    else echo 'Refusing an unapproved Ads base URL' >&2; return 2; fi
  fi
  printf '%s' "$base"
}
ads_http_to_file() {
  local base="$1" token="$2" path="$3" output="$4" quoted protocol status bytes LC_ALL=C
  shift 4
  if [[ -z "$token" || ${#token} -gt 8192 || "$token" == *[[:cntrl:]]* ]]; then
    echo 'Missing or unsafe Ads credential representation' >&2; return 2
  fi
  quoted=${token//\\/\\\\}; quoted=${quoted//\"/\\\"}
  protocol='=https'; [[ "$base" != http:* ]] || protocol='=http'
  # Caller supplies a checked base. Ignore curlrc and never follow redirects.
  if ! status=$(printf 'header = "Authorization: Bearer %s"\n' "$quoted" |
    curl -q --config - --proto "$protocol" --proto-redir '=https' \
      --connect-timeout 5 --max-time 30 --max-filesize 8388608 --silent \
      "${base}${path}" --output "$output" --write-out '%{http_code}' "$@" 2>/dev/null); then
    echo 'Ads transport failed; response body withheld' >&2; return 1
  fi
  bytes=$(wc -c < "$output")
  if [[ ! "$status" =~ ^[0-9]{3}$ ]] || ((bytes > 8388608)); then
    echo 'Invalid or oversized Ads response' >&2; return 1
  fi
  printf '%s' "$status"
}
ads_get() (
  umask 077
  work=$(mktemp -d) || exit 1
  trap 'rm -rf "$work"' EXIT
  base=$(ads_checked_base "${OPENAI_ADS_BASE_URL:-https://api.ads.openai.com/v1}" 'https://api.ads.openai.com/v1') || exit 2
  status=$(ads_http_to_file "$base" "$OPENAI_ADS_API_KEY" "$1" "$work/body" --get "${@:2}") || exit 1
  [[ "$status" == 200 ]] || { echo "Ads request failed: HTTP $status; response body withheld" >&2; exit 1; }
  cat "$work/body"
)
ads_audit_list() (
  umask 077
  work=$(mktemp -d) || exit 1
  trap 'rm -rf "$work"' EXIT
  : > "$work/rows"; : > "$work/cursors"
  cursor=''; count=0
  while :; do
    count=$((count + 1)); ((count <= 10000)) || { echo 'Ads pagination safety limit reached' >&2; exit 1; }
    args=(--data-urlencode 'limit=100' --data-urlencode 'order=asc'
      --data-urlencode "start_time=${OPENAI_ADS_AUDIT_START}")
    [[ -z "$cursor" ]] || args+=(--data-urlencode "after=${cursor}")
    body=$(ads_get '/audit_logs' "${args[@]}") || exit 1
    jq -e '(.data|type == "array") and (.has_more|type == "boolean")' <<<"$body" >/dev/null 2>&1 || {
      echo 'Unexpected Ads list schema; no rows emitted' >&2; exit 1;
    }
    jq -c '.data[]' <<<"$body" >> "$work/rows"
    bytes=$(wc -c < "$work/rows")
    ((bytes <= 67108864)) || { echo 'Ads export exceeds 64 MiB safety bound; no rows emitted' >&2; exit 1; }
    [[ $(jq -r '.has_more' <<<"$body") == true ]] || break
    # Ads docs require the list's last_id, not campaign id or API event id.
    cursor=$(jq -er '.last_id | select(type == "string" and length > 0 and length <= 1024)' <<<"$body") || exit 1
    [[ "$cursor" != *[[:cntrl:]]* ]] || exit 1
    if grep -Fqx -- "$cursor" "$work/cursors"; then echo 'Repeated Ads cursor; no rows emitted' >&2; exit 1; fi
    printf '%s\n' "$cursor" >> "$work/cursors"
  done
  cat "$work/rows"
)
