#!/usr/bin/env bash
# Claude Tag beta transport. Source, do not execute. Never use a Console key.
set -euo pipefail
ANTHROPIC_VERSION=2026-10-21
HTH_ANTHROPIC_BETA=experimental-claude-tag-2026-10-21
ANTHROPIC_PAGE_LIMIT=100
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../anthropic-claude/api" && pwd)/common.sh"
require_admin_key() {
  [[ -n "${ANTHROPIC_ADMIN_KEY:-}" && "${ANTHROPIC_ADMIN_KEY}" != *[[:space:]]* ]] || {
    echo 'Set ANTHROPIC_ADMIN_KEY to an organization-scoped claude.ai Settings > API key with read:claude_tag (also write:claude_tag for apply).' >&2; return 2;
  }
}
TAG_ROOT=/v1/organizations/claude_tag
tag_channel_valid() {
  jq -e --arg id "$1" '.id == $id and .type == "slack_channel" and (.slack.workspace_id|type)=="string" and (.slack.channel_id|type)=="string" and (.settings|type)=="object" and (.settings|has("enabled") and has("guest_policy") and has("model") and has("environment_id") and has("instructions"))' >/dev/null
}
