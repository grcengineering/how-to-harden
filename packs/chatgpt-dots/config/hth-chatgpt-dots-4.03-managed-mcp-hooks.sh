#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-dots-4.3
#   guide: https://howtoharden.com/guides/chatgpt-dots/#43-treat-managed-mcp-hooks-for-dots-as-fail-open-telemetry-not-enforcement
#   profile: L2
#   mode: read-only
#   requires: bash; HTH_HOOK_SERVER and HTH_HOOK_TOOL; approved managed MCP service, cloud-supported event
# Source: https://learn.chatgpt.com/docs/hooks (fetched 2026-11-05)
# Emits native TOML only. Review and deliver to the documented plane manually.
set -euo pipefail
umask 077
# HTH Guide Excerpt: begin native-requirements
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"
[[ "$HTH_PROFILE_LEVEL" =~ ^[1234]$ && "$HTH_PROFILE_LEVEL" -ge 2 ]] || { echo 'This pack requires HTH_PROFILE_LEVEL=2 or higher (1-4)' >&2; exit 2; }
[[ "${HTH_HOOK_SERVER:-}" =~ ^[A-Za-z0-9_-]+$ && "${HTH_HOOK_TOOL:-}" =~ ^[A-Za-z0-9_.-]+$ ]] || { echo 'Set approved HTH_HOOK_SERVER and HTH_HOOK_TOOL identifiers' >&2; exit 2; }
printf '%s\n' '[[hooks.PreToolUse]]' '[[hooks.PreToolUse.hooks]]' 'type = "mcp_tool"' "server = \"$HTH_HOOK_SERVER\"" "tool = \"$HTH_HOOK_TOOL\"" 'timeout = 30' 'input = { session_id = "${session_id}", tool_name = "${tool_name}", tool_use_id = "${tool_use_id}", tool_input = "${tool_input}" }'
echo 'PreToolUse errors/timeouts fail open; configuration is not enforcement proof.' >&2
# HTH Guide Excerpt: end native-requirements
