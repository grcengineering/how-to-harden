#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-cli-2.2
#   guide: https://howtoharden.com/guides/devin-cli/#22-preserve-workspace-trust
#   profile: L1
#   mode: mutating
#   requires: bash, Devin CLI for --launch
# HTH Control 2.02: Preserve Workspace Trust
# Framework: NIST SP 800-53 Rev. 5 CM-6
# Source (fetched 2026-10-29): https://docs.devin.ai/cli/reference/commands
# Validation: offline fixtures only; not tested with a Devin account.

# HTH Guide Excerpt: begin preserve-workspace-trust
set -euo pipefail
# Default: print the planned command; never run a session or trust a workspace.
# Use the sandbox launcher instead when OS isolation is required.
[ "$#" -le 1 ] || { echo 'Usage: script [--launch]' >&2; exit 2; }
case "${1:-}" in
  '') printf '%s\n' 'DRY RUN: devin --permission-mode normal --respect-workspace-trust true' ;;
  --launch)
    command -v devin >/dev/null || { echo 'Devin CLI is not installed' >&2; exit 1; }
    exec devin --permission-mode normal --respect-workspace-trust true ;;
  *) echo 'Usage: script [--launch]' >&2; exit 2 ;;
esac
# HTH Guide Excerpt: end preserve-workspace-trust
