#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: pi-5.2
#   guide: https://howtoharden.com/guides/pi/
#   profile: L1
#   mode: read-only
#   requires: POSIX Bash, Python 3.9+, complete HTH checkout; PyYAML for YAML input
# HTH Pi.dev 5.2 — Native read diagnostics; L1; NIST AU-6, CM-6.
# Guide: https://howtoharden.com/guides/pi/
# Source: https://docs.pi.dev/latest/security (checked 2026-11-15; reviewed 1.5.2)
# HTH Guide Excerpt: begin native-diagnostics
set +x
set -euo pipefail
PACK_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# Default prints fixed argv; --execute opts into native reads only, never remediation.
python3 "$PACK_DIR/../../../scripts/lib/agent_hardening.py" diagnostics "$@" --product pi
# HTH Guide Excerpt: end native-diagnostics
