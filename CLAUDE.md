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

- **No exceptions:** SQL, KQL, SPL, bash, Python, YAML, JSON, HCL — everything goes in packs.
- **Pack pipeline:** `packs/{vendor}/{type}/` source files → `scripts/sync-packs-to-data.sh` → `docs/_data/packs/{vendor}.yml` → `{% include pack-code.html vendor="{vendor}" section="X.X" %}` in guides.
- **Pack types (directories):** `terraform/`, `api/`, `cli/`, `sdk/`, `db/`, `config/`, `siem/sigma/`
  - `cli/` is reserved for scripts that **invoke a vendor's first-party CLI binary** (e.g., `gh`, `vault`, `databricks`, `snow`). If the vendor has no first-party CLI, do NOT create a `cli/` pack — use `api/` (REST API), `terraform/`, or `config/` instead.
  - `config/` is for vendor-native configuration files and config-emitting scripts (e.g., `.jsonc` settings, shell scripts that write `.ini`/`.xml`/`.conf` snippets). Use this when the content configures the vendor's product but isn't directly executed via a CLI command.
  - See `docs/research/cli-inventory.md` for the authoritative list of which vendors actually publish first-party CLIs.
- **Verification:** Run `grep -cE '^ *```' docs/_guides/{vendor}.md` — must return **0** for every guide.
- To add code to a guide: create a pack file in `packs/{vendor}/{type}/`, run the sync script, then use the include tag in the guide.
- Do NOT use `lang=` parameter on include tags.

### 2b. Code Packs Must Contain ONLY Verified Executable Code

**Every Code Pack file must contain real, executable code verified against official vendor documentation.** No exceptions.

- **FORBIDDEN content in packs:** Generic text instructions, tree diagrams, checklists, architecture descriptions, prose wrapped in code markers, `.txt` files of any kind.
- **FORBIDDEN fabricated code:** SQL queries referencing tables that don't exist in the vendor's actual schema, API calls to undocumented endpoints, CLI commands for tools the vendor doesn't provide.
- **Verification requirement:** Before creating any pack file, confirm the code works against the vendor's real API/CLI/SQL interface by checking official docs. If the vendor doesn't have a SQL interface, don't create `.sql` files. If the vendor doesn't have a CLI, don't create CLI scripts.
- **Allowed pack file extensions:** `.tf`, `.sh`, `.py`, `.js`, `.groovy`, `.sql`, `.kql`, `.spl`, `.yml` (Sigma rules and GitHub Actions workflows), `.json` (IAM policies). No `.txt`, `.ini`, `.regex`, or other non-executable formats.
- **If in doubt, don't create the pack file.** It's better to have no Code Pack than a fabricated one.

### 3. Code Blocks Must Specify Language (non-guide files only)

In files other than guides (README, AGENTS.md, CONTRIBUTING.md, etc.), always use: ` ```bash `, ` ```hcl `, ` ```sql `, ` ```python `, etc.

Never use bare ` ``` ` without a language.

### 4. Every Control Needs Both Methods

- **ClickOps** - GUI/console steps for manual implementation
- **Code** - CLI, API, and/or Terraform for automation

### 5. Revision Dates Reflect the Commit Date

Right before `git commit`, set the guide's `last_updated` frontmatter value **and** the new changelog row's `Date` column to today's date (run `date +%F`). Never carry over the drafting date. Both fields must agree. Stale `last_updated` values mislead readers because Jekyll renders that field as "Last updated:" at the top of every guide page.

See [AGENTS.md §5](AGENTS.md#5-revision-dates-reflect-the-publish-date-not-the-drafting-date) for the full rule.

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
- [ ] **All pack code is verified** against real vendor documentation (no fabricated SQL, no fake CLI commands)
- [ ] **No .txt files** in packs — only executable code files
- [ ] Tables have blank lines before AND after
- [ ] Code blocks specify language (non-guide files only)
- [ ] Both ClickOps and Code implementations provided
- [ ] All code uses pack includes: `{% include pack-code.html vendor="X" section="Y.Z" %}`
- [ ] Compliance mappings verified
- [ ] Changelog updated
- [ ] `last_updated` frontmatter AND new changelog row's Date column both equal today's date (`date +%F`) — not the drafting date


<!-- SECURITY_RULES_START -->
# Security Rules

Auto-generated from [TikiTribe/claude-secure-coding-rules](https://github.com/TikiTribe/claude-secure-coding-rules)

## Detected Stack

- **Languages**: javascript, python, ruby, rust, sql
- **Infrastructure**: github-actions, terraform

## Fetched Rules

- `_core/owasp-2025.md`
- `cicd/github-actions/CLAUDE.md`
- `iac/terraform/CLAUDE.md`
- `languages/javascript/CLAUDE.md`
- `languages/python/CLAUDE.md`
- `languages/ruby/CLAUDE.md`
- `languages/rust/CLAUDE.md`
- `languages/sql/CLAUDE.md`

<!-- SECURITY_RULES_END -->
