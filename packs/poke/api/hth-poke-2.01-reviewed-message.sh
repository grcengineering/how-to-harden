#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: poke-2.1
#   guide: https://howtoharden.com/guides/poke/#21-treat-api-messages-as-action-capable-ingress
#   profile: L2
#   mode: mutating
#   requires: jq; reviewed JSON object; existing Kitchen V2 key only for explicit --send
# Source: https://poke.com/docs/api (2026-11-05)
# HTH Guide Excerpt: begin reviewed-message
set +x
set -Eeuo pipefail
umask 077
unknown() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
case "${HTH_PROFILE_LEVEL:-1}" in 2|3|4) ;; *) unknown 'HTH_PROFILE_LEVEL=2..4 required before payload generation or delivery' ;; esac
[[ $# == 1 || ( $# == 2 && "$2" == --send ) ]] || unknown 'usage: reviewed-message.sh FILE.json [--send]'
[[ -f "$1" && ! -L "$1" ]] || unknown 'payload must be a reviewed regular file, not a symlink'
command -v jq >/dev/null || unknown 'jq is required'
tmp="$(mktemp -d "${TMPDIR:-/tmp}/hth-poke-send.XXXXXX")" || unknown 'cannot create private temporary directory'
trap 'rm -rf -- "$tmp"' EXIT
# Snapshot once; validate and send the same bytes from the private directory.
cp -- "$1" "$tmp/payload.json"
[[ $(wc -c < "$tmp/payload.json") -le 65536 ]] || unknown 'pack policy limits payloads to 64 KiB (not a vendor limit)'
jq -se 'length==1 and (.[0]|type=="object" and length>0)' "$tmp/payload.json" >/dev/null 2>&1 || unknown 'payload must contain exactly one nonempty JSON object'
[[ ${2:-} == --send ]] || { printf 'PREVIEW ONLY: valid JSON; zero requests. Entire body can trigger connected-account actions.\n'; exit 0; }
command -v curl >/dev/null || unknown 'curl is required'
[[ -n ${POKE_API_KEY:-} && ${#POKE_API_KEY} -le 4096 && "$POKE_API_KEY" != pk_* ]] || unknown 'supply an existing Kitchen V2 key, not a legacy V1 key'
[[ "$POKE_API_KEY" != *[$'\r\n\t ']* && "$POKE_API_KEY" != *'"'* && "$POKE_API_KEY" != *\\* ]] || unknown 'invalid key characters'
# Do not log the payload or return body.
if ! status="$(printf 'header = "Authorization: Bearer %s"\n' "$POKE_API_KEY" | curl -q --config - \
 --silent --show-error --request POST --proto '=https' --tlsv1.2 \
 --connect-timeout 15 --max-time 60 --max-filesize 1048576 \
 --header 'Content-Type: application/json' --data-binary "@$tmp/payload.json" \
 --output "$tmp/response.json" --write-out '%{http_code}' \
 'https://poke.com/api/v1/inbound/api-message')"; then
 unknown 'delivery outcome uncertain; inspect account before any retry'
fi
[[ "$status" =~ ^2[0-9][0-9]$ ]] || unknown "HTTP ${status}; inspect account before retry; response withheld"
jq -se 'length==1 and (.[0]|type=="object" and .success==true)' "$tmp/response.json" >/dev/null 2>&1 || unknown 'unrecognized acknowledgment; inspect account before retry'
printf 'DELIVERED to Poke per API acknowledgment; downstream actions/completion are unverified.\n'
# HTH Guide Excerpt: end reviewed-message
