#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: humanlayer-1.1
#   guide: https://howtoharden.com/guides/humanlayer/#11-protect-daemon-credentials-and-retire-stored-authentication
#   profile: L1
#   mode: mutating
#   requires: existing approved HumanLayer CLI; production account owner; HTH_APPLY=1 to execute
# HTH HumanLayer 1.1 — NIST IA-5, AC-6
# Source: https://docs.humanlayer.com/guide/remote-daemons (available; checked 2026-11-05)
# This removes production persistent login; it does not stop every supervisor or revoke provider credentials.
set +x
set -Eeuo pipefail
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# HTH Guide Excerpt: begin retire-persistent-login
hl_level 1
case "${HTH_APPLY:-0}" in
  0) printf 'DRY RUN: would invoke humanlayer logout for the current production user. Review beta and running daemons separately.\n' ;;
  1)
    command -v humanlayer >/dev/null 2>&1 || hl_unknown 'approved HumanLayer CLI is required'
    hl_temp="$(mktemp -d "${TMPDIR:-/tmp}/hth-humanlayer.XXXXXX")" || hl_unknown 'cannot create private temp directory'
    trap 'rm -rf -- "$hl_temp"' EXIT
    humanlayer logout > "$hl_temp/logout.stdout" 2> "$hl_temp/logout.stderr" ||
      hl_unknown 'logout failed; persistent authentication removal is unverified'
    printf 'REQUESTED: production logout. Verify stopped processes and independent credentials separately.\n'
    ;;
  *) hl_unknown 'HTH_APPLY must be 0 or 1' ;;
esac
# HTH Guide Excerpt: end retire-persistent-login
