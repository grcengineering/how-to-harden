#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-cli-3.2
#   guide: https://howtoharden.com/guides/devin-cli/#32-restrict-configuration-imports
#   profile: L2
#   mode: read-only
#   requires: bash, Devin CLI
# HTH Control 3.02: Restrict Configuration Imports
# Framework: NIST SP 800-53 Rev. 5 CM-6
# Source (fetched 2026-10-29): https://docs.devin.ai/cli/reference/commands
# Validation: offline fixtures only; not tested with a Devin account.

# HTH Guide Excerpt: begin restrict-configuration-imports
set -euo pipefail
# Read-only inventory of effective rules and skills; not their contents.
# Run from the reviewed project directory. Native and lazy-loaded sources
# still need review; this does not prove every possible imported hook is absent.
[ "$#" -eq 0 ] || { echo 'Usage: script (no arguments)' >&2; exit 2; }
command -v devin >/dev/null || { echo 'Devin CLI is not installed' >&2; exit 1; }
devin rules list
devin skills list
# HTH Guide Excerpt: end restrict-configuration-imports
