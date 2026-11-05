#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-work-codex-4.4
#   guide: https://howtoharden.com/guides/chatgpt-work-codex/#44-verify-native-windows-isolation-and-platform-support
#   profile: L2
#   mode: read-only
#   requires: bash; compatible Windows runtime; verify MXC host capabilities, loopback and effective policy
# Source: https://learn.chatgpt.com/docs/windows/windows-sandbox (fetched 2026-11-05)
# Prints native TOML only. Does not deploy, merge or verify effective policy.
set -euo pipefail
# HTH Guide Excerpt: begin native-requirements
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"
[[ "$HTH_PROFILE_LEVEL" =~ ^[1234]$ && "$HTH_PROFILE_LEVEL" -ge 2 ]] || { echo 'This pack requires HTH_PROFILE_LEVEL=2 or higher (1-4)' >&2; exit 2; }
cat <<'TOML'
# requirements.toml. prefer_mxc allows fallback; this constrains legacy fallback.
[features]
prefer_mxc = true

[windows]
allowed_sandbox_implementations = ["elevated"]
TOML
# HTH Guide Excerpt: end native-requirements
