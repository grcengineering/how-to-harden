#!/usr/bin/env bash
# HTH Anthropic Claude Control 7.7: Defend Against Prompt Injection and Rules File Attacks
# Profile: L2 | NIST: SI-10, SI-7 | SOC 2: CC6.1, CC7.2
# https://howtoharden.com/guides/anthropic-claude/#77-defend-against-prompt-injection-and-rules-file-attacks
#
# Scans CLAUDE.md, AGENTS.md, and .claude/ directories for suspicious
# prompt injection patterns. Intended as a pre-commit hook or CI check.
# Reference: Pillar Security "Rules File Backdoor" research,
#            Snyk "ToxicSkills" study (Feb 2026)
#
# Usage: ./hth-anthropic-claude-7.07-prompt-injection-defense.sh [directory]
# Exit code 0 = clean, 1 = suspicious patterns found

# HTH Guide Excerpt: begin scan-rules-files
set -euo pipefail

TARGET_DIR="${1:-.}"
FINDINGS=0

echo "=== Claude Code Rules File Security Scanner ==="
echo "Scanning: ${TARGET_DIR}"
echo ""

# Patterns commonly found in prompt injection attacks against AI coding agents.
# Sources: Pillar Security "Rules File Backdoor" (2025), Snyk ToxicSkills (2026),
# Lasso Security indirect prompt injection research (2026).
SUSPICIOUS_PATTERNS=(
  # Data exfiltration via network commands
  'curl\s+.*\$'
  'wget\s+.*\$'
  'fetch\(.*\$'
  'nc\s+-'
  # Encoded payloads hiding instructions
  'base64\s+--decode'
  'eval\s*\('
  'exec\s*\('
  # Invisible Unicode characters used to hide instructions
  '\xe2\x80\x8b'   # zero-width space
  '\xe2\x80\x8c'   # zero-width non-joiner
  '\xe2\x80\x8d'   # zero-width joiner
  '\xef\xbb\xbf'   # BOM in middle of file
  # Instruction override attempts
  'ignore\s+(all\s+)?previous\s+instructions'
  'disregard\s+(all\s+)?prior'
  'override\s+system\s+prompt'
  'you\s+are\s+now\s+in\s+.*mode'
  'new\s+instructions:'
  'IMPORTANT:\s*override'
  # Exfiltration via MCP or tool abuse
  'mcp.*install.*--force'
  'plugin.*install.*--trust'
  # Requests to disable safety
  'dangerously-skip-permissions'
  'bypass.*permission'
  'disable.*safety'
  'allow.*all.*commands'
)

# Files to scan: CLAUDE.md, AGENTS.md, skills, hooks, and plugin configs
SCAN_FILES=()
while IFS= read -r -d '' file; do
  SCAN_FILES+=("$file")
done < <(find "$TARGET_DIR" \
  \( -name "CLAUDE.md" -o -name "AGENTS.md" -o -name "GEMINI.md" \
     -o -name "COPILOT.md" -o -name "*.skill.md" -o -name "SKILL.md" \
     -o -path "*/.claude/settings.json" \
     -o -path "*/.claude/settings.local.json" \
     -o -path "*/.claude/agents/*.md" \
     -o -path "*/.claude/commands/*.md" \) \
  -not -path "*/node_modules/*" \
  -not -path "*/.git/*" \
  -print0 2>/dev/null)

if [ ${#SCAN_FILES[@]} -eq 0 ]; then
  echo "No rules files found to scan."
  exit 0
fi

echo "Found ${#SCAN_FILES[@]} rules file(s) to scan."
echo ""

for file in "${SCAN_FILES[@]}"; do
  echo "--- Scanning: ${file} ---"
  for pattern in "${SUSPICIOUS_PATTERNS[@]}"; do
    matches=$(grep -cEi "$pattern" "$file" 2>/dev/null || true)
    if [ "$matches" -gt 0 ]; then
      echo "  [ALERT] Pattern matched ($matches occurrences): $pattern"
      grep -nEi "$pattern" "$file" 2>/dev/null | head -3 | while read -r line; do
        echo "    $line"
      done
      FINDINGS=$((FINDINGS + matches))
    fi
  done
done

echo ""
echo "=== Scan Complete ==="
echo "Total suspicious patterns found: ${FINDINGS}"

if [ "$FINDINGS" -gt 0 ]; then
  echo ""
  echo "ACTION REQUIRED: Review flagged patterns before trusting this repository."
  echo "Not all findings are malicious — review context carefully."
  echo "See: howtoharden.com/guides/anthropic-claude/#77"
  exit 1
fi

echo "No suspicious patterns detected."
exit 0
# HTH Guide Excerpt: end scan-rules-files
