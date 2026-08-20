---
name: verify-hth
description: Run the How to Harden verification battery — content lint, cheat-sheet parity, zero-fence check, pack include/yml integrity, bookkeeping consistency, pack corpus validation and automation-surface coverage — as a prescriptive pass/fail checklist before committing guide or pack changes. USE WHEN verifying HTH changes, before committing guides or packs, checking cheat sheet parity, or diagnosing why a control/pack isn't rendering. Run this at the end of every create-hth-guide, update-hth-guide, and create-code-pack task.
---

# Verify HTH

Seven checks, each with a command and an explicit pass condition. ALL must pass before commit. Commands run from repo root; on Windows use Git Bash (`bash ...` — the scripts carry cygpath/UTF-8 shims).

## Check 1 — Repo lint suite

```bash
bash scripts/validate-guides.sh
```

**Pass:** output ends `ALL TESTS PASSED`. Covers pack-YAML validity, code-block languages, table separators, table blank lines, unescaped Liquid, valid categories, maturity sets (Test 5b — list form, the six status names, and the rule that a `*-reviewed`/`*-validated` claim rests on a `*-drafted` one), required frontmatter, required structural sections.
**On fail:** the failing test names the file/line. Unescaped Liquid → wrap the literal `{{...}}` in `{% raw %}...{% endraw %}`.

## Check 2 — Zero inline fences in guides

```bash
grep -rcE '^ *```' docs/_guides/*.md | grep -v ':0' || echo CLEAN
```

**Pass:** prints `CLEAN`.
**On fail:** the listed guide has fenced code that belongs in a pack — run create-code-pack, then replace the fence with the include.

## Check 3 — Cheat-sheet parity (parser-exact)

```bash
python3 - "docs/_guides/{slug}.md" << 'EOF'
import re, sys, io
body = re.sub(r'^---\r?\n.*?\r?\n---', '', io.open(sys.argv[1], encoding='utf-8').read(), flags=re.S)
bad = []
for sec in re.split(r'^### ', body, flags=re.M)[1:]:
    head = sec.split('\n', 1)[0]
    m = re.match(r'(\d+(?:\.\d+)+)\s', head)
    if not m or 'Profile Level' not in sec: continue
    if not re.search(r'^#### Description\s*$', sec, re.M): bad.append(m.group(1) + ' no-desc')
    if not re.search(r'^#### Rationale\s*$', sec, re.M) and 'Why This Matters' not in sec: bad.append(m.group(1) + ' no-rationale')
print('PARITY ' + ('CLEAN' if not bad else 'DEFECTS: ' + ', '.join(bad)))
EOF
```

**Pass:** prints `PARITY CLEAN` for every touched guide.
**On fail:** each listed control is missing part of the parser contract — a missing `**Profile Level:**` drops the row entirely; a missing Description/Rationale piece renders the row with a silent blank cell. Both violate the quality bar; fix per create-hth-guide Phase 4.

## Check 4 — Pack wiring integrity (when packs or includes changed)

```bash
bash scripts/sync-packs-to-data.sh
```

**Pass:** every vendor prints `✓` (a `✗` leaves that vendor's yml stale). Then, for each include tag touched, confirm its key exists:

```bash
grep '"{N.N}":' docs/_data/packs/{vendor}.yml
```

**Pass:** the grep hits. A missing key renders NOTHING, silently.
Also confirm no same-(section, type) shadowing was introduced (create-code-pack Phase 2).

## Check 5 — Bookkeeping consistency (touched guides)

Manual pass — verify each:

1. Frontmatter `last_updated` == newest changelog row date == `date +%F` (the commit date, not the drafting date)
2. Frontmatter `version` == newest changelog row version
3. No existing control renumbered; new controls take the next free `### N.M` at the end of their section
4. Profile levels use the canonical Crawl/Walk/Run/Fly names — `grep -cE '\((Baseline|Hardened|Maximum Security)\)' docs/_guides/{slug}.md` must return 0
5. If `maturity` or any status badge changed, three things must agree:

```bash
grep -E '^maturity:' docs/_guides/{slug}.md                  # a LIST of the six statuses, resting on a *-drafted one
grep -c 'include status-badge.html' docs/_guides/{slug}.md   # == the VERIFIED-LIVE count in the run ledger
grep -c 'include ai-validated.html' docs/_guides/{slug}.md   # must be 0 — retired include, replaced by status-badge.html
```

   Maturity is a matrix (three stages × `ai`/`ni`), held as a **set**, so a promotion *adds* a member — `["ai-drafted"]` → `["ai-drafted", "ai-validated"]` — and never overwrites the list with a scalar. Test 5b catches the shape; only you can catch a status that was typed rather than earned, and only a `validate-hth-guide` run may write `ai-validated`. **No guide holds any `ni-*` status**, so any `ni-*` appearing here is a defect unless a maintainer put it there deliberately.

## Check 6 — Pack corpus validation and automation coverage

```bash
bash scripts/validate-packs.sh --touched     # blocking: findings in files you changed
bash scripts/validate-packs.sh {vendor}      # then read the coverage lines for your vendor
```

**Pass:** `--touched` exits 0. Exit 2 means a check could not run (missing `python3`/`pyyaml`) — treat that as a failure, never as a pass; it is the exit code that exists specifically so a validator cannot go green while blind.

**Then read checks 15–17 — the exit code is not the whole result:**

- **15** a pack file with zero executable content (prose in code markers — not a Code Pack, AGENTS.md rule 2b)
- **16** a single-type pack **monoculture**, plus how many of this vendor's leveled controls have a pack at all
- **17** a vendor with a documented admin-capable first-party CLI and no `cli/` packs

> Until now this battery ran `validate-guides.sh` and `sync-packs-to-data.sh` and **never ran the pack validator at all** — so every authoring skill terminated in a check that could not see pack quality or coverage. That is how nine packs shipped for one vendor with three of them containing no code, all of it structurally valid and fully "verified."

## Check 7 — Post-deploy spot check (after push only)

Open `/guides/{slug}/?view=cheat` on the live site. **Pass:** row count equals the guide's leveled-control count with no empty cells; new controls appear.
**Browser gotcha:** a backgrounded Chrome tab pauses CSS transitions and rejects screenshot capture — foreground the tab, or verify final-state styles with transitions disabled via injected `* { transition: none !important; }`.

## Gotchas

- Check 3's parser contract mirrors `docs/_includes/cheat-sheet.html` exactly — if that include's parsing logic ever changes, update Check 3 and the create-hth-guide Phase 4 anatomy in the same commit.
- The lint suite validates structure, not consistency — Check 5's version/date agreement is exactly the class of slip automated agents make most.
- Never "fix" a Check 3 failure by removing `**Profile Level:**` from a real control — that hides it from the cheat sheet instead of completing it. Profile Level is removed only from reference sections that were never controls.
- **This battery proves the repo RENDERS, not that the guidance WORKS.** Nothing here executes a pack, re-fetches a cited vendor doc, or runs an OCEAN control — a guide can pass all seven checks while instructing a console path the vendor renamed last quarter. For that, run the `validate-hth-guide` skill; the two are complements, not substitutes.
