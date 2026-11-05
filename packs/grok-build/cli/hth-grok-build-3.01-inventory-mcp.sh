#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-build-3.1
#   guide: https://howtoharden.com/guides/grok-build/#31-review-mcp-origins-and-restrict-server-authority
#   profile: L1
#   mode: read-only
#   requires: bash; grok; HTH_RUN_GROK_READS=1
#   changes: opt-in native configuration reads, private local evidence files; no MCP doctor/login
#   source: https://docs.x.ai/build/features/mcp-servers
# HTH Guide Excerpt: begin inventory-mcp
set -euo pipefail
if [[ "${HTH_RUN_GROK_READS:-}" != 1 ]]; then
  echo 'PRECONDITION: set HTH_RUN_GROK_READS=1 to collect local CLI inventory. It may contain sensitive configuration.' >&2
  exit 2
fi
command -v grok >/dev/null || { echo 'PRECONDITION: Grok Build is not installed; this pack does not install it.' >&2; exit 2; }
export GROK_DISABLE_AUTOUPDATER=1
umask 077
evidence_dir=$(mktemp -d "${TMPDIR:-/tmp}/hth-grok-build-mcp.XXXXXX")
trap 'echo "PARTIAL evidence retained at: $evidence_dir" >&2' ERR
grok inspect --json >"$evidence_dir/inspect.json" 2>"$evidence_dir/inspect.stderr"
grok mcp list --json >"$evidence_dir/mcp-list.json" 2>"$evidence_dir/mcp-list.stderr"
printf 'COLLECTED: private evidence at %s\n' "$evidence_dir"
printf '%s\n' 'NOT ASSESSED: native output schema, source completeness, endpoint provenance, token scope and effective enforcement. Review evidence before trusting a repository.'
# HTH Guide Excerpt: end inventory-mcp
