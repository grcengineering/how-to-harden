#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-work-codex-3.4
#   guide: https://howtoharden.com/guides/chatgpt-work-codex/#34-authenticate-and-verify-self-hosted-configuration-delivery
#   profile: L2
#   mode: read-only
#   requires: bash; HTH_CONFIG_BASE_URL; administrator-owned device requirements delivery
# Source: https://learn.chatgpt.com/docs/enterprise/configuration-server (fetched 2026-11-05)
# Emits the native bootstrap only; optional OAuth requires reviewed IdP endpoints.
set -euo pipefail
# HTH Guide Excerpt: begin native-requirements
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"
[[ "$HTH_PROFILE_LEVEL" =~ ^[1234]$ && "$HTH_PROFILE_LEVEL" -ge 2 ]] || { echo 'This pack requires HTH_PROFILE_LEVEL=2 or higher (1-4)' >&2; exit 2; }
[[ "${HTH_CONFIG_BASE_URL:-}" =~ ^https://[A-Za-z0-9.-]+(:[0-9]+)?(/[A-Za-z0-9/_-]*)?$ ]] || { echo 'Set HTH_CONFIG_BASE_URL to the approved HTTPS base without credentials, query or fragment' >&2; exit 2; }
printf '[config_server]\nbase_url = "%s"\n' "$HTH_CONFIG_BASE_URL"
echo 'Deploy only through admin-owned device requirements; authenticate the endpoint if policy requires it. Inspect /debug-config after refresh/restart.' >&2
# HTH Guide Excerpt: end native-requirements
