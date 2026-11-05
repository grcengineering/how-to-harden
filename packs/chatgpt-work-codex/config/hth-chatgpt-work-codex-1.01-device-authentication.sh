#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-work-codex-1.1
#   guide: https://howtoharden.com/guides/chatgpt-work-codex/#11-bind-approved-identities-and-protect-local-credentials
#   profile: L1
#   mode: read-only
#   requires: bash; HTH_WORKSPACE_ID; device requirements.toml delivery, not cloud policy
# Source: https://learn.chatgpt.com/docs/enterprise/managed-configuration (fetched 2026-11-05)
# Prints native TOML only. Does not deploy, merge or verify effective policy.
set -euo pipefail
# HTH Guide Excerpt: begin native-requirements
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"
[[ "$HTH_PROFILE_LEVEL" =~ ^[1234]$ && "$HTH_PROFILE_LEVEL" -ge 1 ]] || { echo 'This pack requires HTH_PROFILE_LEVEL=1 or higher (1-4)' >&2; exit 2; }
[[ "${HTH_WORKSPACE_ID:-}" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]] || { echo 'Set HTH_WORKSPACE_ID to the approved UUID' >&2; exit 2; }
printf 'allowed_login_methods = ["chatgpt"]\nallowed_chatgpt_workspaces = ["%s"]\ncli_auth_credentials_store = "keyring"\n' "$HTH_WORKSPACE_ID"
# HTH Guide Excerpt: end native-requirements
