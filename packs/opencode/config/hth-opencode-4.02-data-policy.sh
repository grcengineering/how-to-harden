#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: opencode-4.2
#   guide: https://howtoharden.com/guides/opencode/
#   profile: L2
#   mode: read-only
#   requires: POSIX Bash, Python 3.9+, complete HTH checkout; PyYAML for YAML input
# HTH OpenCode 4.2 — data-policy; L1/L2; NIST CM-6, AC-6.
# Guide: https://howtoharden.com/guides/opencode/
# Source: https://opencode.ai/docs/ (checked 2026-11-15; reviewed 2.3.0)
# Read-only or stdout candidate/preview only. Requires the complete HTH checkout.
# HTH Guide Excerpt: begin data-policy
set +x
set -euo pipefail
PACK_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
python3 "$PACK_DIR/../../../scripts/lib/agent_hardening.py" emit "$@" --product opencode --section 4.2
# HTH Guide Excerpt: end data-policy
