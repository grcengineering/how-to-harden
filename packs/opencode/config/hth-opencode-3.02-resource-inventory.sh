#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: opencode-3.2
#   guide: https://howtoharden.com/guides/opencode/
#   profile: L1
#   mode: read-only
#   requires: POSIX Bash, Python 3.9+, complete HTH checkout; PyYAML for YAML input
# HTH OpenCode 3.2 — resource-inventory; L1/L2; NIST CM-6, AC-6.
# Guide: https://howtoharden.com/guides/opencode/
# Source: https://opencode.ai/docs/ (checked 2026-11-15; reviewed 2.3.0)
# Read-only or stdout candidate/preview only. Requires the complete HTH checkout.
# HTH Guide Excerpt: begin resource-inventory
set +x
set -euo pipefail
PACK_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
python3 "$PACK_DIR/../../../scripts/lib/agent_hardening.py" inventory "$@" --product opencode
# HTH Guide Excerpt: end resource-inventory
