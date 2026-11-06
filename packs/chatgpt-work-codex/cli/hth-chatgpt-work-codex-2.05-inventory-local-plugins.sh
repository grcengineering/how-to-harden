#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-work-codex-2.5
#   guide: https://howtoharden.com/guides/chatgpt-work-codex/#25-admit-trusted-mcp-servers-plugins-and-marketplaces
#   profile: L1
#   mode: read-only
#   requires: Codex CLI; approved local identity (no install or plugin execution)
# Source: https://learn.chatgpt.com/docs/security/cli/reference (fetched 2026-11-05)
set -euo pipefail
umask 077
# HTH Guide Excerpt: begin cli-check
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"
[[ "$HTH_PROFILE_LEVEL" =~ ^[1234]$ && "$HTH_PROFILE_LEVEL" -ge 1 ]] || { echo 'This pack requires profile 1 or higher (1-4)' >&2; exit 2; }
command -v codex >/dev/null || { echo 'Codex CLI is required' >&2; exit 2; }
codex --version
codex plugin list --json
echo 'Inventory only: inspect identities and effective policy separately.' >&2
# HTH Guide Excerpt: end cli-check
