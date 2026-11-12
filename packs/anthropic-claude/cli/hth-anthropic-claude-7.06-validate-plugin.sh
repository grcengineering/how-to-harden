#!/usr/bin/env bash
# HTH Claude Code 2.2 / shared pack 7.6: Validate a reviewed local plugin
# Profile: L2 | NIST: CM-7, SI-7 | SOC 2: CC6.1, CC8.1
# https://howtoharden.com/guides/claude-code/#22-lock-down-hooks-and-plugins
# Source: https://code.claude.com/docs/en/plugins-reference#validate-the-manifest
# Read-only native CLI validation. Does not install, load, update or execute the plugin.
set -euo pipefail
# HTH Guide Excerpt: begin validate-reviewed-plugin
# Use a reviewed installed Claude Code release (v2.1.281+ for MCP checks).
# Passing validation is not a safety verdict: inspect code, network/process access,
# dependencies, injected commands and any runtime-downloaded code separately.
[[ $# == 1 && -d "$1" ]] || { echo 'Usage: bash validate-plugin.sh LOCAL_PLUGIN_DIRECTORY' >&2; exit 2; }
command -v claude >/dev/null || { echo 'Claude Code CLI is required.' >&2; exit 2; }
plugin_dir=$(cd -- "$1" && pwd -P)
claude plugin validate "$plugin_dir" --strict
# HTH Guide Excerpt: end validate-reviewed-plugin
