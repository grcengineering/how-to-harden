#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cursor-4.2
#   guide:   https://howtoharden.com/guides/cursor/#42-enable-mcp-tool-protection
#   profile: L1
#   mode:    read-only
#   requires: jq
# =============================================================================
# HTH Cursor Control 4.2: Enable MCP Tool Protection
# Profile Level: L1 (Crawl) | NIST 800-53: AC-6
# Source: https://howtoharden.com/guides/cursor/#42-enable-mcp-tool-protection
#
# Every entry in `mcpAllowlist` removes the per-call approval prompt for that
# MCP tool. Cursor reads it from two files and CONCATENATES them
# (https://cursor.com/docs/enterprise/deployment-patterns — "Managing Run Mode
# allowlists with MDM"):
#   ~/.cursor/permissions.json                 (per-user, MDM-deployable)
#   <workspace>/.cursor/permissions.json       (per-repo, committed)
# Entry forms: server:tool | server:* | *:tool | *:*
# A team-dashboard allowlist overrides both files and is not visible here.
#
# Findings: `*:*` (every tool on every server), `server:*` (every tool on a
# server, including ones it adds later), `*:tool` (that tool name on ANY server,
# including one an attacker registers).
#
# Exit codes: 0 no wildcard entries | 1 finding | 2 precondition (jq missing,
# or a permissions.json that does not parse — Cursor falls back silently)
# =============================================================================

set -uo pipefail

command -v jq >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

# HTH Guide Excerpt: begin cli-audit-mcp-allowlist
FINDINGS=0
FILES_SEEN=0
for PERM_FILE in "${HOME}/.cursor/permissions.json" ".cursor/permissions.json"; do
  [ -f "${PERM_FILE}" ] || continue
  FILES_SEEN=$((FILES_SEEN + 1))
  if ! jq -e . "${PERM_FILE}" >/dev/null 2>&1; then
    echo "ERROR: ${PERM_FILE} is not valid JSON — Cursor will not apply it as written"
    exit 2
  fi
  echo "=== ${PERM_FILE}: mcpAllowlist ==="
  ENTRIES=$(jq -r '(.mcpAllowlist // [])[]' "${PERM_FILE}")
  if [ -z "${ENTRIES}" ]; then
    echo "  (none — every MCP tool call keeps its approval prompt, unless a team policy says otherwise)"
    continue
  fi
  while IFS= read -r ENTRY; do
    case "${ENTRY}" in
      '*:*') echo "  FINDING: ${ENTRY} — pre-approves every tool on every MCP server"; FINDINGS=$((FINDINGS + 1)) ;;
      *':*') echo "  FINDING: ${ENTRY} — pre-approves every tool on this server, including tools added later"; FINDINGS=$((FINDINGS + 1)) ;;
      '*:'*) echo "  FINDING: ${ENTRY} — pre-approves this tool name on ANY server, including an attacker's"; FINDINGS=$((FINDINGS + 1)) ;;
      *)     echo "  ok:      ${ENTRY} — confirm this tool is read-only and low-consequence" ;;
    esac
  done < <(printf '%s\n' "${ENTRIES}")
done

[ "${FILES_SEEN}" -gt 0 ] || echo "No permissions.json found — Cursor uses the editor-managed allowlist; review it in Settings > Agents > Approvals & Execution"
if [ "${FINDINGS}" -gt 0 ]; then
  echo "${FINDINGS} wildcard MCP allowlist entr(y/ies) — replace each with explicit server:tool pairs"
  exit 1
fi
echo "PASS: no wildcard MCP allowlist entries"
exit 0
# HTH Guide Excerpt: end cli-audit-mcp-allowlist
