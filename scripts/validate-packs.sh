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
#   15. Pack substance             — a file that is 100% comments is prose, not code
#   16. Automation-surface coverage — pack-type monoculture (WARN) + coverage report
#
# Usage: bash scripts/validate-packs.sh [vendor-slug]
#        A vendor slug scopes the check-16 coverage report to that vendor.
# Exit:  0 = all pass · 1 = failures found · 2 = a check could not run
#
# Exit 2 matters: sync-packs-to-data.sh silently SKIPS its only YAML check when
# python3 is absent and still exits 0. This script refuses to be green when it
# could not actually look.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# ─── --touched: gate new work without pinning main red on old debt ──────────
# The corpus carries pre-existing failures (40 extension-table violations, 4
# collisions, unresolved anchors). A blanket required check would block every PR
# on debt it did not create, so the CI gate runs this mode: full sweep, but only
# findings in files the branch actually touched decide the exit code. Everything
# else still prints, so the debt stays visible instead of silently growing.
#
# Implemented as a self re-exec so the 17 checks below need no filtering logic.
if [ "${1:-}" = "--touched" ]; then
  base=""
  for ref in "${GITHUB_BASE_REF:+origin/$GITHUB_BASE_REF}" origin/main main; do
    [ -n "$ref" ] || continue
    if git -C "${REPO_ROOT}" rev-parse --verify -q "$ref" >/dev/null; then
      base="$(git -C "${REPO_ROOT}" merge-base HEAD "$ref" 2>/dev/null || true)"
      [ -n "$base" ] && break
    fi
  done
  if [ -z "$base" ]; then
    echo "▸ --touched: no merge base found (shallow clone?) — falling back to full corpus"
    exec bash "$0" --all
  fi
  touched="$(git -C "${REPO_ROOT}" diff --name-only "$base"...HEAD -- packs docs/_guides docs/_data/packs || true)"
  if [ -z "$touched" ]; then
    echo "▸ --touched: this branch changes no packs or guides — nothing to gate."
    exit 0
  fi
  echo "▸ --touched: gating on $(echo "$touched" | wc -l | tr -d ' ') changed file(s)"
  echo ""
  set +e
  report="$(bash "$0" --all 2>&1)"          # bash "$0": the file need not be +x
  raw_exit=$?
  set -e
  echo "$report"
  if [ $raw_exit -eq 2 ]; then exit 2; fi   # a check could not run — never mask that
  # Fail CLOSED on a malformed inner run. Without this, an inner failure that
  # produced no output would yield an empty finding list and a green verdict —
  # the filter would report "no failures in your files" having seen no report at
  # all. A gate that passes when it cannot see is worse than no gate.
  if ! echo "$report" | grep -q "═══════"; then
    echo "❌ CANNOT RUN: inner --all run produced no recognisable report (exit ${raw_exit})"
    exit 2
  fi
  echo ""
  echo "═══ --touched verdict ═══"
  # Split touched guides into body-changed vs frontmatter-only: only the former
  # inherits its vendor's pack findings (see the note in the filter below).
  # Strip frontmatter AND the trailing "## Changelog" section before comparing.
  # Neither can break a pack: frontmatter is metadata, and the changelog is
  # bookkeeping ABOUT the guide, not content packs resolve against. A guide's
  # control bodies, headings, and include tags are what a pack finding can
  # legitimately be attributed to. Without the changelog cut, a corpus-wide
  # bookkeeping sweep (a maturity-vocabulary rename, a date restamp) re-acquires
  # every vendor as an attribution key and the branch inherits the entire
  # corpus's pre-existing pack debt — the exact false-attribution this filter
  # exists to prevent, seen twice on 2026-08-20.
  strip_bookkeeping() {
    awk 'BEGIN{n=0}
         /^---[[:space:]]*$/{n++; if(n<=2) next}
         n>=2 && /^## Changelog[[:space:]]*$/{stop=1}
         n>=2 && !stop{print}'
  }
  body_changed=""
  for g in $(echo "$touched" | grep '^docs/_guides/' || true); do
    old_body="$(git -C "${REPO_ROOT}" show "$base:$g" 2>/dev/null | strip_bookkeeping || true)"
    new_body="$(strip_bookkeeping < "${REPO_ROOT}/$g" 2>/dev/null || true)"
    if [ "$old_body" != "$new_body" ]; then
      body_changed="${body_changed}${g}"$'\n'
    fi
  done

  TOUCHED="$touched" BODY_CHANGED="$body_changed" REPORT="$report" python3 << 'PYEOF' || exit 1
