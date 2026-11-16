#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: opencode-5.2
#   guide: https://howtoharden.com/guides/opencode/
#   profile: L1
#   mode: read-only
#   requires: POSIX Bash, Python 3.9+, complete HTH checkout; PyYAML for YAML input
# HTH OpenCode 5.2 — Native read diagnostics; L1; NIST AU-6, CM-6.
# Guide: https://howtoharden.com/guides/opencode/
# Source: https://opencode.ai/docs/ (checked 2026-11-15; reviewed 2.3.0)
# HTH Guide Excerpt: begin native-diagnostics
set +x
set -euo pipefail
PACK_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# Default prints fixed argv; --execute opts into native reads only, never remediation.
python3 "$PACK_DIR/../../../scripts/lib/agent_hardening.py" diagnostics "$@" --product opencode
# HTH Guide Excerpt: end native-diagnostics
