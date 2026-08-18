#!/usr/bin/env bash
# validate-packs.sh — Corpus-integrity validation for HTH Code Packs (Tier 0)
#
# The companion to validate-guides.sh. That script asks "does the guide render?";
# this one asks "is the pack corpus structurally sound?" — the silent-failure
# classes that nothing in this repo looked for until now:
#
#    1. (section,type) collisions      — sync drops a file with NO warning
#    2. Control-YAML schema conformance + guide_url anchor resolution
#    3. Filename <-> id/section parity
#    4. Sigma rule id (UUID) uniqueness
#    5. Excerpt marker hygiene         — balance, symmetry, uniqueness, charset
#    6. Shebang present on every .sh
#    7. bash -n syntax (honors the HTH Pack Directive allowlist)
#    8. Extension <-> pack-type table (AGENTS.md)
#    9. Generated pack YAML freshness  — ignoring the volatile `# Generated:` line
#   10. Sync reachability              — every marked pack claimed by the pipeline
#   11. Include <-> yml integrity      — both directions
#   12. Link host-policy parity        — SKIPPED until scripts/link-host-policy.yml exists
#   13. HTH Pack Contract v1 coverage  — WARN while the corpus is being backfilled
#   14. Declared `mode:` vs actual mutation verbs — FAIL on mismatch
#
# Usage: bash scripts/validate-packs.sh
# Exit:  0 = all pass · 1 = failures found · 2 = a check could not run
#
# Exit 2 matters: sync-packs-to-data.sh silently SKIPS its only YAML check when
# python3 is absent and still exits 0. This script refuses to be green when it
# could not actually look.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Git Bash for Windows: native-exe python3 can't open POSIX /c/... paths.
if command -v cygpath &>/dev/null; then
  REPO_ROOT="$(cygpath -m "${REPO_ROOT}")"
fi
export PYTHONUTF8=1
PACKS_DIR="${REPO_ROOT}/packs"
DATA_DIR="${REPO_ROOT}/docs/_data/packs"
GUIDES_DIR="${REPO_ROOT}/docs/_guides"

FAIL_COUNT=0
WARN_COUNT=0

