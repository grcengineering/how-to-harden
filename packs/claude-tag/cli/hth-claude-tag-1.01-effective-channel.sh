#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: claude-tag-1.1
#   guide: https://howtoharden.com/guides/claude-tag/#11-inventory-effective-access-before-enabling-tools
#   profile: L1
#   mode: read-only
#   requires: official ant CLI, jq, organization-scoped claude.ai read:claude_tag key
# HTH 1.01: Read effective Claude Tag policy for one exact channel using official ant
# Profile: L1 | NIST CSF PR.AA-05 | https://howtoharden.com/guides/claude-tag/
# Beta, Claude Enterprise only; not Team or Claude Console Admin API credentials.
# Sources: https://platform.claude.com/docs/en/manage-claude/claude-tag-api
# https://platform.claude.com/docs/en/cli-sdks-libraries/cli/using
# Requires current official ant CLI + jq. No installation or live validation implied.
# Set ANTHROPIC_API_KEY (claude.ai org-scoped read:claude_tag) and HTH_CHANNEL_ID=slch_...
# This single-resource check supplements, does not replace, the full API inventory.
# HTH Guide Excerpt: begin effective-channel
set +x
set -euo pipefail
umask 077
[[ "${HTH_CHANNEL_ID:-}" =~ ^slch_[A-Za-z0-9]+$ ]] || { echo 'Supply HTH_CHANNEL_ID.' >&2; exit 2; }
[[ -n "${ANTHROPIC_API_KEY:-}" && "$ANTHROPIC_API_KEY" != *[[:space:]]* ]] || exit 2
# Do not combine org Admin API credentials with ambient bearer tokens or profiles.
[[ -z "${ANTHROPIC_AUTH_TOKEN+x}" && -z "${ANTHROPIC_PROFILE+x}" ]] || { echo 'Unset bearer token and named profile for this scoped-key check.' >&2; exit 2; }
command -v ant >/dev/null; command -v jq >/dev/null
# Builtin printf feeds the key through stdin, never argv. Never enable --debug.
# Pin origin regardless of ambient base URL; CLI supplies beta/version headers.
if ! response=$(printf '%s' "$ANTHROPIC_API_KEY" | ant beta:organization:claude-tag:slack-channels retrieve \
    --id "$HTH_CHANNEL_ID" --include-inherited --api-key-stdin \
    --base-url https://api.anthropic.com --format json 2>/dev/null); then
  echo 'Read failed; verify CLI version, scoped key, API availability and target. No evidence emitted.' >&2
  exit 1
fi
printf '%s' "$response" | jq -cse --arg id "$HTH_CHANNEL_ID" '
  if length==1 and .[0].id==$id and .[0].type=="slack_channel" and
    (.[0].settings.enabled|type)=="boolean" and (.[0].settings.guest_policy.type|type)=="string"
  then .[0] | {id,slack,settings:(.settings|del(.instructions)),sources:(.sources|del(.instructions)),
    scope:"one configured channel; not Bundle contents or complete Slack inventory"}
  else error("Unexpected response; no verified effective policy") end'
# HTH Guide Excerpt: end effective-channel
