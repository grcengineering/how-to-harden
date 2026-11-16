#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: oh-my-pi-3.1
#   guide: https://howtoharden.com/guides/oh-my-pi/
#   profile: L1
#   mode: read-only
#   requires: POSIX Bash, Python 3.9+, complete HTH checkout; PyYAML for YAML input
# HTH OhMyPi 3.1 — credential-environment; L1/L2; NIST CM-6, AC-6.
# Guide: https://howtoharden.com/guides/oh-my-pi/
# Source: https://github.com/can1357/oh-my-pi/blob/v18.20.2/docs/settings.md (checked 2026-11-15; reviewed 18.20.2)
# Read-only or stdout candidate/preview only. Requires the complete HTH checkout.
# HTH Guide Excerpt: begin credential-environment
set +x
set -euo pipefail
PACK_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
python3 "$PACK_DIR/../../../scripts/lib/agent_hardening.py" environment "$@" --product oh-my-pi --scope credentials
# HTH Guide Excerpt: end credential-environment
