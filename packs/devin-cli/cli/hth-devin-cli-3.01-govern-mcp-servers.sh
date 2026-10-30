#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-cli-3.1
#   guide: https://howtoharden.com/guides/devin-cli/#31-govern-mcp-servers
#   profile: L2
#   mode: mutating
#   requires: bash, Devin CLI; server name and exact scope for disable
# HTH Control 3.01: Govern MCP Servers
# Framework: NIST SP 800-53 Rev. 5 CM-6
# Source (fetched 2026-10-29): https://docs.devin.ai/cli/extensibility/mcp/configuration
# Validation: offline fixtures only; not tested with a Devin account.

# HTH Guide Excerpt: begin govern-mcp-servers
set -euo pipefail
# list is read-only. disable changes only the named scope, only with --apply.
# List output may contain internal server metadata; keep it local.
case "${1:-list}" in
  list)
    [ "$#" -le 1 ] || { echo 'Usage: script list' >&2; exit 2; }
    command -v devin >/dev/null || { echo 'Devin CLI is not installed' >&2; exit 1; }
    devin mcp list ;;
  disable)
    [ "$#" -ge 3 ] && [ "$#" -le 4 ] || { echo 'Usage: script disable NAME local|project|user [--apply]' >&2; exit 2; }
    name="$2"; scope="$3"
    [[ "$name" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || { echo 'Invalid server name' >&2; exit 2; }
    case "$scope" in local|project|user) ;; *) echo 'Invalid scope' >&2; exit 2;; esac
    if [ "$#" -eq 4 ]; then
      [ "$4" = '--apply' ] || { echo 'Expected --apply' >&2; exit 2; }
      command -v devin >/dev/null || { echo 'Devin CLI is not installed' >&2; exit 1; }
      devin mcp disable "$name" --scope "$scope"
    else
      printf 'DRY RUN: devin mcp disable %q --scope %q\n' "$name" "$scope"
    fi ;;
  *) echo 'Usage: script list | disable NAME local|project|user [--apply]' >&2; exit 2 ;;
esac
# HTH Guide Excerpt: end govern-mcp-servers
