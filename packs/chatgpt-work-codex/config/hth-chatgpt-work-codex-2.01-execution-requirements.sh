#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-work-codex-2.1
#   guide: https://howtoharden.com/guides/chatgpt-work-codex/#21-enforce-permission-profiles-approvals-and-denied-reads
#   profile: L1
#   mode: read-only
#   requires: bash; supporting runtime; verify denied reads per OS, glob timing and actual requirements precedence
# Source: https://learn.chatgpt.com/docs/enterprise/managed-configuration (fetched 2026-11-05)
# Prints native TOML only. Does not deploy, merge or verify effective policy.
set -euo pipefail
# HTH Guide Excerpt: begin native-requirements
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"
[[ "$HTH_PROFILE_LEVEL" =~ ^[1234]$ && "$HTH_PROFILE_LEVEL" -ge 1 ]] || { echo 'This pack requires HTH_PROFILE_LEVEL=1 or higher (1-4)' >&2; exit 2; }
cat <<'TOML'
# requirements.toml; profiles require Codex >=0.138.0.
default_permissions = ":read-only"
allowed_approval_policies = ["on-request"]
allowed_sandbox_modes = ["read-only", "workspace-write"]

[allowed_permission_profiles]
":read-only" = true
":workspace" = true

[permissions.filesystem]
deny_read = ["~/.ssh", "/**/*.env"]

[rules]
prefix_rules = [
  { pattern = [{ any_of = ["bash", "sh", "zsh"] }], decision = "prompt", justification = "Review shell entry points" },
]
TOML
# HTH Guide Excerpt: end native-requirements
