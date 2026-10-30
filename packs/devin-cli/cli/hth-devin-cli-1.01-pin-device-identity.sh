#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-cli-1.1
#   guide: https://howtoharden.com/guides/devin-cli/#11-pin-device-identity
#   profile: L2
#   mode: read-only
#   requires: bash, installed Devin CLI
# HTH Control 1.01: Pin Device Identity
# Framework: NIST SP 800-53 Rev. 5 CM-6
# Source (fetched 2026-10-29): https://docs.devin.ai/cli/reference/commands
# Validation: offline fixtures only; not tested with a Devin account.

# HTH Guide Excerpt: begin pin-device-identity
set -euo pipefail
# Read-only status, not a login/logout flow. Output can identify the account;
# review it locally instead of posting it in tickets or CI logs.
[ "$#" -eq 0 ] || { echo 'Usage: script (no arguments)' >&2; exit 2; }
command -v devin >/dev/null || { echo 'Devin CLI is not installed' >&2; exit 1; }
devin version
devin auth status
# HTH Guide Excerpt: end pin-device-identity
