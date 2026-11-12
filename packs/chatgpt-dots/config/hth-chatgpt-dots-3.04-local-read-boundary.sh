#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-dots-3.4
#   guide: https://howtoharden.com/guides/chatgpt-dots/#34-keep-allow-local-computer-access-off-for-dots
#   profile: L2
#   mode: read-only
#   requires: bash; supported local requirements delivery; verify OS-specific denied-read coverage
# Source: https://learn.chatgpt.com/docs/enterprise/managed-configuration (2026-11-12)
# NIST AC-6, CM-6; CIS Controls v8 4.1, 6.1
# Emits only: review/merge into LOCAL execution requirements, never assume cloud enforcement.
set -euo pipefail
# HTH Guide Excerpt: begin local-read-boundary
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"
[[ "$HTH_PROFILE_LEVEL" =~ ^[1234]$ && "$HTH_PROFILE_LEVEL" -ge 2 ]] || { echo 'This pack requires HTH_PROFILE_LEVEL=2 or higher (1-4)' >&2; exit 2; }
cat <<'TOML'
# Review application-specific credentials before deployment. Not an exhaustive secret list.
# Native Windows shell subprocess reads do not enforce deny_read; validate OS coverage.
allowed_sandbox_modes = ["read-only"]
[permissions.filesystem]
deny_read = ["~/.ssh", "/**/*.env"]
TOML
# HTH Guide Excerpt: end local-read-boundary
