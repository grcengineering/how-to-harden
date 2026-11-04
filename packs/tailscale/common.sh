#!/usr/bin/env bash
# Shared local utilities. Download the whole packs/tailscale directory.
set +x
set -Eeuo pipefail
umask 077

hth_unknown() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }

hth_init() {
  local minimum="$1" level="${HTH_PROFILE_LEVEL:-1}" dependency
  [[ "$level" =~ ^[1-4]$ ]] || hth_unknown 'HTH_PROFILE_LEVEL must be 1..4'
  (( level >= minimum )) || hth_unknown "requires HTH_PROFILE_LEVEL >= ${minimum}"
  for dependency in jq python3; do
    command -v "$dependency" >/dev/null 2>&1 || hth_unknown "missing dependency: ${dependency}"
  done
  [[ "${TAILSCALE_OUTPUT:-}" == /* && ! -e "$TAILSCALE_OUTPUT" && ! -L "$TAILSCALE_OUTPUT" && -d "$(dirname "$TAILSCALE_OUTPUT")" ]] ||
    hth_unknown 'TAILSCALE_OUTPUT must be a new absolute file path in an existing trusted directory'
  HTH_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/hth-tailscale.XXXXXX")" || hth_unknown 'cannot create private temporary directory'
  trap 'rm -rf -- "$HTH_TEMP"' EXIT
  trap 'hth_unknown "unexpected failure; incomplete output discarded"' ERR
}

hth_save() {
  python3 - "$1" "$TAILSCALE_OUTPUT" <<'PY'
import os
import shutil
import sys
source, destination = sys.argv[1:]
try:
    fd = os.open(destination, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
except OSError:
    sys.exit('UNKNOWN: output already exists or cannot be created')
try:
    with os.fdopen(fd, 'wb') as target, open(source, 'rb') as incoming:
        shutil.copyfileobj(incoming, target)
        target.flush()
        os.fsync(target.fileno())
except OSError:
    os.unlink(destination)
    sys.exit('UNKNOWN: complete output could not be saved')
PY
}

hth_cli() {
  command -v tailscale >/dev/null 2>&1 || hth_unknown 'install an approved Tailscale client first'
  # Only fixed read operations may reach the first-party CLI.
  case "$*" in
    'lock status'|'funnel status --json'|'version --json') ;;
    *) hth_unknown 'unsupported CLI operation' ;;
  esac
  if ! tailscale "$@" > "$HTH_TEMP/cli" 2> "$HTH_TEMP/cli-error"; then
    hth_unknown 'CLI read failed; check client support, active tailnet and local permissions'
  fi
  [[ -s "$HTH_TEMP/cli" ]] || hth_unknown 'empty CLI result'
}
