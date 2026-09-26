#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cursor-5.1
#   guide:   https://howtoharden.com/guides/cursor/#51-disable-auto-run-mode
#   profile: L1
#   mode:    read-only
#   requires: jq
# =============================================================================
# HTH Cursor Control 5.1: Disable Auto-Run Mode
# Profile Level: L1 (Crawl) | NIST 800-53: CM-7, AC-6
# Source: https://howtoharden.com/guides/cursor/#51-disable-auto-run-mode
#
# WHAT CAN AND CANNOT BE READ FROM DISK.
# The Run Mode itself (Auto-review / Allowlist / Run Everything) is chosen in
# Settings > Agents > Approvals & Execution, or imposed from the Enterprise
# dashboard's Auto Run Configuration. Cursor documents no settings.json key for
# it (https://cursor.com/docs/agent/security/run-modes), so no file on disk
# proves "Run Everything is off" — check that in the app or the dashboard.
#
# What IS on disk, and documented, is what each mode runs WITHOUT asking:
#   ~/.cursor/permissions.json and <workspace>/.cursor/permissions.json
#   terminalAllowlist  string[]  commands that run without approval
#   autoRun            object    allow_instructions / block_instructions that
#                                steer the Auto-review classifier
# (https://cursor.com/docs/enterprise/deployment-patterns). Both files are
# concatenated; a team-dashboard setting replaces them.
#
# Findings: a terminalAllowlist entry that is empty, `*`, or starts with a shell,
# an interpreter, or a network/remote tool — any of those turns the allowlist
# into arbitrary execution. autoRun.allow_instructions are printed for REVIEW
# (they lean the classifier toward running calls) but do not fail the pack.
#
# Exit codes: 0 pass | 1 finding | 2 precondition
# =============================================================================

set -uo pipefail

command -v jq >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

# HTH Guide Excerpt: begin cli-audit-terminal-allowlist
FINDINGS=0
FILES_SEEN=0
RISKY='^(bash|sh|zsh|fish|dash|ksh|pwsh|powershell|cmd|python[0-9.]*|node|deno|bun|perl|ruby|php|osascript|eval|exec|sudo|su|doas|curl|wget|nc|ncat|netcat|ssh|scp|rsync|env|xargs|find)( |$)'
for PERM_FILE in "${HOME}/.cursor/permissions.json" ".cursor/permissions.json"; do
  [ -f "${PERM_FILE}" ] || continue
  FILES_SEEN=$((FILES_SEEN + 1))
  if ! jq -e . "${PERM_FILE}" >/dev/null 2>&1; then
    echo "ERROR: ${PERM_FILE} is not valid JSON — Cursor will not apply it as written"
    exit 2
  fi
  echo "=== ${PERM_FILE} ==="
  while IFS= read -r CMD; do
    TRIMMED="$(printf '%s' "${CMD}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    if [ -z "${TRIMMED}" ] || [ "${TRIMMED}" = "*" ]; then
      echo "  FINDING: terminalAllowlist entry '${CMD}' matches any command"
      FINDINGS=$((FINDINGS + 1))
    elif printf '%s\n' "${TRIMMED}" | grep -Eq "${RISKY}"; then
      echo "  FINDING: terminalAllowlist entry '${TRIMMED}' starts with a shell, interpreter, or network tool"
      FINDINGS=$((FINDINGS + 1))
    else
      echo "  ok:      terminalAllowlist '${TRIMMED}'"
    fi
  done < <(jq -r '(.terminalAllowlist // [])[]' "${PERM_FILE}")
  ALLOW_N=$(jq '(.autoRun.allow_instructions // []) | length' "${PERM_FILE}")
  BLOCK_N=$(jq '(.autoRun.block_instructions // []) | length' "${PERM_FILE}")
  echo "  autoRun: ${ALLOW_N} allow_instruction(s), ${BLOCK_N} block_instruction(s)"
  if [ "${ALLOW_N}" -gt 0 ]; then
    jq -r '.autoRun.allow_instructions[] | "  REVIEW:  allow_instruction: \(.)"' "${PERM_FILE}"
  fi
done

[ "${FILES_SEEN}" -gt 0 ] || echo "No permissions.json found — the editor-managed allowlist applies; review it in Settings > Agents > Approvals & Execution"
echo "Run Mode itself is not stored in a documented file: confirm it is not 'Run Everything' in Settings > Agents > Approvals & Execution (or in the team dashboard)."
if [ "${FINDINGS}" -gt 0 ]; then
  echo "${FINDINGS} finding(s)"
  exit 1
fi
echo "PASS: no broad terminal allowlist entries"
exit 0
# HTH Guide Excerpt: end cli-audit-terminal-allowlist
