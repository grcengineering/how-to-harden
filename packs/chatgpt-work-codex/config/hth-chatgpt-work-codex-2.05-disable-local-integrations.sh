#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-work-codex-2.5
#   guide: https://howtoharden.com/guides/chatgpt-work-codex/#25-admit-trusted-mcp-servers-plugins-and-marketplaces
#   profile: L1
#   mode: read-only
#   requires: bash; supported local policy; separately govern bundled/remote/workspace plugins
# Source: https://learn.chatgpt.com/docs/enterprise/managed-configuration (fetched 2026-11-05)
# Prints native TOML only. Does not deploy, merge or verify effective policy.
set -euo pipefail
# HTH Guide Excerpt: begin native-requirements
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"
[[ "$HTH_PROFILE_LEVEL" =~ ^[1234]$ && "$HTH_PROFILE_LEVEL" -ge 1 ]] || { echo 'This pack requires HTH_PROFILE_LEVEL=1 or higher (1-4)' >&2; exit 2; }
cat <<'TOML'
# requirements.toml. An empty MCP table disables all local MCP servers.
[mcp_servers]

[features]
plugins = false
TOML
# HTH Guide Excerpt: end native-requirements
