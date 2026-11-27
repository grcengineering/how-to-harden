#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tresorit-1.2
#   guide: https://howtoharden.com/guides/tresorit/#12-restrict-devices-and-folder-sharing-by-policy
#   profile: L1
#   mode: read-only
#   requires: vendor tresorit-cli on an approved Linux client
# Source (reviewed 2026-11-27): https://support.tresorit.com/hc/en-us/articles/360009330614-Using-Tresorit-CLI-for-Linux
# HTH Guide Excerpt: begin check-linux-client-session
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }

command -v tresorit-cli >/dev/null || fail 'Tresorit Linux CLI is not installed'
tresorit-cli status
# HTH Guide Excerpt: end check-linux-client-session
