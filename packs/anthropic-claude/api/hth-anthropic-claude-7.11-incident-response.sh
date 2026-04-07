#!/usr/bin/env bash
# HTH Anthropic Claude Control 7.11: Incident Response for Claude Code and Cowork
# Profile: L2 | NIST: IR-4, IR-5, IR-8 | SOC 2: CC7.3, CC7.4
# https://howtoharden.com/guides/anthropic-claude/#711-establish-incident-response-for-claude-code-and-cowork
#
# Forensic collection and triage script for Claude Code/Cowork incidents.
# Collects local session data before cleanup triggers deletion.
# Reference: code.claude.com/docs/en/security

set -euo pipefail

# HTH Guide Excerpt: begin ir-forensic-collection
# Forensic evidence collector for Claude Code/Cowork incidents.
# Run on the affected user's machine BEFORE cleanupPeriodDays
# triggers automatic transcript deletion.
#
# Usage: ./hth-anthropic-claude-7.11-incident-response.sh [output-dir]
# Output: timestamped archive of Claude session data + summary

OUTPUT_DIR="${1:-./claude-forensics-$(date +%Y%m%d-%H%M%S)}"
CLAUDE_DIR="${HOME}/.claude"

echo "=== Claude Code/Cowork Forensic Collection ==="
echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Hostname:  $(hostname)"
echo "User:      $(whoami)"
echo "Output:    ${OUTPUT_DIR}"
echo ""

mkdir -p "${OUTPUT_DIR}"

# Collect session transcripts (.jsonl files)
if [ -d "${CLAUDE_DIR}" ]; then
  echo "[1/5] Collecting session transcripts..."
  find "${CLAUDE_DIR}" -name "*.jsonl" -type f 2>/dev/null | while read -r f; do
    rel="${f#${CLAUDE_DIR}/}"
    mkdir -p "${OUTPUT_DIR}/transcripts/$(dirname "${rel}")"
    cp "${f}" "${OUTPUT_DIR}/transcripts/${rel}"
  done
  transcript_count=$(find "${OUTPUT_DIR}/transcripts" -name "*.jsonl" 2>/dev/null | wc -l)
  echo "  Collected ${transcript_count} transcript files"
else
  echo "[1/5] No .claude directory found — skipping transcripts"
fi

# Collect settings files (may contain evidence of tampering)
echo "[2/5] Collecting settings and configuration..."
for settings_file in \
  "${CLAUDE_DIR}/settings.json" \
  "${CLAUDE_DIR}/settings.local.json" \
  "${HOME}/.claude.json"; do
  if [ -f "${settings_file}" ]; then
    cp "${settings_file}" "${OUTPUT_DIR}/$(basename "${settings_file}")"
    echo "  Collected: ${settings_file}"
  fi
done

# Collect project-level settings from CWD if present
if [ -d ".claude" ]; then
  echo "[3/5] Collecting project-level .claude/ directory..."
  cp -r .claude "${OUTPUT_DIR}/project-claude/"
else
  echo "[3/5] No project .claude/ directory in CWD"
fi

# Collect MCP server configs
echo "[4/5] Collecting MCP configurations..."
for mcp_file in \
  ".mcp.json" \
  "${CLAUDE_DIR}/mcp.json"; do
  if [ -f "${mcp_file}" ]; then
    cp "${mcp_file}" "${OUTPUT_DIR}/$(basename "${mcp_file}").mcp-config"
    echo "  Collected: ${mcp_file}"
  fi
done

# Collect managed settings (if accessible)
for managed_path in \
  "/Library/Application Support/ClaudeCode/managed-settings.json" \
  "/etc/claude-code/managed-settings.json"; do
  if [ -f "${managed_path}" ]; then
    cp "${managed_path}" "${OUTPUT_DIR}/managed-settings.json"
    echo "  Collected managed settings: ${managed_path}"
  fi
done

# Generate summary
echo "[5/5] Generating collection summary..."
{
  echo "Claude Forensic Collection Summary"
  echo "=================================="
  echo "Date:     $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Hostname: $(hostname)"
  echo "User:     $(whoami)"
  echo "CWD:      $(pwd)"
  echo ""
  echo "Files Collected:"
  find "${OUTPUT_DIR}" -type f | sort | while read -r f; do
    size=$(wc -c < "${f}" | tr -d ' ')
    echo "  ${f} (${size} bytes)"
  done
  echo ""
  echo "Next Steps:"
  echo "  1. Correlate session_id and prompt.id UUIDs with OTel logs in SIEM"
  echo "  2. Review transcript .jsonl files for suspicious tool_use entries"
  echo "  3. Check settings files for unauthorized MCP servers or hooks"
  echo "  4. Preserve this archive per your data retention policy"
} > "${OUTPUT_DIR}/SUMMARY.txt"

cat "${OUTPUT_DIR}/SUMMARY.txt"

echo ""
echo "=== Collection Complete ==="
echo "Archive: ${OUTPUT_DIR}"
echo "To compress: tar -czf ${OUTPUT_DIR}.tar.gz ${OUTPUT_DIR}"
# HTH Guide Excerpt: end ir-forensic-collection
