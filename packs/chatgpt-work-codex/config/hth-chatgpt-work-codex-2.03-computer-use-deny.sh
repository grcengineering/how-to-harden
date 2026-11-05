#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-work-codex-2.3
#   guide: https://howtoharden.com/guides/chatgpt-work-codex/#23-limit-native-computer-use-and-locked-device-access
#   profile: L2
#   mode: read-only
#   requires: bash; supported local client; review existing locked-use state and OS app permissions
# Source: https://learn.chatgpt.com/docs/enterprise/managed-configuration (fetched 2026-11-05)
# Prints native TOML only. Does not deploy, merge or verify effective policy.
set -euo pipefail
# HTH Guide Excerpt: begin native-requirements
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"
[[ "$HTH_PROFILE_LEVEL" =~ ^[1234]$ && "$HTH_PROFILE_LEVEL" -ge 2 ]] || { echo 'This pack requires HTH_PROFILE_LEVEL=2 or higher (1-4)' >&2; exit 2; }
cat <<'TOML'
# requirements.toml. Existing locked-use state must also be disabled on device.
[features]
computer_use = false

[computer_use]
default_app_access = "deny"
allow_persistent_approval = false
allow_locked_computer_use = false
TOML
# HTH Guide Excerpt: end native-requirements
