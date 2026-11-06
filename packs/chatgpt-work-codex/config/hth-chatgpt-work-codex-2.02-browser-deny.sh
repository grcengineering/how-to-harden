#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-work-codex-2.2
#   guide: https://howtoharden.com/guides/chatgpt-work-codex/#22-restrict-browser-access-across-every-enabled-browser-route
#   profile: L2
#   mode: read-only
#   requires: bash; supported local client; cloud browser permissions separately administered
# Source: https://learn.chatgpt.com/docs/enterprise/managed-configuration (fetched 2026-11-05)
# Prints native TOML only. Does not deploy, merge or verify effective policy.
set -euo pipefail
# HTH Guide Excerpt: begin native-requirements
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"
[[ "$HTH_PROFILE_LEVEL" =~ ^[1234]$ && "$HTH_PROFILE_LEVEL" -ge 2 ]] || { echo 'This pack requires HTH_PROFILE_LEVEL=2 or higher (1-4)' >&2; exit 2; }
cat <<'TOML'
# requirements.toml. Disable every unneeded local browser route.
[features]
browser_use = false
browser_use_external = false
browser_use_full_cdp_access = false
in_app_browser = false

[browser_use]
allow_history_access = false
allow_global_persistent_approval = false

[browser_use.default_origin_policy]
access = "deny"
TOML
# HTH Guide Excerpt: end native-requirements
