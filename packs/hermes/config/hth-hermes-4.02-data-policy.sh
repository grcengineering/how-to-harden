#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: hermes-4.2
#   guide: https://howtoharden.com/guides/hermes/
#   profile: L1
#   mode: read-only
#   requires: POSIX Bash, Python 3.9+, complete HTH checkout; PyYAML for YAML input
# HTH Hermes Agent 4.2 — data-policy; L1/L2; NIST CM-6, AC-6.
# Guide: https://howtoharden.com/guides/hermes/
# Source: https://hermes-agent.nousresearch.com/docs/user-guide/security (checked 2026-11-15; reviewed 0.23.1)
# Read-only or stdout candidate/preview only. Requires the complete HTH checkout.
# HTH Guide Excerpt: begin data-policy
set +x
set -euo pipefail
PACK_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
python3 "$PACK_DIR/../../../scripts/lib/agent_hardening.py" emit "$@" --product hermes --section 4.2
# HTH Guide Excerpt: end data-policy
