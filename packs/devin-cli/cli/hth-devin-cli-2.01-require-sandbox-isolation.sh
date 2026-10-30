#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-cli-2.1
#   guide: https://howtoharden.com/guides/devin-cli/#21-require-sandbox-isolation
#   profile: L2
#   mode: mutating
#   requires: bash, Devin CLI; Linux bwrap and socat; macOS or Linux
# HTH Control 2.01: Require Sandbox Isolation
# Framework: NIST SP 800-53 Rev. 5 CM-6
# Source (fetched 2026-10-29): https://docs.devin.ai/cli/sandbox
# Validation: offline fixtures only; not tested with a Devin account.

# HTH Guide Excerpt: begin require-sandbox-isolation
set -euo pipefail
# Default: dependency preflight only. No CLI session or model call starts.
# --launch: explicitly starts an INTERACTIVE sandboxed session, with no prompt.
# This is not runtime proof of sandbox isolation or enterprise policy.
case "${1:-check}" in
  check|--launch) action="${1:-check}" ;;
  *) echo 'Usage: script [check|--launch]' >&2; exit 2 ;;
esac
[ "$#" -le 1 ] || { echo 'Unexpected arguments' >&2; exit 2; }
command -v devin >/dev/null || { echo 'Devin CLI is not installed' >&2; exit 1; }
case "$(uname -s)" in
  Darwin) ;;
  Linux)
    for tool in bwrap socat; do
      command -v "$tool" >/dev/null || { echo "Missing sandbox dependency: $tool" >&2; exit 1; }
    done ;;
  *) echo 'Unsupported OS: native Windows sandbox is not supported' >&2; exit 1 ;;
esac
if [ "$action" = '--launch' ]; then
  exec devin --sandbox --permission-mode autonomous --respect-workspace-trust true
fi
printf '%s\n' 'Preflight only: dependencies found; actual sandbox resolution remains untested.'
printf '%s\n' 'After reviewing workspace/config, pass --launch to start the sandboxed CLI.'
# HTH Guide Excerpt: end require-sandbox-isolation
