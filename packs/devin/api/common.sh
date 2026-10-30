#!/usr/bin/env bash
# Shared GET-only transport for the Devin Enterprise verification packs.
# Sources: https://docs.devin.ai/api-reference/authentication
#          https://docs.devin.ai/v3-openapi.json (verified 2026-10-29)
# Local files are private; no API response body or credential is logged on failure.
set +x
set -Eeuo pipefail
umask 077

hth_unknown() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }

hth_init() {
  local minimum="$1" level="${HTH_PROFILE_LEVEL:-1}"
  [[ "$level" =~ ^[1-4]$ ]] || hth_unknown 'HTH_PROFILE_LEVEL must be 1, 2, 3, or 4'
  (( level >= minimum )) || hth_unknown "not run: this pack requires HTH_PROFILE_LEVEL >= ${minimum}"
  for dependency in curl jq python3; do
    command -v "$dependency" >/dev/null 2>&1 || hth_unknown "missing dependency: ${dependency}"
  done
  [[ "${DEVIN_API_KEY:-}" =~ ^cog_[A-Za-z0-9_-]+$ ]] || hth_unknown 'set DEVIN_API_KEY to a v3 cog_ credential via your secret manager'
  # The origin is deliberately not configurable; a typo must not send a token elsewhere.
  [[ -z "${DEVIN_API_BASE:-}" ]] || hth_unknown 'DEVIN_API_BASE overrides are not supported'
  HTH_MAX_PAGES="${HTH_MAX_PAGES:-1000}"
  [[ "$HTH_MAX_PAGES" =~ ^[1-9][0-9]{0,3}$ ]] || hth_unknown 'HTH_MAX_PAGES must be 1..9999'
  HTH_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/hth-devin.XXXXXX")" || hth_unknown 'cannot create private temporary directory'
  trap 'rm -rf -- "$HTH_TEMP"' EXIT
  trap 'hth_unknown "unexpected local failure at line ${LINENO}; no compliant verdict"' ERR
}

hth_get() {
  local path="$1" destination="$2" status
  [[ "$path" == /v3/* || "$path" == /v3beta1/* ]] || hth_unknown 'invalid API path'
  # -q MUST be first: ignore ~/.curlrc. Header travels on stdin, not in argv.
  # No --location: redirects fail closed instead of forwarding credentials.
  if ! status="$(printf 'header = "Authorization: Bearer %s"\n' "$DEVIN_API_KEY" |
    curl -q --config - --silent --show-error --request GET --proto '=https' \
      --tlsv1.2 --connect-timeout 15 --max-time 60 --max-filesize 20971520 \
      --header 'Accept: application/json' --output "$destination" --write-out '%{http_code}' \
      "https://api.devin.ai${path}")"; then
    hth_unknown 'GET failed at transport layer; no evidence accepted'
  fi
  [[ "$status" == 200 ]] || hth_unknown "GET returned HTTP ${status}; check entitlement, scope, credential, and source IP"
  jq -e 'type == "object"' "$destination" >/dev/null 2>&1 || hth_unknown 'GET returned malformed JSON or a non-object'
}

hth_paginate() {
  local path="$1" destination="$2" query="${3:-}" cursor="" next pages=0
  local response="$HTH_TEMP/page.json" seen="$HTH_TEMP/cursors.jsonl"
  : > "$destination"; : > "$seen"
  while :; do
    local request="${path}?first=100${query:+&${query}}"
    if [[ -n "$cursor" ]]; then
      request+="&after=$(jq -rn --arg cursor "$cursor" '$cursor | @uri')"
    fi
    hth_get "$request" "$response"
    jq -e '(.items | type == "array") and (.has_next_page | type == "boolean") and
      (has("end_cursor")) and (.end_cursor == null or (.end_cursor | type == "string"))' \
      "$response" >/dev/null || hth_unknown 'malformed pagination envelope'
    jq -c '.items[]' "$response" >> "$destination"
    pages=$((pages + 1))
    [[ "$(jq -r '.has_next_page' "$response")" == true ]] || break
    next="$(jq -r '.end_cursor // empty' "$response")"
    [[ -n "$next" ]] || hth_unknown 'has_next_page without a nonempty cursor'
    if jq -se --arg cursor "$next" 'index($cursor) != null' "$seen" >/dev/null; then
      hth_unknown 'repeated pagination cursor; partial evidence discarded'
    fi
    (( pages < HTH_MAX_PAGES )) || hth_unknown 'pagination limit reached; partial evidence discarded'
    jq -nc --arg cursor "$next" '$cursor' >> "$seen"
    cursor="$next"
  done
}

hth_save_private() {
  # Exclusive create: refuse existing files/symlinks, never overwrite prior evidence.
  # Source is complete before the destination is created; failures remove partial output.
  python3 - "$1" "$2" <<'PY'
import os, shutil, sys
source, destination = sys.argv[1:]
try:
    fd = os.open(destination, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
except OSError:
    print('UNKNOWN: output must be a new file in an existing trusted directory', file=sys.stderr)
    sys.exit(2)
try:
    with os.fdopen(fd, 'wb') as target, open(source, 'rb') as incoming:
        shutil.copyfileobj(incoming, target)
        target.flush()
        os.fsync(target.fileno())
except OSError:
    os.unlink(destination)
    print('UNKNOWN: could not persist complete evidence', file=sys.stderr)
    sys.exit(2)
PY
}
