#!/usr/bin/env bash
# Shared transport for FEDERAL service-key JSON POST reads; not commercial cog_ auth.
# Sources: https://docs.devin.ai/federal/api/overview and /group-management (2026-11-05).
set +x
set -Eeuo pipefail
umask 077
hth_unknown() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
hth_federal_init() {
  for dependency in curl jq bun; do command -v "$dependency" >/dev/null || hth_unknown "missing ${dependency}"; done
  [[ "${DEVIN_FEDERAL_API_URL:-}" =~ ^https://[A-Za-z0-9][A-Za-z0-9.-]*(:[0-9]{1,5})?$ ]] || hth_unknown 'set the confirmed HTTPS API origin only (no path, credentials, query or fragment)'
  [[ -n ${WINDSURF_SERVICE_KEY:-} && ${#WINDSURF_SERVICE_KEY} -le 4096 ]] || hth_unknown 'inject an existing scoped WINDSURF_SERVICE_KEY'
  [[ "${HTH_PROFILE_LEVEL:-1}" =~ ^[2-4]$ ]] || hth_unknown 'HTH_PROFILE_LEVEL >= 2 required'
  [[ -n ${HTH_OUTPUT_FILE:-} ]] || hth_unknown 'set a new HTH_OUTPUT_FILE in a trusted directory'
  HTH_MAX_PAGES="${HTH_MAX_PAGES:-1000}"
  [[ "$HTH_MAX_PAGES" =~ ^[1-9][0-9]{0,3}$ ]] || hth_unknown 'HTH_MAX_PAGES must be 1..9999'
  HTH_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/hth-federal.XXXXXX")" || hth_unknown 'cannot create private temporary directory'
  trap 'rm -rf -- "$HTH_TEMP"' EXIT
  trap 'hth_unknown "unexpected local failure; no evidence accepted"' ERR
}
hth_federal_post_read() {
  local operation="$1" body="$2" result="$3" status
  [[ "$operation" == ListGroups || "$operation" == GetGroup ]] || hth_unknown 'operation is not in the read-only allowlist'
  if ! status="$(curl -q --silent --show-error --request POST --proto '=https' --tlsv1.2 \
    --connect-timeout 15 --max-time 60 --max-filesize 20971520 \
    --header 'Content-Type: application/json' --data-binary "@$body" \
    --output "$result" --write-out '%{http_code}' "${DEVIN_FEDERAL_API_URL}/api/v1/${operation}" </dev/null)"; then
    hth_unknown 'transport failure; no complete inventory'
  fi
  [[ "$status" == 200 ]] || hth_unknown "HTTP ${status}; check origin, key scope and federal deployment entitlement"
  jq -se 'length==1 and (.[0]|type=="object" and (has("error")|not))' "$result" >/dev/null 2>&1 || hth_unknown 'malformed response, multiple values or error object'
}
hth_private_copy() {
  bun - "$1" "$2" <<'JS'
import { openSync,readFileSync,writeFileSync,fsyncSync,closeSync,unlinkSync,constants } from 'node:fs';
const [source,destination]=process.argv.slice(2);
let fd;
try { fd=openSync(destination,constants.O_WRONLY|constants.O_CREAT|constants.O_EXCL|constants.O_NOFOLLOW,0o600); }
catch { console.error('UNKNOWN: output must be a new file in an existing trusted directory'); process.exit(2); }
try { writeFileSync(fd,readFileSync(source));fsyncSync(fd);closeSync(fd); }
catch { try { closeSync(fd);unlinkSync(destination); } catch {} console.error('UNKNOWN: cannot persist complete evidence');process.exit(2); }
JS
}
