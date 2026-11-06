#!/usr/bin/env bash
# Local guards only; no authentication, daemon launch or network request.
set +x
set -Eeuo pipefail
umask 077

hl_unknown() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
hl_level() {
  local minimum="$1" level="${HTH_PROFILE_LEVEL:-1}"
  [[ "$level" =~ ^[1-4]$ ]] || hl_unknown 'HTH_PROFILE_LEVEL must be 1..4'
  (( level >= minimum )) || hl_unknown "not run: requires HTH_PROFILE_LEVEL >= ${minimum}"
}
hl_jq() { command -v jq >/dev/null 2>&1 || hl_unknown 'jq is required'; }
