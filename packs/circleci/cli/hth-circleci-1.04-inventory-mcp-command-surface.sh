#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: circleci-1.4
#   guide: https://howtoharden.com/guides/circleci/#14-bound-mcp-access-and-retire-the-deprecated-server
#   profile: L2
#   mode: read-only
#   requires: current official circleci CLI
# Source: https://circleci.com/docs/guides/toolkit/circleci-mcp-overview/ (2026-11-12)
set -euo pipefail
# HTH Guide Excerpt: begin mcp-command-inventory
: "${HTH_PROFILE_LEVEL:=1}"
[[ "$HTH_PROFILE_LEVEL" =~ ^[234]$ ]] || { echo 'Requires HTH_PROFILE_LEVEL=2 or higher' >&2; exit 2; }
command -v circleci >/dev/null || { echo 'Install the reviewed official CircleCI CLI' >&2; exit 2; }
# The CLI MCP mirrors this command surface. No credentials or MCP server started.
circleci help reference
# Inventory only: approval and token restrictions must be checked independently.
# HTH Guide Excerpt: end mcp-command-inventory
