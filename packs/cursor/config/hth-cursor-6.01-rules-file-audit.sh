#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cursor-6.1
#   guide:   https://howtoharden.com/guides/cursor/#61-audit-cursorrules-for-hidden-payloads
#   profile: L1
#   mode:    read-only
#   requires: grep, find
# =============================================================================
# HTH Cursor Control 6.1: Audit .cursorrules for Hidden Payloads
# Profile Level: L1 (Crawl) | NIST 800-53: SI-3, CM-7
# Source: https://howtoharden.com/guides/cursor/#61-audit-cursorrules-for-hidden-payloads
#
# WHY BYTE PATTERNS AND NOT `grep -P`.
# macOS ships BSD grep, which has no -P. An earlier version of this pack used
# `grep -cP ... 2>/dev/null || echo 0`, so on a Mac the scan never ran and every
# file printed PASS — including files that did contain zero-width characters.
# The scan below matches the UTF-8 byte sequences with LC_ALL=C grep -E, which
# works on BSD and GNU grep alike, and a grep that cannot run stops the pack
# (exit 2) instead of reading as "0 findings".
#
# Characters detected (UTF-8 bytes):
#   U+200B-U+200F  zero-width space/non-joiner/joiner, LRM/RLM   e2 80 8b-8f
#   U+2028-U+202F  line/paragraph separators, bidi embeddings    e2 80 a8-af
#   U+2060         word joiner                                    e2 81 a0
#   U+FEFF         byte-order mark / zero-width no-break space    ef bb bf
#   U+E0000-E007F  Unicode tag characters (invisible ASCII)       f3 a0 80-81 xx
#
# Exit codes: 0 no hidden Unicode | 1 hidden Unicode found | 2 scan could not run
# Suitable as a pre-commit or CI gate (see 6.2).
# =============================================================================

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

HIDDEN_RE=$'\xe2\x80[\x8b-\x8f\xa8-\xaf]|\xe2\x81\xa0|\xef\xbb\xbf|\xf3\xa0[\x80\x81]'
FOUND_HIDDEN=0
for f in "${RULES_FILES[@]}"; do
  HIDDEN=$(LC_ALL=C grep -cE "$HIDDEN_RE" "$f"); RC=$?
  if [ "$RC" -gt 1 ]; then
    echo "  ERROR: hidden-Unicode scan could not run on $f (grep exit $RC)"
    exit 2
  fi
  if [ "$HIDDEN" -gt 0 ]; then
    echo "  FAIL: $f contains $HIDDEN line(s) with hidden Unicode characters"
    echo "    Locate with: hexdump -C '$f'"
    FOUND_HIDDEN=$((FOUND_HIDDEN + 1))
  else
    echo "  PASS: $f — no hidden Unicode detected"
  fi
done

if [ "$FOUND_HIDDEN" -gt 0 ]; then
  echo ""
  echo "ACTION: Review flagged files with a hex editor before trusting"
  echo "  hexdump -C <file> | grep -E '(e2 80 8[b-f]|e2 80 a[8-f]|e2 81 a0|ef bb bf|f3 a0 8[01])'"
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
  MATCHES=$(grep -ciE "$PATTERN" "$f"); RC=$?
  if [ "$RC" -gt 1 ]; then
    echo "  ERROR: content review could not run on $f (grep exit $RC)"
    exit 2
  fi
  if [ "$MATCHES" -gt 0 ]; then
    echo "  WARN: $f has $MATCHES suspicious pattern(s):"
    grep -niE "$PATTERN" "$f" | head -5
  else
    echo "  PASS: $f — no suspicious patterns"
  fi
done

# Non-zero exit when hidden Unicode was found, so CI or a pre-commit hook (6.2)
# can gate on it. Suspicious-pattern matches are WARN-only: they need a human.
[ "$FOUND_HIDDEN" -gt 0 ] && exit 1
exit 0
# HTH Guide Excerpt: end cli-rules-content-review
