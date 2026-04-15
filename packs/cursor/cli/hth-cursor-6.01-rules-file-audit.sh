#!/usr/bin/env bash
# HTH Cursor Control 6.1: Audit .cursorrules for Hidden Payloads
# Profile: L1 | NIST: SI-3, CM-7
# https://howtoharden.com/guides/cursor/#61-audit-cursorrules-for-hidden-payloads

# HTH Guide Excerpt: begin cli-rules-unicode-scan
# Scan .cursorrules and .cursor/rules/ for hidden Unicode characters
# that could carry invisible prompt injection payloads
echo "=== Scanning for hidden Unicode in AI rules files ==="

RULES_FILES=()
[ -f ".cursorrules" ] && RULES_FILES+=(".cursorrules")
if [ -d ".cursor/rules" ]; then
  while IFS= read -r -d '' f; do
    RULES_FILES+=("$f")
  done < <(find .cursor/rules -type f -name "*.mdc" -print0 2>/dev/null)
fi

if [ ${#RULES_FILES[@]} -eq 0 ]; then
  echo "  No rules files found in project (OK)"
  exit 0
fi

FOUND_HIDDEN=0
for f in "${RULES_FILES[@]}"; do
  # Detect zero-width characters, bidirectional markers, and other invisible Unicode
  # U+200B (zero-width space), U+200C/D (zero-width non-joiner/joiner),
  # U+200E/F (LTR/RTL marks), U+2060 (word joiner), U+FEFF (BOM)
  HIDDEN=$(grep -cP '[\x{200B}-\x{200F}\x{2028}-\x{202F}\x{2060}\x{FEFF}]' "$f" 2>/dev/null || echo "0")
  if [ "$HIDDEN" -gt 0 ]; then
    echo "  FAIL: $f contains $HIDDEN line(s) with hidden Unicode characters"
    echo "    View with: cat -v '$f' | grep -n 'M-b'"
    FOUND_HIDDEN=$((FOUND_HIDDEN + 1))
  else
    echo "  PASS: $f — no hidden Unicode detected"
  fi
done

if [ "$FOUND_HIDDEN" -gt 0 ]; then
  echo ""
  echo "ACTION: Review flagged files with a hex editor before trusting"
  echo "  hexdump -C <file> | grep -E '(e2 80 8[b-f]|e2 80 a[a-f]|ef bb bf)'"
fi
# HTH Guide Excerpt: end cli-rules-unicode-scan

# HTH Guide Excerpt: begin cli-rules-content-review
# Review rules files for suspicious instructions
echo "=== Content Review of AI Rules Files ==="

SUSPICIOUS_PATTERNS=(
  'curl\s'
  'wget\s'
  'eval\s'
  'exec\('
  'system\('
  'subprocess'
  'base64'
  'reverse.shell'
  '/dev/tcp'
  'nc\s.*-e'
  '<user_query>'
  '<user_info>'
  'ignore.*previous.*instructions'
  'disregard.*above'
)

PATTERN=$(printf '%s|' "${SUSPICIOUS_PATTERNS[@]}")
PATTERN=${PATTERN%|}

for f in "${RULES_FILES[@]}"; do
  MATCHES=$(grep -ciE "$PATTERN" "$f" 2>/dev/null || echo "0")
  if [ "$MATCHES" -gt 0 ]; then
    echo "  WARN: $f has $MATCHES suspicious pattern(s):"
    grep -niE "$PATTERN" "$f" 2>/dev/null | head -5
  else
    echo "  PASS: $f — no suspicious patterns"
  fi
done
# HTH Guide Excerpt: end cli-rules-content-review