import os, re, sys

touched = [p for p in os.environ["TOUCHED"].splitlines() if p.strip()]
# Guides whose content (not just YAML frontmatter) changed on this branch.
BODY_CHANGED_GUIDES = set(
    p for p in os.environ.get("BODY_CHANGED", "").splitlines() if p.strip()
)
# A finding is "yours" when it names a file you changed, or that file's vendor
# directory. Findings are printed either inline on the FAIL line or as indented
# items beneath it, so both forms are matched.
keys = set()
for p in touched:
    parts = p.split('/')
    is_guide = parts[0] == 'docs' and len(parts) > 1 and parts[1] == '_guides'
    # A frontmatter-only guide edit claims NOTHING. Its own path and basename are
    # withheld too, because findings name a guide as the TARGET of a broken
    # anchor ("... NOT FOUND in github.md") — matching on the bare filename is
    # how a metadata sweep inherited another vendor's anchor debt.
    if is_guide and p not in BODY_CHANGED_GUIDES:
        continue
    keys.add(p)
    keys.add(os.path.basename(p))
    if parts[0] == 'packs' and len(parts) > 1:
        keys.add(parts[1] + '/')
    if is_guide:
        # A guide edit inherits its vendor's pack findings, because editing a
        # guide really can break that vendor's packs — a renamed heading moves
        # an anchor a control YAML's guide_url points at, a removed include
        # orphans a pack section.
        #
        # But ONLY when the guide's BODY changed. A frontmatter-only edit (a
        # maturity sweep across every guide, a date restamp) cannot move an
        # anchor, cannot touch an include, cannot rename a control — so
        # attributing the vendor's pre-existing pack debt to it is a false
        # accusation, and a repo-wide metadata edit would inherit the debt of
        # all 71 vendors at once. Measured: one such sweep attributed 43
        # findings across 8 vendors to a branch that changed one line per file.
        keys.add(os.path.splitext(parts[-1])[0] + '/')

mine, in_fail = [], None
for line in os.environ["REPORT"].splitlines():
    m = re.match(r'\s*FAIL: (.*)', line)
    if m:
        in_fail = m.group(1)
        if any(k in line for k in keys):
            mine.append(line.strip())
        continue
    if in_fail and re.match(r'\s{4,}\S', line):
        if any(k in line for k in keys):
            mine.append(f"[{in_fail[:48]}] {line.strip()}")
        continue
    if line.strip() and not line.startswith(' '):
        in_fail = None

if mine:
    print(f"❌ {len(mine)} failure(s) in files this branch touched:")
    for f in mine[:40]:
        print(f"    {f}")
    sys.exit(1)
print("✅ No failures in the files this branch touched.")
print("   (Corpus-wide findings above are pre-existing debt — not introduced here.)")
PYEOF
  exit 0
fi
[ "${1:-}" = "--all" ] && shift || true
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

