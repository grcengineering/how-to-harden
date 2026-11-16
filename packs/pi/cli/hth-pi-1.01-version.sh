#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: pi-1.1
#   guide: https://howtoharden.com/guides/pi/
#   profile: L1
#   mode: read-only
#   requires: POSIX Bash, Python 3.9+, complete HTH checkout; PyYAML for YAML input
# HTH Pi.dev 1.1 — Verify reviewed first-party binary; L1; NIST SI-2.
# Guide: https://howtoharden.com/guides/pi/
# Source: https://docs.pi.dev/latest/security (checked 2026-11-15; reviewed 1.5.2)
# HTH Guide Excerpt: begin version
set +x
set -euo pipefail
[[ $# -eq 0 ]] || { printf '%s\n' 'No positional arguments are accepted.' >&2; exit 2; }
[[ "${HTH_EXECUTE:-0}" == 0 || "${HTH_EXECUTE:-0}" == 1 ]] || exit 2
[[ "${HTH_BINARY:-}" == /* ]] || { printf '%s\n' 'Set HTH_BINARY to an absolute reviewed executable path.' >&2; exit 2; }
PACK_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# Default is a preview; opt-in runs only --version, with a timeout and private output.
run_version_read() {
  python3 "$PACK_DIR/../../../scripts/lib/agent_hardening.py" version \
    --product pi --version 1.5.2 --binary "$HTH_BINARY" "$@"
}
if [[ "${HTH_EXECUTE:-0}" == 1 ]]; then
  run_version_read --execute
else
  run_version_read
fi
# HTH Guide Excerpt: end version
