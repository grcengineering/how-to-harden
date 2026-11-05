#!/usr/bin/env bash
# Fixed-origin transport. Never applies a policy, approves a device, or creates a key.
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

hth_api_init() {
  hth_init "$1"
  command -v curl >/dev/null 2>&1 || hth_unknown 'missing dependency: curl'
  local credential="${TAILSCALE_ACCESS_TOKEN:-}" tailnet="${TAILSCALE_TAILNET:-}"
  [[ "$credential" =~ ^[A-Za-z0-9._~-]+$ && ${#credential} -ge 16 && ${#credential} -le 4096 ]] ||
    hth_unknown 'inject TAILSCALE_ACCESS_TOKEN without whitespace or configuration metacharacters'
  [[ "$tailnet" =~ ^[A-Za-z0-9-][A-Za-z0-9_.@-]*$ && ${#tailnet} -le 253 ]] ||
    hth_unknown 'set TAILSCALE_TAILNET to the reviewed tailnet ID/name, or explicitly -'
  [[ -z "${TAILSCALE_BASE_URL:-}" ]] || hth_unknown 'TAILSCALE_BASE_URL overrides are not supported'
  HTH_TAILNET="$(jq -rn --arg value "$tailnet" '$value | @uri')"
}

hth_request() {
  local method="$1" path="$2" destination="$3" accept="${4:-application/json}" body="${5:-}" status
  # A populated array also works with macOS Bash 3.2 under nounset.
  local -a arguments=(--header "Accept: ${accept}")
  case "${method}:${path}" in
    GET:/api/v2/tailnet/"$HTH_TAILNET"/users|GET:/api/v2/tailnet/"$HTH_TAILNET"/settings|GET:/api/v2/tailnet/"$HTH_TAILNET"/devices\?fields=all|GET:/api/v2/tailnet/"$HTH_TAILNET"/acl|GET:/api/v2/tailnet/"$HTH_TAILNET"/keys|GET:/api/v2/tailnet/"$HTH_TAILNET"/keys/*|GET:/api/v2/device/*/routes|GET:/api/v2/tailnet/"$HTH_TAILNET"/logging/configuration\?*|GET:/api/v2/tailnet/"$HTH_TAILNET"/logging/configuration/status|GET:/api/v2/tailnet/"$HTH_TAILNET"/logging/network/status) ;;
    GET:/api/v2/device/*/attributes)
      [[ "$path" =~ ^/api/v2/device/[A-Za-z0-9_-]{1,128}/attributes$ ]] || hth_unknown 'invalid device attribute path' ;;
    GET:/api/v2/tailnet/"$HTH_TAILNET"/dns/nameservers|GET:/api/v2/tailnet/"$HTH_TAILNET"/dns/preferences|GET:/api/v2/tailnet/"$HTH_TAILNET"/dns/searchpaths|GET:/api/v2/tailnet/"$HTH_TAILNET"/dns/split-dns) ;;
    POST:/api/v2/tailnet/"$HTH_TAILNET"/acl/validate)
      [[ -f "$body" ]] || hth_unknown 'missing candidate policy'
      arguments+=(--header 'Content-Type: application/hujson' --data-binary "@${body}") ;;
    *) hth_unknown 'unsupported API operation' ;;
  esac
  # -q ignores ~/.curlrc. The token is delivered on stdin, never in argv.
  # No redirects, arbitrary origins, response bodies on stderr, or partial evidence.
  if ! status="$(printf 'header = "Authorization: Bearer %s"\n' "$TAILSCALE_ACCESS_TOKEN" |
    curl -q --config - --silent --request "$method" --proto '=https' --tlsv1.2 \
      --connect-timeout 15 --max-time 60 --max-filesize 20971520 \
      --dump-header "$HTH_TEMP/headers" \
      --output "$destination" --write-out '%{http_code}' "${arguments[@]}" \
      "https://api.tailscale.com${path}" 2> "$HTH_TEMP/transport-error")"; then
    hth_unknown 'API transport failure or response bound exceeded; incomplete evidence discarded'
  fi
  [[ "$status" == 200 ]] || hth_unknown "API returned HTTP ${status}; check scope, role and plan"
}

hth_get() {
  hth_request GET "$1" "$2"
  jq -e 'type == "object"' "$2" >/dev/null 2>&1 || hth_unknown 'malformed API object'
  jq -e 'has("nextCursor") or has("nextPageToken") or has("pagination") or has("next")' "$2" >/dev/null 2>&1 &&
    hth_unknown 'unrecognized pagination; refusing to claim a complete collection'
  return 0
}

hth_window() {
  # Configuration audit history is retained for 90 days. Export at most one day
  # per request; collect overlapping windows and deduplicate in the receiving store.
  HTH_WINDOW="$(python3 - <<'PY'
import datetime as dt
import os
import re
import sys
import urllib.parse
try:
    values = [os.environ[name] for name in ('TAILSCALE_LOG_START', 'TAILSCALE_LOG_END')]
    if not all(re.fullmatch(r'\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ', v) for v in values):
        raise ValueError()
    start, end = [dt.datetime.strptime(v, '%Y-%m-%dT%H:%M:%SZ').replace(tzinfo=dt.timezone.utc) for v in values]
    now = dt.datetime.now(dt.timezone.utc)
    if not (now-dt.timedelta(days=90) <= start < end <= now and end-start <= dt.timedelta(days=1)):
        raise ValueError()
    print(urllib.parse.urlencode(dict(zip(('start', 'end'), values))))
except (KeyError, ValueError):
    print('UNKNOWN: require a past UTC window within 90 days and no longer than one day', file=sys.stderr)
    sys.exit(2)
PY
)" || hth_unknown 'invalid audit-log window'
}
