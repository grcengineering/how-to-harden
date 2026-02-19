# Claude Code Context

Quick reference for Claude Code working with this repository. For complete guidelines, see [AGENTS.md](AGENTS.md).

## Project Summary

SaaS security hardening guides focused on **integration security** and **supply chain attack mitigation**. Each guide provides both GUI ("ClickOps") and automation ("Code") implementations.

## Critical Rules

### 1. Tables MUST Have Blank Lines

```markdown
<!-- CORRECT -->
Text here

| Col1 | Col2 |
|------|------|
| A    | B    |

More text

<!-- WRONG - breaks Jekyll rendering -->
Text here
| Col1 | Col2 |
|------|------|
| A    | B    |
More text
```

### 2. ZERO Inline Code Blocks in Guides

**All code, queries, configs, and examples MUST live in the Code Pack system** — never as inline fenced code blocks in guide markdown files (`docs/_guides/*.md`).

- **No exceptions:** SQL, KQL, SPL, bash, Python, YAML, JSON, HCL, text configs, regex patterns, architecture diagrams — everything goes in packs.
- **Pack pipeline:** `packs/{vendor}/{type}/` source files → `scripts/sync-packs-to-data.sh` → `docs/_data/packs/{vendor}.yml` → `{% include pack-code.html vendor="{vendor}" section="X.X" %}` in guides.
- **Pack types (directories):** `terraform/`, `api/`, `cli/`, `sdk/`, `db/`, `siem/sigma/`
- **Verification:** Run `grep -cE '^ *```' docs/_guides/{vendor}.md` — must return **0** for every guide.
- To add code to a guide: create a pack file in `packs/{vendor}/{type}/`, run the sync script, then use the include tag in the guide.
- Do NOT use `lang=` parameter on include tags.

### 3. Code Blocks Must Specify Language (non-guide files only)

In files other than guides (README, AGENTS.md, CONTRIBUTING.md, etc.), always use: ` ```bash `, ` ```hcl `, ` ```sql `, ` ```python `, etc.

Never use bare ` ``` ` without a language.

### 4. Every Control Needs Both Methods

- **ClickOps** - GUI/console steps for manual implementation
- **Code** - CLI, API, and/or Terraform for automation

## File Locations

| What | Where |
|------|-------|
| Guides | `docs/_guides/[vendor-name].md` |
| Template | `templates/vendor-guide-template.md` |
| Jekyll config | `docs/_config.yml` |

## Creating a New Guide

```bash
cp templates/vendor-guide-template.md docs/_guides/[vendor-name].md
```

## For Everything Else

| Topic | Source File |
|-------|-------------|
| Guide/control structure | `templates/vendor-guide-template.md` |
| Formatting rules | `CONTRIBUTING.md` |
| Scope (in/out) | `PHILOSOPHY.md` |
| AI task procedures | `AGENTS.md` |
| Categories | `docs/about.md` |

## Quality Checks Before Commit

- [ ] **ZERO inline code blocks** in guide files (`grep -cE '^ *```' docs/_guides/*.md` all return 0)
- [ ] Tables have blank lines before AND after
- [ ] Code blocks specify language (non-guide files only)
- [ ] Both ClickOps and Code implementations provided
- [ ] All code uses pack includes: `{% include pack-code.html vendor="X" section="Y.Z" %}`
- [ ] Compliance mappings verified
- [ ] Changelog updated