# ─── Checks 15-16: pack substance and coverage ──────────────────────────────
# These two exist because prose review did not catch either failure mode. A pack
# can satisfy every other check while containing no code at all, and a vendor can
# ship a dozen packs that all automate the same surface while five of its controls
# have none.
coverage=$(PACKS_DIR="${PACKS_DIR}" GUIDES_DIR="${GUIDES_DIR}" \
           ONLY_VENDOR="${1:-}" python3 << 'PYEOF'
import os, re, glob, collections

packs_dir  = os.environ["PACKS_DIR"]
guides_dir = os.environ["GUIDES_DIR"]

COMMENT = {'.tf':'#', '.sh':'#', '.py':'#', '.ps1':'#', '.yml':'#', '.yaml':'#',
           '.sql':'--', '.kql':'//', '.js':'//', '.jsonc':'//', '.spl':'#',
           '.groovy':'//', '.rb':'#', '.hcl':'#', '.graphql':'#', '.dax':'//'}
SKIP_DIRS = ('controls', 'scripts')

empty, mono, uncovered = [], [], []
per_vendor = collections.defaultdict(collections.Counter)

for path in sorted(glob.glob(os.path.join(packs_dir, '**', '*'), recursive=True)):
    if not os.path.isfile(path):
        continue
    base = os.path.basename(path)
    if not base.startswith('hth-'):
        continue
    rel = os.path.relpath(path, packs_dir)
    parts = rel.split(os.sep)
    if len(parts) < 2:
        continue
    vendor = parts[0]
    seg = parts[1:-1]
    ptype = 'sigma' if 'sigma' in seg else (seg[0] if seg else 'other')
    if ptype in SKIP_DIRS:
        continue
    per_vendor[vendor][ptype] += 1

    # Check 15: a pack whose every line is a comment is prose in code markers.
    ext = os.path.splitext(base)[1]
    marker = COMMENT.get(ext)
    if marker:
        try:
            lines = open(path, encoding='utf-8').read().splitlines()
        except (UnicodeDecodeError, OSError):
            continue
        code = [l for l in lines if l.strip() and not l.strip().startswith(marker)]
        if not code:
            empty.append(f"{rel}: {len(lines)} lines, ZERO executable — prose in code markers (AGENTS.md rule 2b)")

# Check 16a: pack-type monoculture. One type across a large pack set means the
# other automation surfaces were never enumerated.
for vendor, types in sorted(per_vendor.items()):
    total = sum(types.values())
    if total >= 5 and len(types) == 1:
        mono.append(f"{vendor}: {total} packs, all '{list(types)[0]}' — other surfaces likely unexamined")

# Check 16b: pack coverage per leveled control. This is a REPORT, not a gate.
# Many SaaS admin settings genuinely have no automation surface, so "no pack" is
# often the honest answer (AGENTS.md). What the number is for: an agent working a
# vendor sees at a glance how much of that guide is still ClickOps-only, and a
# currency pass can diff it against the vendor's Surface Inventory.
only = os.environ.get("ONLY_VENDOR", "").strip()
inc_re = re.compile(r'pack-code\.html')
tot_leveled = tot_packed = 0
for g in sorted(glob.glob(os.path.join(guides_dir, '*.md'))):
    slug = os.path.basename(g)[:-3]
    if only and slug != only:
        continue
    body = re.sub(r'^---\r?\n.*?\r?\n---', '', open(g, encoding='utf-8').read(), flags=re.S)
    missing, leveled = [], 0
    for sec in re.split(r'^### ', body, flags=re.M)[1:]:
        head = sec.split('\n', 1)[0]
        m = re.match(r'(\d+(?:\.\d+)+)\s', head)
        if not m or 'Profile Level' not in sec:
            continue
        leveled += 1
        if not inc_re.search(sec):
            missing.append(m.group(1))
    tot_leveled += leveled
    tot_packed += leveled - len(missing)
    # Only name a vendor when explicitly scoped — corpus-wide this is ~70 lines
    # of noise, and a warning that always fires is a warning nobody reads.
    if only and missing:
        uncovered.append(f"{slug}: {leveled - len(missing)}/{leveled} leveled controls have a pack; "
                         f"no pack for {', '.join(missing)}")
if not only and tot_leveled:
    uncovered.append(f"corpus: {tot_packed}/{tot_leveled} leveled controls have a pack "
                     f"({100*tot_packed//tot_leveled}%) — re-run with a vendor slug to itemise")

def emit(name, items, cap=25):
    print(f"==={name}===")
    print(len(items))
    for i in items[:cap]:
        print(f"    {i}")

emit("EMPTY", empty)
emit("MONO", mono)
emit("UNCOVERED", uncovered, cap=200)
print("===END===")   # sentinel: csection() reads up to the next ===marker===
PYEOF
) || die_cannot_run "coverage sweep failed"

csection() { echo "$coverage" | sed -n "/===$1===/,/^===/p" | sed '$d' | tail -n +2; }
creport() {
  local sec="$1" label="$2" mode="$3" n
  n=$(csection "$sec" | head -1)
  if [ "${n:-0}" -gt 0 ]; then
    case "$mode" in
      warn) warn "${n} ${label}:" ;;
      info) echo "  INFO: ${label}" ;;
      *)    fail "${n} ${label}:" ;;
    esac
    csection "$sec" | tail -n +2
  else
    pass "${label}: none"
  fi
}

echo "▸ Check 15: Packs contain executable code (not prose in code markers)"
creport EMPTY "pack files with ZERO executable content" fail
echo ""

