#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-work-codex-2.4
#   guide: https://howtoharden.com/guides/chatgpt-work-codex/#24-constrain-command-egress-and-review-every-independent-network-path
#   profile: L2
#   mode: read-only
#   requires: bash; approved administrator-owned destinations; test proxy, escalation, loopback and other egress routes
# Source: https://learn.chatgpt.com/docs/enterprise/managed-configuration (fetched 2026-11-05)
# Prints native TOML only. Does not deploy, merge or verify effective policy.
set -euo pipefail
# HTH Guide Excerpt: begin native-requirements
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"
[[ "$HTH_PROFILE_LEVEL" =~ ^[1234]$ && "$HTH_PROFILE_LEVEL" -ge 2 ]] || { echo 'This pack requires HTH_PROFILE_LEVEL=2 or higher (1-4)' >&2; exit 2; }
cat <<'TOML'
# requirements.toml. Compatibility name; canonical network_proxy needs 0.166.0.
# Replace/extend this exact domain map through review; do not add legacy lists.
[experimental_network]
enabled = true
managed_allowed_domains_only = true

[experimental_network.domains]
"api.openai.com" = "allow"
TOML
# HTH Guide Excerpt: end native-requirements
