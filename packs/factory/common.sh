#!/usr/bin/env bash
# Shared local utilities; no Factory requests or settings changes.
set +x
set -Eeuo pipefail
umask 077

hth_unknown() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }

hth_init() {
  local minimum="$1" level="${HTH_PROFILE_LEVEL:-1}" dependency
  [[ "$level" =~ ^[1-4]$ ]] || hth_unknown 'HTH_PROFILE_LEVEL must be 1, 2, 3, or 4'
  (( level >= minimum )) || hth_unknown "not run: requires HTH_PROFILE_LEVEL >= ${minimum}"
  for dependency in jq python3; do
    command -v "$dependency" >/dev/null 2>&1 || hth_unknown "missing dependency: ${dependency}"
  done
  HTH_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/hth-factory.XXXXXX")" || hth_unknown 'cannot create private temporary directory'
  trap 'rm -rf -- "$HTH_TEMP"' EXIT
  trap 'hth_unknown "unexpected failure at line ${LINENO}; no compliant verdict"' ERR
}

hth_save_private() {
  # Refuse existing files and symlinks. Complete evidence is collected first.
  python3 - "$1" "$2" <<'PY'
import os
import shutil
import sys
source, destination = sys.argv[1:]
try:
    fd = os.open(destination, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
except OSError:
    print('UNKNOWN: output must be a new file in a trusted existing directory', file=sys.stderr)
    sys.exit(2)
try:
    with os.fdopen(fd, 'wb') as target, open(source, 'rb') as incoming:
        shutil.copyfileobj(incoming, target)
        target.flush()
        os.fsync(target.fileno())
except OSError:
    os.unlink(destination)
    print('UNKNOWN: complete evidence could not be saved', file=sys.stderr)
    sys.exit(2)
PY
}

hth_project() {
  [[ -n "${FACTORY_PROJECT_DIR:-}" && "$FACTORY_PROJECT_DIR" == /* && -d "$FACTORY_PROJECT_DIR" ]] ||
    hth_unknown 'set FACTORY_PROJECT_DIR to an absolute, trusted repository directory'
  command -v droid >/dev/null 2>&1 || hth_unknown 'install an approved Droid CLI version first'
}