echo "▸ Check 16: Automation-surface coverage"
creport MONO "vendors whose packs are a single-type monoculture" warn
creport UNCOVERED "pack coverage of leveled controls" info
echo ""

# ─── Check 17: CLI-inventory conformance ────────────────────────────────────
# docs/research/cli-inventory.md is a fetch-verified census of which vendors ship
# a first-party CLI. Until now NOTHING read it (grep: zero hits in scripts/,
# Makefile, .github/, .claude/skills/). It recorded Buildkite as GA-Official `bk`
# with admin coverage "Yes" while the Buildkite guide shipped zero cli/ packs —
# the repo owned the answer in writing and the workflow never asked. This check
# is that question, asked automatically, in both directions.
INVENTORY="${REPO_ROOT}/docs/research/cli-inventory.md"
echo "▸ Check 17: CLI-inventory conformance (docs/research/cli-inventory.md)"
if [ ! -f "${INVENTORY}" ]; then
  warn "cli-inventory.md not found — check skipped"
else
  cliconf=$(INVENTORY="${INVENTORY}" PACKS_DIR="${PACKS_DIR}" python3 << 'PYEOF'
import os, re, glob

inv_path  = os.environ["INVENTORY"]
packs_dir = os.environ["PACKS_DIR"]

def slugify(name):
    s = name.lower().replace('(', '').replace(')', '').replace('.', '').replace("'", '')
    return re.sub(r'[^a-z0-9]+', '-', s).strip('-')

# Column order: vendor | status | binary | install | covers-admin-ops | docs
rows = {}
row_re = re.compile(r'^\|\s*\d+\s*\|([^|]*)\|([^|]*)\|([^|]*)\|([^|]*)\|([^|]*)\|')
for line in open(inv_path, encoding='utf-8'):
    m = row_re.match(line)
    if m:
        cells = [c.strip() for c in m.groups()]
        rows[slugify(cells[0])] = cells

def lookup(vendor):
    for cand in (vendor, vendor.replace('-', ''), vendor.split('-')[0]):
        if cand in rows:
            return rows[cand]
    for key, cells in rows.items():
        if key.startswith(vendor) or vendor.startswith(key):
            return cells
    return None

# "None" / "Vendor-Adjacent" / "Deprecated" mean no admin-capable first-party CLI.
NO_CLI = ('none', 'vendor-adjacent', 'deprecated')

expected, fabricated, unlisted = [], [], []
for vdir in sorted(glob.glob(os.path.join(packs_dir, '*'))):
    if not os.path.isdir(vdir):
        continue
    vendor = os.path.basename(vdir)
    if not glob.glob(os.path.join(vdir, '**', 'hth-*'), recursive=True):
        continue                              # no packs at all — nothing to conform
    has_cli = bool(glob.glob(os.path.join(vdir, 'cli', 'hth-*')))
    row = lookup(vendor)
    if row is None:
        if has_cli:
            unlisted.append(f"{vendor}: ships cli/ packs but has NO row in cli-inventory.md — add one")
        continue
    status, admin = row[1], row[4]
    usable = not status.lower().startswith(NO_CLI)
    if has_cli and not usable:
        fabricated.append(f"{vendor}: ships cli/ packs but inventory status is '{status}' "
                          f"— no admin-capable first-party CLI (AGENTS.md pack-type table)")
    if (not has_cli) and usable and admin.lower().startswith('yes'):
        expected.append(f"{vendor}: inventory says '{status}' CLI, admin coverage YES "
                        f"— zero cli/ packs shipped")

def emit(name, items):
    print(f"==={name}===")
    print(len(items))
    for i in items[:40]:
        print(f"    {i}")

emit("FABRICATED", fabricated)
emit("EXPECTED", expected)
emit("UNLISTED", unlisted)
print("===END===")
PYEOF
) || die_cannot_run "cli-inventory cross-check failed"

  csection() { echo "$cliconf" | sed -n "/===$1===/,/^===/p" | sed '$d' | tail -n +2; }
  creport FABRICATED "cli/ packs for a vendor with no admin-capable first-party CLI" fail
  creport EXPECTED   "vendors with a documented admin CLI but no cli/ packs" warn
  creport UNLISTED   "vendors shipping cli/ packs with no cli-inventory row" warn
fi
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
