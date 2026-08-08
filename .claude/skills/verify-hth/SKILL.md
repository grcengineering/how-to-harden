---
name: verify-hth
description: Run the How to Harden verification battery — content lint, cheat-sheet parity, zero-fence check, pack include/yml integrity — before committing guide or pack changes. USE WHEN verifying HTH changes, before committing guides or packs, checking cheat sheet parity, or diagnosing why a control/pack isn't rendering. Run this at the end of every create-hth-guide, update-hth-guide, and create-code-pack task.
---

# Verify HTH

Every check below must pass before a commit. All commands from repo root; on Windows run through Git Bash (`bash ...` — the scripts carry cygpath/UTF-8 shims).

## 1. Repo lint suite (8 checks)

```bash
bash scripts/validate-guides.sh
```

Must end `ALL TESTS PASSED`. Covers: pack YAML validity, code-block languages, table separators, table blank lines, unescaped Liquid (wrap literal `{{...}}` in `{% raw %}…{% endraw %}`), valid categories, required frontmatter, required structural sections.

## 2. Zero inline fences in guides

```bash
grep -rcE '^ *```' docs/_guides/*.md | grep -v ':0' || echo CLEAN
```

Must print `CLEAN`. Any hit means code belongs in a pack (create-code-pack).

## 3. Cheat-sheet parity (parser-exact)

Every section carrying `**Profile Level:**` must also carry `#### Description` AND (`#### Rationale` or `**Why This Matters:**`) — that is exactly what the client-side cheat-sheet parser requires for a complete row. Check the touched guide:

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

## 4. Pack wiring integrity (when packs or includes changed)

```bash
bash scripts/sync-packs-to-data.sh
```

Every vendor must print `✓` (a `✗` skips that vendor and leaves its yml stale). Then confirm no include references a missing yml key: for each `{% include pack-code.html vendor="V" section="S" %}` in the touched guide, `grep '"S":' docs/_data/packs/V.yml` must hit. A missing key renders NOTHING, silently.

## 5. Bookkeeping consistency (touched guides)

- Frontmatter `last_updated` == newest changelog row date == today's commit date (`date +%F`)
- Frontmatter `version` == newest changelog row version
- New control numbers unique and sequential within their section; existing numbers never renumbered

## 6. Post-deploy spot check (after push)

Live cheat sheet: open `/guides/{slug}/?view=cheat` and confirm row count matches leveled-control count with no empty cells. Note: a backgrounded Chrome tab pauses CSS transitions and rejects screenshot capture — foreground the tab or verify final-state styles with transitions disabled.
