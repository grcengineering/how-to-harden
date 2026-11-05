#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-work-codex-3.3
#   guide: https://howtoharden.com/guides/chatgpt-work-codex/#33-collect-minimal-telemetry-and-verify-compliance-coverage
#   profile: L2
#   mode: read-only
#   requires: bash; HTH_OTEL_ENDPOINT; Codex 0.166.0+ with requirements OTel support, excluded macOS alpha build
# Source: https://learn.chatgpt.com/docs/enterprise/managed-configuration (fetched 2026-11-05)
# Prints native TOML only. Does not deploy, merge or verify effective policy.
set -euo pipefail
# HTH Guide Excerpt: begin native-requirements
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"
[[ "$HTH_PROFILE_LEVEL" =~ ^[1234]$ && "$HTH_PROFILE_LEVEL" -ge 2 ]] || { echo 'This pack requires HTH_PROFILE_LEVEL=2 or higher (1-4)' >&2; exit 2; }
[[ "${HTH_OTEL_ENDPOINT:-}" =~ ^https://[A-Za-z0-9.-]+(:[0-9]+)?/[A-Za-z0-9/_-]+$ ]] || { echo 'Set HTH_OTEL_ENDPOINT to an approved HTTPS collector path (no credentials/query)' >&2; exit 2; }
printf '%s\n' '[otel]' 'environment = "managed"' "exporter = { otlp-http = { endpoint = \"$HTH_OTEL_ENDPOINT\", protocol = \"binary\" } }" 'log_user_prompt = false' 'log_agent_responses = false' 'log_guardian_assessments = false' 'tool_result = { max_bytes = 0 }'
# HTH Guide Excerpt: end native-requirements
