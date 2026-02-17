#!/usr/bin/env bash
# validate-guides.sh — Pre-push regression tests for HTH guides and pack data
#
# Catches issues that break GitHub Pages Jekyll builds:
#   1. Invalid YAML in _data/packs/*.yml
#   2. Bare code blocks without language identifiers
#   3. Malformed table separators (column count mismatch)
#   4. Tables missing required blank lines (kramdown)
#   5. Invalid frontmatter categories
#   6. Required frontmatter fields
#   7. Required structural sections
#   8. Unescaped Liquid syntax ({{ outside code blocks)
#
# Usage: bash scripts/validate-guides.sh
# Exit code: 0 = all pass, 1 = failures found

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GUIDES_DIR="${REPO_ROOT}/docs/_guides"
DATA_DIR="${REPO_ROOT}/docs/_data/packs"

FAIL_COUNT=0
WARN_COUNT=0

fail() { echo "  FAIL: $1"; ((FAIL_COUNT++)); }
warn() { echo "  WARN: $1"; ((WARN_COUNT++)); }
pass() { echo "  PASS: $1"; }

echo "═══ HTH Guide Validation ═══"
echo ""

# ─── Test 1: YAML validity of pack data files ───────────────────────────────
echo "▸ Test 1: Pack data YAML validity"
if [ -d "${DATA_DIR}" ]; then
  yaml_failures=0
  for f in "${DATA_DIR}"/*.yml; do
    [ -f "$f" ] || continue
    if ! python3 -c "
import yaml, sys
with open('${f}') as fh:
    try:
        yaml.safe_load(fh)
    except yaml.YAMLError as e:
        print(str(e), file=sys.stderr)
        sys.exit(1)
" 2>/tmp/hth-yaml-err; then
      fail "$(basename "$f"): $(cat /tmp/hth-yaml-err)"
      ((yaml_failures++))
    fi
  done
  [ $yaml_failures -eq 0 ] && pass "All $(ls "${DATA_DIR}"/*.yml 2>/dev/null | wc -l) pack YAML files valid"
else
  warn "No pack data directory found at ${DATA_DIR}"
fi
echo ""

# ─── Tests 2-4: Python-based content validation ─────────────────────────────
# Uses Python for performance — bash while-read loops over 116 large files are too slow
content_results=$(GUIDES_DIR="${GUIDES_DIR}" python3 << 'PYEOF'
import os, re, glob

guides_dir = os.environ["GUIDES_DIR"]
files = sorted(glob.glob(os.path.join(guides_dir, "*.md")))

bare_issues = []
sep_issues = []
table_issues = []
liquid_issues = []

for fpath in files:
    with open(fpath, 'r') as f:
        lines = f.readlines()

    fname = os.path.basename(fpath)
    in_code = False
    prev_stripped = ""

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Track code block state
        if stripped.startswith('```'):
            if not in_code:
                in_code = True
                # Test 2: Check if this is a bare opening fence
                if stripped == '```':
                    bare_issues.append(f"{fname}:L{i+1}")
            else:
                in_code = False
            prev_stripped = stripped
            continue

        if in_code:
            prev_stripped = stripped
            continue

        # Test 3: Malformed table separators
        no_spaces = stripped.replace(' ', '')
        if stripped.startswith('|') and all(c in '|-' for c in no_spaces):
            sep_pipes = stripped.count('|')
            # Check if previous line is a header row
            if prev_stripped.startswith('|') and '|' in prev_stripped[1:]:
                prev_no_spaces = prev_stripped.replace(' ', '')
                if not all(c in '|-' for c in prev_no_spaces):
                    header_pipes = prev_stripped.count('|')
                    if sep_pipes > header_pipes + 1:
                        sep_issues.append(f"{fname}:L{i+1}: separator has {sep_pipes} pipes, header has {header_pipes}")

        # Test 4: Tables missing blank lines before
        is_table = stripped.startswith('|') and '|' in stripped[1:]
        if is_table and i > 0:
            prev = lines[i-1].strip()
            prev_is_table = prev.startswith('|') and '|' in prev[1:]
            prev_is_code = prev.startswith('```')
            if prev and not prev_is_table and prev != '---' and not prev_is_code:
                table_issues.append(f"{fname}:L{i+1}: missing blank line before table")

        # Test 8: Unescaped Liquid syntax ({{ or {%) outside code blocks
        if '{{' in stripped and '{% raw %}' not in stripped:
            liquid_issues.append(f"{fname}:L{i+1}: unescaped '{{{{}}' in: {stripped[:60]}")

        prev_stripped = stripped

# Output results as sections separated by markers
print("===BARE===")
print(len(bare_issues))
for issue in bare_issues[:20]:
    print(f"    {issue}")

print("===SEP===")
print(len(sep_issues))
for issue in sep_issues[:20]:
    print(f"    {issue}")

print("===TABLE===")
print(len(table_issues))
for issue in table_issues[:20]:
    print(f"    {issue}")

print("===LIQUID===")
print(len(liquid_issues))
for issue in liquid_issues[:20]:
    print(f"    {issue}")
PYEOF
)

# Parse Test 2 results
echo "▸ Test 2: Code blocks have language identifiers"
bare_section=$(echo "$content_results" | sed -n '/===BARE===/,/===SEP===/p' | head -n -1 | tail -n +2)
bare_count=$(echo "$bare_section" | head -1)
if [ "$bare_count" -gt 0 ]; then
  fail "${bare_count} bare code blocks found:"
  echo "$bare_section" | tail -n +2
  [ "$bare_count" -gt 20 ] && echo "    ... and $((bare_count - 20)) more"
else
  pass "All code blocks have language identifiers"
fi
echo ""

# Parse Test 3 results
echo "▸ Test 3: Table separator column counts match headers"
sep_section=$(echo "$content_results" | sed -n '/===SEP===/,/===TABLE===/p' | head -n -1 | tail -n +2)
sep_count=$(echo "$sep_section" | head -1)
if [ "$sep_count" -gt 0 ]; then
  fail "${sep_count} malformed table separators found:"
  echo "$sep_section" | tail -n +2
else
  pass "All table separators match header column counts"
fi
echo ""

# Parse Test 4 results
echo "▸ Test 4: Tables have required blank lines (kramdown)"
table_section=$(echo "$content_results" | sed -n '/===TABLE===/,/===LIQUID===/p' | head -n -1 | tail -n +2)
table_count=$(echo "$table_section" | head -1)
if [ "$table_count" -gt 0 ]; then
  fail "${table_count} tables missing blank lines:"
  echo "$table_section" | tail -n +2
else
  pass "All tables have required blank lines"
fi
echo ""

# Parse Test 8 results
echo "▸ Test 8: No unescaped Liquid syntax outside code blocks"
liquid_section=$(echo "$content_results" | sed -n '/===LIQUID===/,$p' | tail -n +2)
liquid_count=$(echo "$liquid_section" | head -1)
if [ "$liquid_count" -gt 0 ]; then
  fail "${liquid_count} unescaped Liquid expressions found:"
  echo "$liquid_section" | tail -n +2
else
  pass "No unescaped Liquid syntax found"
fi
echo ""

# ─── Tests 5-7: Python-based frontmatter and structure validation ────────────
meta_results=$(GUIDES_DIR="${GUIDES_DIR}" python3 << 'PYEOF'
import os, re, glob

guides_dir = os.environ["GUIDES_DIR"]
files = sorted(glob.glob(os.path.join(guides_dir, "*.md")))

VALID_CATS = {"Identity", "Security", "DevOps", "Data", "Productivity", "HR/Finance", "Marketing", "IaC", "IT Operations"}
REQUIRED_FIELDS = ["layout", "vendor", "slug", "category", "description", "version", "maturity", "last_updated"]
REQUIRED_SECTIONS = ["Overview", "Intended Audience", "How to Use This Guide", "Scope", "Changelog"]

cat_issues = []
fm_issues = []
struct_issues = []

for fpath in files:
    with open(fpath, 'r') as f:
        content = f.read()
        lines = content.split('\n')

    fname = os.path.basename(fpath)

    # Extract frontmatter (between first and second ---)
    fm_match = re.match(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
    fm_text = fm_match.group(1) if fm_match else ""
    fm_fields = {}
    for line in fm_text.split('\n'):
        m = re.match(r'^(\w[\w_]*):\s*(.*)', line)
        if m:
            fm_fields[m.group(1)] = m.group(2).strip().strip('"').strip("'")

    # Test 5: Valid categories
    cat_val = fm_fields.get("category", "")
    if cat_val and cat_val not in VALID_CATS:
        cat_issues.append(f"{fname}: invalid category '{cat_val}'")

    # Test 6: Required frontmatter fields
    for field in REQUIRED_FIELDS:
        if field not in fm_fields:
            fm_issues.append(f"{fname}: missing frontmatter field '{field}'")

    # Test 7: Required structural sections
    for section in REQUIRED_SECTIONS:
        pattern = r'^#{{2,3}}\s+{}'.format(re.escape(section))
        if not re.search(pattern, content, re.MULTILINE):
            struct_issues.append(f"{fname}: missing section '{section}'")

print("===CAT===")
print(len(cat_issues))
for issue in cat_issues:
    print(f"    {issue}")

print("===FM===")
print(len(fm_issues))
for issue in fm_issues[:40]:
    print(f"    {issue}")

print("===STRUCT===")
print(len(struct_issues))
for issue in struct_issues[:40]:
    print(f"    {issue}")
PYEOF
)

# Parse Test 5 results
echo "▸ Test 5: Frontmatter categories are valid"
cat_section=$(echo "$meta_results" | sed -n '/===CAT===/,/===FM===/p' | head -n -1 | tail -n +2)
cat_count=$(echo "$cat_section" | head -1)
if [ "$cat_count" -gt 0 ]; then
  fail "${cat_count} invalid categories found:"
  echo "$cat_section" | tail -n +2
else
  pass "All categories valid across $(ls "${GUIDES_DIR}"/*.md | wc -l) guides"
fi
echo ""

# Parse Test 6 results
echo "▸ Test 6: Required frontmatter fields present"
fm_section=$(echo "$meta_results" | sed -n '/===FM===/,/===STRUCT===/p' | head -n -1 | tail -n +2)
fm_count=$(echo "$fm_section" | head -1)
if [ "$fm_count" -gt 0 ]; then
  fail "${fm_count} missing frontmatter fields:"
  echo "$fm_section" | tail -n +2
else
  pass "All required frontmatter fields present"
fi
echo ""

# Parse Test 7 results
echo "▸ Test 7: Required structural sections present"
struct_section=$(echo "$meta_results" | sed -n '/===STRUCT===/,$p' | tail -n +2)
struct_count=$(echo "$struct_section" | head -1)
if [ "$struct_count" -gt 0 ]; then
  fail "${struct_count} missing structural sections:"
  echo "$struct_section" | tail -n +2
else
  pass "All required structural sections present"
fi
echo ""

# ─── Summary ─────────────────────────────────────────────────────────────────
echo "═══════════════════════════════"
if [ $FAIL_COUNT -eq 0 ]; then
  echo "✅ ALL TESTS PASSED (${WARN_COUNT} warnings)"
  exit 0
else
  echo "❌ ${FAIL_COUNT} FAILURES, ${WARN_COUNT} warnings"
  exit 1
fi