# Plain assignment, not ((x++)): under `set -e` the arithmetic form returns 1
# when incrementing from 0 and can abort the script.
fail() { echo "  FAIL: $1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
warn() { echo "  WARN: $1"; WARN_COUNT=$((WARN_COUNT + 1)); }
pass() { echo "  PASS: $1"; }
skip() { echo "  SKIP: $1"; }

die_cannot_run() { echo ""; echo "❌ CANNOT RUN: $1"; exit 2; }

echo "═══ HTH Pack Validation ═══"
echo ""

# ─── Preflight: refuse to be green if we cannot actually check ──────────────
command -v python3 &>/dev/null || die_cannot_run "python3 not found (required for checks 1-5, 8, 10-14)"
python3 -c "import yaml" 2>/dev/null || die_cannot_run "python3 module 'yaml' not found — pip install pyyaml"
[ -d "${PACKS_DIR}" ] || die_cannot_run "packs directory not found at ${PACKS_DIR}"

# ─── Checks 1-5, 8, 10, 11, 13, 14: Python corpus sweep ─────────────────────
# One pass over ~1,100 files; bash loops at this scale are unusably slow.
results=$(PACKS_DIR="${PACKS_DIR}" DATA_DIR="${DATA_DIR}" GUIDES_DIR="${GUIDES_DIR}" python3 << 'PYEOF'
import os, re, glob, json, sys
from collections import defaultdict

packs_dir  = os.environ["PACKS_DIR"]
data_dir   = os.environ["DATA_DIR"]
guides_dir = os.environ["GUIDES_DIR"]
import yaml

# Structural files that are legitimately not numbered control packs.
STRUCTURAL = {"README.md", "variables.tf", "providers.tf", "outputs.tf",
              "terraform.tfvars.example", "common.sh"}

# AGENTS.md pack-type table.
TYPE_EXT = {
    "terraform": {".tf"},
    "api":       {".sh"},
    "cli":       {".sh", ".yml"},
    "sdk":       {".py", ".ps1", ".js", ".go", ".groovy", ".rb"},
    "db":        {".sql", ".kql", ".dax"},
    "siem":      {".spl", ".kql"},
    "sigma":     {".yml"},
    "config":    {".jsonc", ".yml", ".sh"},
}
MUTATION_RE = re.compile(r"-X\s*(POST|PUT|PATCH|DELETE)\b")
BEGIN_RE = re.compile(r"HTH Guide Excerpt:\s*begin\s+(\S+)\s*$")
END_RE   = re.compile(r"HTH Guide Excerpt:\s*end\s+(\S+)\s*$")
CONTRACT_RE = re.compile(r"HTH Pack Contract:\s*v(\d+)")
DIRECTIVE_RE = re.compile(r"HTH Pack Directive:\s*doc-snippet\s*(.*)$")
SEC_RE = re.compile(r"^hth-[a-z0-9-]+-(\d+\.\d+)-")

def normalize(sec):
    """1.01 -> 1.1 ; 1.10 -> 1.10 (mirrors sync-packs-to-data.sh normalize_section)."""
    a, b = sec.split(".")
    return f"{int(a)}.{int(b)}"

def detect_type(relpath):
    parts = relpath.split(os.sep)
    if "sigma" in parts:   return "sigma"
    for t in ("terraform", "api", "cli", "sdk", "db", "config", "siem", "controls", "scripts"):
        if t in parts:     return t
    return "other"

collisions, schema_bad, parity_bad, sigma_dupes = [], [], [], []
marker_bad, ext_bad, unreachable, contract_missing, mode_bad = [], [], [], [], []
anchor_bad, migration = [], []

by_key = defaultdict(list)          # (vendor, type, normsection) -> files
sigma_ids = defaultdict(list)
contract_ok = 0
pack_total = 0
directive_files = []

all_files = [p for p in glob.glob(os.path.join(packs_dir, "**", "*"), recursive=True)
             if os.path.isfile(p)]

for path in all_files:
    rel = os.path.relpath(path, packs_dir)
    base = os.path.basename(path)
    parts = rel.split(os.sep)
    if len(parts) < 2:               # packs/README.md, packs/schema/*
        continue
    vendor = parts[0]
    if vendor == "schema":
        continue
    ptype = detect_type(rel)
    ext = os.path.splitext(base)[1]

    try:
        text = open(path, encoding="utf-8").read()
    except (UnicodeDecodeError, OSError):
        continue
    lines = text.splitlines()

    # ── Check 5: marker hygiene ──
    begins = [BEGIN_RE.search(l).group(1) for l in lines if BEGIN_RE.search(l)]
    ends   = [END_RE.search(l).group(1)   for l in lines if END_RE.search(l)]
    if begins or ends:
        if len(begins) != len(ends):
            marker_bad.append(f"{rel}: {len(begins)} begin / {len(ends)} end (unbalanced)")
        elif set(begins) != set(ends):
            marker_bad.append(f"{rel}: begin/end region names differ")
        elif len(set(begins)) != len(begins):
            marker_bad.append(f"{rel}: duplicate region name within file")
        for r in begins:
            if not re.fullmatch(r"[a-z0-9-]+", r):
                marker_bad.append(f"{rel}: region '{r}' has non [a-z0-9-] chars")

    # ── controls/*.yaml — deprecated format, but still anchor-checked ──
    if ptype == "controls":
        migration.append(rel)
        try:
            doc = yaml.safe_load(text)
        except yaml.YAMLError as e:
            schema_bad.append(f"{rel}: unparseable YAML ({str(e)[:60]})")
            continue
        if not isinstance(doc, dict):
            continue
        # Check 2: conformance against the repo's own control.schema.json
        schema_path = os.path.join(packs_dir, "schema", "control.schema.json")
        if os.path.exists(schema_path):
            schema = json.load(open(schema_path, encoding="utf-8"))
            def check_level(obj, spec, where):
                props = spec.get("properties", {})
                if spec.get("additionalProperties") is False:
                    for k in obj:
                        if k not in props:
                            schema_bad.append(f"{rel}: undefined key '{k}' in {where}")
                for k in spec.get("required", []):
                    if k not in obj:
                        schema_bad.append(f"{rel}: missing required '{k}' in {where}")
                for k, v in obj.items():
                    sub = props.get(k)
                    if isinstance(sub, dict) and isinstance(v, dict) and "properties" in sub:
                        check_level(v, sub, f"{where}.{k}")
            check_level(doc, schema, "root")
        # Check 3: filename <-> id/section parity
        m = SEC_RE.match(base)
        if m and "section" in doc:
            if normalize(m.group(1)) != normalize(str(doc["section"])):
                parity_bad.append(f"{rel}: filename {m.group(1)} != section {doc['section']}")
        if "id" in doc and "section" in doc:
            if not str(doc["id"]).endswith(str(doc["section"])):
                parity_bad.append(f"{rel}: id '{doc['id']}' does not end with section '{doc['section']}'")
        # guide_url anchor must resolve to a real heading
        gu = doc.get("guide_url", "")
        if "#" in str(gu):
            slug = str(gu).rstrip("/").split("/guides/")[-1].split("/")[0] if "/guides/" in str(gu) else None
            anchor = str(gu).split("#", 1)[1]
            gpath = os.path.join(guides_dir, f"{slug}.md") if slug else None
            if gpath and os.path.exists(gpath):
                gtext = open(gpath, encoding="utf-8").read()
                heads = set()
                for h in re.findall(r"^#{2,4}\s+(.+)$", gtext, re.M):
                    s = re.sub(r"[^a-z0-9 -]", "", h.lower()).replace(" ", "-")
                    heads.add(s)
                if anchor not in heads:
                    anchor_bad.append(f"{rel}: #{anchor} NOT FOUND in {slug}.md")
        continue

    if ptype in ("other", "scripts"):
        # Check 10: sync's detect_type() emits "scripts" but process_vendor() has
        # no section_scripts case — anything landing here can never be published.
        if base.startswith("hth-") or begins:
            unreachable.append(f"{rel}: type '{ptype}' is not consumed by sync")
        continue

    if base in STRUCTURAL or base.endswith(".example"):
        continue
    if not base.startswith("hth-"):
        continue

    pack_total += 1

    # ── Check 8: extension <-> type ──
    allowed = TYPE_EXT.get(ptype, set())
    if allowed and ext not in allowed:
        ext_bad.append(f"{rel}: '{ext}' not allowed in {ptype}/ (allowed: {', '.join(sorted(allowed))})")

    # ── Check 1: (section,type) collision ──
    m = SEC_RE.match(base)
    if m:
        key = (vendor, ptype, normalize(m.group(1)))
        by_key[key].append(base)
    else:
        # sync's extract_raw_section() returns empty here, so the file is silently
        # skipped no matter what it contains.
        unreachable.append(f"{rel}: filename has no hth-<vendor>-<N.NN>- section — sync skips it")

    # ── Check 4: sigma id uniqueness ──
    if ptype == "sigma":
        try:
            sdoc = yaml.safe_load(text)
            if isinstance(sdoc, dict) and "id" in sdoc:
                sigma_ids[str(sdoc["id"])].append(rel)
        except yaml.YAMLError:
            pass

    # ── Check 13 / 14: pack contract ──
    head = "\n".join(lines[:15])
    if CONTRACT_RE.search(head):
        contract_ok += 1
        mm = re.search(r"mode:\s*(read-only|mutating)", head)
        if mm:
            declared = mm.group(1)
            body = "\n".join(l for l in lines if not l.strip().startswith(("#", "//", "--")))
            actually_mutates = bool(MUTATION_RE.search(body))
            if declared == "read-only" and actually_mutates:
                mode_bad.append(f"{rel}: declares mode: read-only but contains a mutation verb")
    else:
        contract_missing.append(rel)

    if DIRECTIVE_RE.search(head):
        directive_files.append(rel)

for key, files in sorted(by_key.items()):
    if len(files) > 1 and key[1] != "sigma":
        collisions.append(f"{key[0]}|{key[1]}|{key[2]}: " + ", ".join(sorted(files)))

for sid, files in sorted(sigma_ids.items()):
    if len(files) > 1:
        sigma_dupes.append(f"{sid}: " + ", ".join(sorted(files)))

# ── Check 11: include <-> yml integrity, both directions ──
include_bad = []
inc_re = re.compile(r'pack-code\.html\s+vendor="([^"]+)"\s+section="([^"]+)"')
referenced = defaultdict(set)
for g in sorted(glob.glob(os.path.join(guides_dir, "*.md"))):
    gt = open(g, encoding="utf-8").read()
    for vendor, section in inc_re.findall(gt):
        referenced[vendor].add(section)
        ypath = os.path.join(data_dir, f"{vendor}.yml")
        if not os.path.exists(ypath):
            include_bad.append(f"{os.path.basename(g)}: include vendor '{vendor}' has no yml")
            continue
        yt = open(ypath, encoding="utf-8").read()
        if f'"{section}":' not in yt:
            include_bad.append(f"{os.path.basename(g)}: section '{section}' missing from {vendor}.yml (renders NOTHING)")

orphan_keys = []
for ypath in sorted(glob.glob(os.path.join(data_dir, "*.yml"))):
    vendor = os.path.basename(ypath)[:-4]
    keys = set(re.findall(r'^"([0-9.]+)":', open(ypath, encoding="utf-8").read(), re.M))
    unused = keys - referenced.get(vendor, set())
    if unused:
        orphan_keys.append(f"{vendor}: {len(unused)} yml section(s) referenced by no include: {', '.join(sorted(unused)[:6])}")

def emit(name, items):
    print(f"==={name}===")
    print(len(items))
    for i in items[:25]:
        print(f"    {i}")

emit("COLLISION", collisions)
emit("SCHEMA", schema_bad)
emit("PARITY", parity_bad)
emit("ANCHOR", anchor_bad)
emit("SIGMA", sigma_dupes)
emit("MARKER", marker_bad)
emit("EXT", ext_bad)
emit("UNREACHABLE", unreachable)
emit("INCLUDE", include_bad)
emit("ORPHAN", orphan_keys)
emit("MODE", mode_bad)
emit("CONTRACT", contract_missing)
emit("MIGRATION", migration)
print("===STATS===")
print(f"{pack_total}|{contract_ok}|{len(directive_files)}")
PYEOF
) || die_cannot_run "python corpus sweep failed"

section_of() {
  echo "$results" | sed -n "/===$1===/,/^===/p" | sed '$d' | tail -n +2
}
count_of() { section_of "$1" | head -1; }
body_of()  { section_of "$1" | tail -n +2; }

report() { # report <SECTION> <label> <fail|warn>
  local sec="$1" label="$2" mode="$3" n
  n=$(count_of "$sec")
  if [ "${n:-0}" -gt 0 ]; then
    if [ "$mode" = "warn" ]; then warn "${n} ${label}:"; else fail "${n} ${label}:"; fi
    body_of "$sec"
  else
    pass "${label}: none"
  fi
}

echo "▸ Check 1: (section,type) collisions — sync drops one file, silently"
report COLLISION "(section,type) collisions" fail
echo ""

echo "▸ Check 2: Control YAML schema conformance"
# WARN, not FAIL: this format is DEPRECATED — OCEAN's schema is canonical, and the
# migration (not an in-place fix) is the remedy. Failing here would pin the gate
# permanently red on files we have already decided to retire.
report SCHEMA "control YAML schema violations (deprecated format — migrate, do not patch)" warn
mig=$(count_of MIGRATION)
[ "${mig:-0}" -gt 0 ] && warn "MIGRATION-REQUIRED: ${mig} control YAMLs use HTH's deprecated format (OCEAN's schema is canonical)"
echo ""

echo "▸ Check 2b: guide_url anchors resolve"
report ANCHOR "guide_url anchors unresolved" fail
echo ""

echo "▸ Check 3: filename <-> id/section parity"
report PARITY "filename/id parity violations" fail
echo ""

echo "▸ Check 4: Sigma rule id uniqueness"
report SIGMA "duplicate sigma ids" fail
echo ""

echo "▸ Check 5: Excerpt marker hygiene"
report MARKER "marker hygiene violations" fail
echo ""

# ─── Check 6: shebang on every .sh ──────────────────────────────────────────
echo "▸ Check 6: Shebang present on every .sh"
missing_shebang=0
while IFS= read -r f; do
  [ -f "$f" ] || continue
  if [ "$(head -c 2 "$f")" != "#!" ]; then
    fail "${f#"${PACKS_DIR}"/}: no shebang"
    missing_shebang=$((missing_shebang + 1))
  fi
done < <(find "${PACKS_DIR}" -name '*.sh' -type f)
[ "$missing_shebang" -eq 0 ] && pass "shebang: all .sh files have one"
echo ""

# ─── Check 7: bash -n, honoring the doc-snippet directive ───────────────────
echo "▸ Check 7: bash -n syntax (HTH Pack Directive allowlist)"
syntax_fail=0
undirected=0
while IFS= read -r f; do
  [ -f "$f" ] || continue
  if ! bash -n "$f" 2>/dev/null; then
    rel="${f#"${PACKS_DIR}"/}"
    if head -10 "$f" | grep -q 'HTH Pack Directive:[[:space:]]*doc-snippet'; then
      reason="$(head -10 "$f" | grep 'HTH Pack Directive:' | sed 's/.*doc-snippet[[:space:]]*//')"
      if [ -z "${reason// /}" ]; then
        fail "${rel}: HTH Pack Directive present but carries no reason"
        syntax_fail=$((syntax_fail + 1))
      elif ! grep -qE '<[a-z-]+>' "$f"; then
        warn "${rel}: directive reason given but no <placeholder> token found — verify it is not a real bug"
      fi
    else
      fail "${rel}: fails bash -n and carries no HTH Pack Directive"
      syntax_fail=$((syntax_fail + 1))
      undirected=$((undirected + 1))
    fi
  fi
done < <(find "${PACKS_DIR}" -name '*.sh' -type f)
[ "$syntax_fail" -eq 0 ] && pass "bash -n: clean (or directive-covered)"
echo ""

echo "▸ Check 8: Extension <-> pack-type table (AGENTS.md)"
report EXT "files violate the type table" fail
echo ""

# ─── Check 9: generated YAML freshness (ignore the volatile timestamp) ──────
echo "▸ Check 9: Generated pack YAML freshness"
if [ ! -d "${DATA_DIR}" ]; then
  warn "no ${DATA_DIR} — skipping freshness check"
else
  tmp_out="$(mktemp -d)"
  # Snapshot the CURRENT yml files and restore from that snapshot afterwards.
  # Never `git checkout --` here: sync rewrites in place, and restoring from git
  # would silently destroy a contributor's uncommitted work in docs/_data/packs.
  mkdir -p "${tmp_out}/before"
  cp -p "${DATA_DIR}"/*.yml "${tmp_out}/before/" 2>/dev/null || true
  restore_yml() {
    cp -p "${tmp_out}/before"/*.yml "${DATA_DIR}/" 2>/dev/null || true
    # A vendor with no prior yml (newly added pack dir) leaves a fresh file behind;
    # remove only those, so the tree ends exactly as we found it.
    for produced in "${DATA_DIR}"/*.yml; do
      [ -f "$produced" ] || continue
      [ -f "${tmp_out}/before/$(basename "$produced")" ] || rm -f "$produced"
    done
  }
  trap 'restore_yml; rm -rf "${tmp_out}"' EXIT

  if bash "${REPO_ROOT}/scripts/sync-packs-to-data.sh" >"${tmp_out}/sync.log" 2>&1; then
    if grep -q '✗' "${tmp_out}/sync.log"; then
      # sync exits 0 even when a vendor fails validation — that is why we grep.
      fail "sync reported ✗ for at least one vendor:"
      grep '✗' "${tmp_out}/sync.log" | sed 's/^/    /'
    fi
    stale=0
    for produced in "${DATA_DIR}"/*.yml; do
      [ -f "$produced" ] || continue
      base="$(basename "$produced")"
      prior="${tmp_out}/before/${base}"
      if [ ! -f "$prior" ]; then
        fail "${base}: generated but absent from docs/_data/packs — run sync and commit it"
        stale=$((stale + 1))
        continue
      fi
      # Compare ignoring the volatile `# Generated: <ISO8601>` line only.
      if ! diff -q <(grep -v '^# Generated:' "$prior") <(grep -v '^# Generated:' "$produced") >/dev/null; then
        fail "${base}: regenerates differently — pack source and yml are out of sync"
        stale=$((stale + 1))
      fi
    done
    [ "$stale" -eq 0 ] && pass "generated YAML is fresh (ignoring the # Generated: timestamp)"
  else
    fail "sync-packs-to-data.sh returned non-zero"
  fi
fi
echo ""

echo "▸ Check 10: Sync reachability — every marked pack claimed by the pipeline"
report UNREACHABLE "marked pack files unreachable by sync" fail
echo ""

echo "▸ Check 11: Include <-> yml integrity"
report INCLUDE "dead includes (render NOTHING, silently)" fail
report ORPHAN "vendors with yml sections no include references" warn
echo ""

echo "▸ Check 12: Link host-policy parity"
if [ -f "${REPO_ROOT}/scripts/link-host-policy.yml" ]; then
  pass "host policy present (parity check runs in validate-links.sh)"
else
  skip "scripts/link-host-policy.yml not present yet (ships with validate-links.sh)"
fi
echo ""

echo "▸ Check 13: HTH Pack Contract v1 coverage"
stats=$(echo "$results" | sed -n '/===STATS===/,$p' | tail -n +2 | head -1)
pack_total="${stats%%|*}"; rest="${stats#*|}"
contract_ok="${rest%%|*}"; directive_n="${rest##*|}"
missing_n=$(count_of CONTRACT)
if [ "${missing_n:-0}" -gt 0 ]; then
  warn "${contract_ok}/${pack_total} packs carry a v1 contract — ${missing_n} missing (backfill lands in PR4; FAIL once complete)"
else
  pass "all ${pack_total} packs carry an HTH Pack Contract v1"
fi
echo ""

echo "▸ Check 14: Declared mode vs actual mutation verbs"
report MODE "packs whose declared mode contradicts their code" fail
echo ""

echo "───────────────────────────────"
echo "doc-snippet directives in corpus: ${directive_n:-0}"
echo "═══════════════════════════════"
if [ $FAIL_COUNT -eq 0 ]; then
  echo "✅ ALL TESTS PASSED (${WARN_COUNT} warnings)"
  exit 0
else
  echo "❌ ${FAIL_COUNT} FAILURES, ${WARN_COUNT} warnings"
  exit 1
fi
