#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-dots-5.1
#   guide: https://howtoharden.com/guides/chatgpt-dots/#51-keep-dots-out-of-workspaces-and-populations-that-require-residency-ekm-or-zero-retention
#   profile: L3
#   mode: read-only
#   requires: bash; HTH_CONFIRM_US_CODEX_RESIDENCY=yes; reviewed impact on incompatible products
# Source: https://learn.chatgpt.com/docs/enterprise/managed-configuration (fetched 2026-11-05)
# Emits native TOML only. Review and deliver to the documented plane manually.
set -euo pipefail
umask 077
# HTH Guide Excerpt: begin native-requirements
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"
[[ "$HTH_PROFILE_LEVEL" =~ ^[1234]$ && "$HTH_PROFILE_LEVEL" -ge 3 ]] || { echo 'This pack requires HTH_PROFILE_LEVEL=3 or higher (1-4)' >&2; exit 2; }
[[ "${HTH_CONFIRM_US_CODEX_RESIDENCY:-}" = yes ]] || { echo 'Set HTH_CONFIRM_US_CODEX_RESIDENCY=yes only for the documented US Codex restriction; it disables incompatible dots/Work local access.' >&2; exit 2; }
printf '%s\n' '# requirements.toml; NOT a dots storage-region selector.' 'enforce_residency = "us"'
# HTH Guide Excerpt: end native-requirements
