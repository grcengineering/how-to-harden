#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-dots-4.2
#   guide: https://howtoharden.com/guides/chatgpt-dots/#42-enforce-orchestrator-approval-and-web-search-limits-in-the-agent-security-global-baseline
#   profile: L2
#   mode: read-only
#   requires: bash; supported Global requirements editor; separate local/cloud executor checks
# Source: https://learn.chatgpt.com/docs/enterprise/managed-configuration (fetched 2026-11-05)
# Emits native TOML only. Review and deliver to the documented plane manually.
set -euo pipefail
umask 077
# HTH Guide Excerpt: begin native-requirements
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"
[[ "$HTH_PROFILE_LEVEL" =~ ^[1234]$ && "$HTH_PROFILE_LEVEL" -ge 2 ]] || { echo 'This pack requires HTH_PROFILE_LEVEL=2 or higher (1-4)' >&2; exit 2; }
cat <<'TOML'
# Global requirements.toml; conditional on managed policy and supported runtime.
allowed_approval_policies = ["on-request"]
allowed_web_search_modes = ["disabled"]
TOML
# HTH Guide Excerpt: end native-requirements
