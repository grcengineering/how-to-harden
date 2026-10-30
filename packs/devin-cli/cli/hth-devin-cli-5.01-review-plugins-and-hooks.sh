#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-cli-5.1
#   guide: https://howtoharden.com/guides/devin-cli/#51-review-plugins-and-hooks
#   profile: L2
#   mode: read-only
#   requires: bash, Devin CLI
# HTH Control 5.01: Review Plugins and Hooks
# Framework: NIST SP 800-53 Rev. 5 CM-6
# Source (fetched 2026-10-29): https://docs.devin.ai/cli/extensibility/plugins/overview
# Validation: offline fixtures only; not tested with a Devin account.

# HTH Guide Excerpt: begin review-plugins-and-hooks
set -euo pipefail
# No install/update/remove operations. The list is inventory, not a security scan.
[ "$#" -eq 0 ] || { echo 'Usage: script (no arguments)' >&2; exit 2; }
command -v devin >/dev/null || { echo 'Devin CLI is not installed' >&2; exit 1; }
devin plugins list
printf '%s\n' 'Review /hooks inside an already-trusted session for loaded hooks and source files.'
printf '%s\n' 'Do not start an unreviewed workspace merely to inspect hooks: SessionStart hooks can execute.'
# HTH Guide Excerpt: end review-plugins-and-hooks
