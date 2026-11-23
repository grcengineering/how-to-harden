#!/usr/bin/env bash
# Shared Inspect REST transport; not a first-party CLI or SDK.
# Official API: https://docs.inspect.com/api/openapi.json (2026-11-17).
set +x
set -Eeuo pipefail
umask 077
hth_unknown() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
hth_init() {
  for dependency in curl jq python3; do command -v "$dependency" >/dev/null || hth_unknown "missing $dependency"; done
  [[ -n "${INSPECT_API_KEY:-}" && "$INSPECT_API_KEY" =~ ^[A-Za-z0-9_.~-]+$ ]] || hth_unknown 'inject INSPECT_API_KEY through your secret manager; unsupported token characters rejected'
  [[ -z "${INSPECT_API_BASE:-}" ]] || hth_unknown 'origin overrides are not supported'
  HTH_TEMP=$(mktemp -d "${TMPDIR:-/tmp}/hth-inspect.XXXXXX")
  trap 'rm -rf -- "$HTH_TEMP"' EXIT
  trap 'hth_unknown "local failure; no verified result"' ERR
}
hth_request() {
  local method=$1 path=$2 destination=$3 body=${4:-} expected=${5:-200} status
  [[ "$method" == GET || "$method" == PATCH || "$method" == POST ]] || hth_unknown 'unsupported method'
  [[ "$path" == /api/v2/* && "$path" != *$'\n'* ]] || hth_unknown 'invalid path'
  local args=(--request "$method")
  if [[ "$method" != GET ]]; then
    [[ -f "$body" ]] || hth_unknown 'missing request body'
    args+=(--header 'Content-Type: application/json' --data-binary "@$body")
  fi
  # Ignore curlrc, never follow redirects or retry writes. Secret header uses stdin, not argv.
  if ! status=$(printf 'header = "Authorization: Bearer %s"\n' "$INSPECT_API_KEY" |
    env -u INSPECT_API_KEY curl -q --config - --silent --show-error --request "$method" --proto '=https' \
      --noproxy '*' --tlsv1.2 --connect-timeout 15 --max-time 60 --max-filesize 20971520 \
      --header 'Accept: application/json' "${args[@]}" --output "$destination" \
      --write-out '%{http_code}' "https://app.inspect.com$path"); then
    hth_unknown 'transport failed; a write may have taken effect; inspect current state before retrying'
  fi
  [[ "$status" == "$expected" ]] || hth_unknown "HTTP $status; response body withheld; write outcome may require reconciliation"
  jq -se 'length==1 and (.[0]|type)=="object"' "$destination" >/dev/null 2>&1 || hth_unknown 'invalid response object'
}
hth_id() { [[ "$1" =~ ^[A-Za-z0-9_-]+$ ]] || hth_unknown 'supply exact ID using letters, digits, hyphen or underscore'; }
hth_apply_gate() {
  [[ "${HTH_APPLY:-0}" == 0 || ( "${HTH_APPLY:-}" == 1 && "${HTH_CONFIRM_ID:-}" == "$1" ) ]] || hth_unknown 'apply requires HTH_APPLY=1 and HTH_CONFIRM_ID matching exact target'
}
hth_agent_valid() {
  jq -e --arg id "$1" '.data | .id==$id and (.name|type)=="string" and (.builtin|type)=="boolean" and has("repositories") and (.repositories==null or ((.repositories|type)=="array" and all(.repositories[]; type=="string"))) and has("skills") and (.skills==null or ((.skills|type)=="array" and all(.skills[]; type=="string"))) and has("capabilities") and (.prompt_context_mode=="append" or .prompt_context_mode=="replace")' "$2" >/dev/null || hth_unknown 'malformed or mismatched agent'
}
hth_automation_valid() {
  jq -e --arg id "$1" '.data | .id==$id and (.enabled|type)=="boolean" and (.viewer_can_edit|type)=="boolean" and (.triggers|type)=="array" and (.repositories|type)=="array" and (.updated_at|type)=="string"' "$2" >/dev/null || hth_unknown 'malformed or mismatched automation'
}
hth_save() {
  [[ -n "${HTH_OUTPUT_FILE:-}" ]] || hth_unknown 'set HTH_OUTPUT_FILE to a new private evidence file'
  python3 - "$1" "$HTH_OUTPUT_FILE" <<'PY'
import os,sys,shutil
try:
    fd=os.open(sys.argv[2],os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600)
except OSError:
    sys.exit('UNKNOWN: output must be a new file in a trusted existing directory')
try:
    with os.fdopen(fd,'wb') as dst,open(sys.argv[1],'rb') as src:
        shutil.copyfileobj(src,dst)
except OSError:
    os.unlink(sys.argv[2]); raise
PY
}
hth_snapshot_dir() {
  HTH_EVIDENCE=$(mktemp -d "${TMPDIR:-/tmp}/hth-inspect-change.XXXXXX")
  printf 'Private change evidence retained at %s; remove after your retention period.\n' "$HTH_EVIDENCE" >&2
}
