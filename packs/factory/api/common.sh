#!/usr/bin/env bash
# GET-only transport. Source: https://docs.factory.com/api-reference
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

hth_api_init() {
  hth_init "$1"
  command -v curl >/dev/null 2>&1 || hth_unknown 'missing dependency: curl'
  local credential="${FACTORY_API_KEY:-}"
  # Length bounds are separate: macOS Bash/POSIX regex rejects large {m,n} bounds.
  [[ "$credential" =~ ^[A-Za-z0-9._~-]+$ && ${#credential} -ge 16 && ${#credential} -le 4096 ]] ||
    hth_unknown 'inject a Factory bearer credential without whitespace or config metacharacters'
  [[ -z "${FACTORY_API_BASE:-}" ]] || hth_unknown 'FACTORY_API_BASE overrides are not supported'
  HTH_MAX_PAGES="${HTH_MAX_PAGES:-1000}"
  [[ "$HTH_MAX_PAGES" =~ ^[1-9][0-9]{0,3}$ ]] || hth_unknown 'HTH_MAX_PAGES must be 1..9999'
}

hth_get() {
  local path="$1" destination="$2" status
  [[ "$path" == /api/v0/* ]] || hth_unknown 'unexpected API path'
  # -q is first to ignore ~/.curlrc; bearer header is stdin, never an argv value.
  # Redirects are rejected. The public API origin is deliberately fixed.
  if ! status="$(printf 'header = "Authorization: Bearer %s"\n' "$FACTORY_API_KEY" |
    curl -q --config - --silent --show-error --request GET --proto '=https' \
      --tlsv1.2 --connect-timeout 15 --max-time 60 --max-filesize 20971520 \
      --header 'Accept: application/json' --output "$destination" --write-out '%{http_code}' \
      "https://api.factory.ai${path}")"; then
    hth_unknown 'GET transport failure; partial evidence discarded'
  fi
  [[ "$status" == 200 ]] || hth_unknown "GET returned HTTP ${status}; check human role, plan, source IP and credential"
  jq -e 'type == "object"' "$destination" >/dev/null 2>&1 || hth_unknown 'malformed JSON response'
}

hth_paginate() {
  local path="$1" key="$2" destination="$3" cursor="" next pages=0
  local response="$HTH_TEMP/page.json" seen="$HTH_TEMP/cursors.jsonl"
  : > "$destination"
  : > "$seen"
  while :; do
    local request="${path}?limit=100"
    [[ -z "$cursor" ]] || request+="&cursor=$(jq -rn --arg cursor "$cursor" '$cursor | @uri')"
    hth_get "$request" "$response"
    jq -e --arg key "$key" '(.[$key] | type == "array") and
      (.pagination | type == "object") and (.pagination.hasMore | type == "boolean") and
      (.pagination | has("nextCursor")) and
      (.pagination.nextCursor == null or (.pagination.nextCursor | type == "string"))' \
      "$response" >/dev/null || hth_unknown 'malformed pagination envelope'
    jq -c --arg key "$key" '.[$key][]' "$response" >> "$destination"
    pages=$((pages + 1))
    [[ "$(jq -r '.pagination.hasMore' "$response")" == true ]] || break
    next="$(jq -r '.pagination.nextCursor // empty' "$response")"
    [[ -n "$next" ]] || hth_unknown 'hasMore without a cursor'
    (( $(jq --arg key "$key" '.[$key] | length' "$response") > 0 )) || hth_unknown 'empty nonterminal page'
    if jq -se --arg cursor "$next" 'index($cursor) != null' "$seen" >/dev/null; then
      hth_unknown 'repeated cursor; incomplete evidence discarded'
    fi
    (( pages < HTH_MAX_PAGES )) || hth_unknown 'page limit reached; incomplete evidence discarded'
    jq -nc --arg cursor "$next" '$cursor' >> "$seen"
    cursor="$next"
  done
}
