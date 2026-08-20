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
- **Pack types (directories):** `terraform/`, `api/`, `cli/`, `sdk/`, `db/`, `config/`, `siem/`, `siem/sigma/`
  - `cli/` is reserved for scripts that **invoke a vendor's first-party CLI binary** (e.g., `gh`, `vault`, `databricks`, `snow`). If the vendor has no first-party CLI, do NOT create a `cli/` pack — use `api/` (REST API), `terraform/`, or `config/` instead.
  - `config/` is for vendor-native configuration files and config-emitting scripts (e.g., `.jsonc` settings, shell scripts that write `.ini`/`.xml`/`.conf` snippets). Use this when the content configures the vendor's product but isn't directly executed via a CLI command.
  - `db/` is for vendor-NATIVE query surfaces only (Snowflake/Databricks SQL, BigQuery log-export SQL, SOQL, DAX). `siem/` is for SIEM-resident detections (Splunk `.spl`, Sentinel `.kql`) — SIEM queries never go in `db/`.
  - **Collision rule:** the sync keeps ONE file per (section, type), last-alphabetical wins silently (only `siem/sigma/` allows multiples). Full table + rules: [AGENTS.md §Pack types](AGENTS.md).
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

### 4. Every Control Needs ClickOps AND an Automation Verdict

- **ClickOps** — GUI/console steps for manual implementation.
- **Code** — one pack per surface the vendor actually documents for that control: `terraform` (**resources AND data sources**), `api` (REST **and** GraphQL), `cli`, `sdk`, `config`, `siem`. Enumerate all six before choosing; one code artifact is not automatically "done."
- **No surface?** The control carries `**Automation:** ClickOps only — {vendor} exposes no write interface for this setting ({url}, {date}).` Omitting both the pack and this line is not permitted — it makes an unchecked control look identical to a checked one.
- **Never decide "no CLI exists" from memory** — look the vendor up in `docs/research/cli-inventory.md`.

Full rule with the failure history behind it: [AGENTS.md §4](AGENTS.md).

### 5. Revision Dates Reflect the Commit Date

Right before `git commit`, set the guide's `last_updated` frontmatter value **and** the new changelog row's `Date` column to today's date (run `date +%F`). Never carry over the drafting date. Both fields must agree. Stale `last_updated` values mislead readers because Jekyll renders that field as "Last updated:" at the top of every guide page.

See [AGENTS.md §5](AGENTS.md#5-revision-dates-reflect-the-publish-date-not-the-drafting-date) for the full rule.

### 6. Cheat Sheets Are Parsed From Control Structure

A control renders as a cheat-sheet row when its `### N.N` section carries `**Profile Level:**` — that key alone creates the row. Every other contract piece (`#### Description` + paragraph, `#### Rationale` with `**Why This Matters:**` bullets plus `**Attack Prevented:**`) fills a cell; miss one and the row renders with a silent blank gap, which violates the fully-populated-cells quality bar. Omit `**Profile Level:**` and the control is excluded entirely — so reference sections and `### N.N.N` walk-throughs must NOT carry it. Full contract: [AGENTS.md §6](AGENTS.md).

### 7. Hardening Links Are Literal Hardening Docs

`hardening_docs` in `docs/_data/doc_links.yml` = actual hardening/config documentation or an authoritative benchmark, never a Trust Center or marketing security page; omit the key when no honest link exists. Multi-source entries use a list of `{label, url}` (renders an expandable button). Full standard: [AGENTS.md §7](AGENTS.md).

### 8. Maturity Is a Matrix, and Every Cell Is Earned

A **matrix, not a ladder**: three stages (`drafted` → `reviewed` → `validated`) × two agents (`ai` = a machine, `ni` = natural intelligence, i.e. a person) = six statuses. They are **not mutually exclusive**, so `maturity` is a **list**: `maturity: ["ai-drafted", "ai-validated"]`. **Defined once, canonically, in [VERSIONS.md](VERSIONS.md#maturity-statuses--the-matrix)** — link to it, never restate it.

- An **`ai-*` status is a claim about a machine's act and asserts nothing about human judgement.** `ai-validated` means an agent exercised the guidance against a real tenant or console and it survived — it never substitutes for its `ni-*` twin, and there is no rung above it to climb to. "Better" is expressed by holding **both** agents at a stage, which is also why the version qualifier drops the agent prefix in that case: `v1.0.0-validated` is the strongest string in the system. The qualifier is derived by `docs/_includes/status-set.html`, never typed.
- **No guide currently holds any `ni-*` status.** All 130 are `ai-drafted`; two (Buildkite, Ona) are also `ai-validated`. Never write prose implying a human has reviewed or tested any of it.
- Only a `validate-hth-guide` run may write `ai-validated` (its Phase 6, gated on `FAIL = 0` **and** ≥1 `VERIFIED-LIVE` result). New AI-written guides are `["ai-drafted"]` and nothing else; every `ni-*` is maintainers only. Typing a status by hand asserts an act that did not happen.
- The per-**surface** mark — `{% include status-mark.html status="ai-validated" evidence="…" date="…" %}` — is appended to a `#### ClickOps Implementation` or `#### Code Implementation` heading, on the same line, and nowhere else. It marks the surface that was exercised, not the control: a control whose Terraform was applied live but whose console was never walked gets a Code mark and no ClickOps mark. `VERIFIED-LIVE` surfaces only — never `SKIPPED`/`BLOCKED`/`DRIFT-CHECKED-ONLY`. The mark is **icon only and renders no text node**; give it a label and you silently rewrite the heading's anchor and blind the cheat-sheet parser, which decides what a section is by comparing that heading's text. Contract: the comment block in `docs/_includes/status-mark.html`.
- `scripts/validate-guides.sh` Test 5b rejects a scalar, an unknown status name, an empty list, and any `*-reviewed`/`*-validated` that does not rest on a `*-drafted` in the same set; it cannot tell an earned status from a typed one.

Full rule: [AGENTS.md §8](AGENTS.md).


## Authoring Skills — Use These, Don't Improvise

This repo ships skills in `.claude/skills/` that encode the core workflows as prescriptive step-by-step processes. They auto-load in Claude Code and are plain markdown for everyone else. **When a task matches, follow the skill:**

| Skill | Use for |
|-------|---------|
| `create-hth-guide` | New vendor/product guides, platform breakouts, de-stubbing placeholders |
| `update-hth-guide` | Currency updates, corrections, adding controls to existing guides |
| `create-code-pack` | Any pack authoring or pack wiring |
| `verify-hth` | The pre-commit verification battery (run after every change) |
| `validate-hth-guide` | Proving ClickOps steps, Code Packs, and OCEAN scanning actually work — and iterating until they do. **The only thing allowed to promote a guide to `ai-validated`** |

Source-selection standards (hardening guide vs Trust Center; which third parties are authoritative — CIS, DISA, CISA SCuBA, NIST, and the expert-vendor standing list) live in [SOURCES.md](SOURCES.md) — all four skills depend on it.

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
- [ ] Every control has ClickOps **and** either a pack or an evidenced `**Automation:** ClickOps only` line (rule 4)
- [ ] Every automation surface enumerated before choosing pack types — no single-type monoculture left unjustified
- [ ] `bash scripts/validate-packs.sh {vendor}` run and its **coverage warnings read** (checks 15–17), not just its exit code
- [ ] All code uses pack includes: `{% include pack-code.html vendor="X" section="Y.Z" %}`
- [ ] Compliance mappings verified (never invent IDs; CIS numbering shifts between majors — map by name with a version note when unverifiable; prefer CISA SCuBA policy IDs where a baseline exists)
- [ ] Changelog updated; frontmatter `version` matches the new changelog row
- [ ] `last_updated` frontmatter AND new changelog row's Date column both equal today's date (`date +%F`) — not the drafting date
- [ ] `maturity` is a **list** drawn from `ai-drafted` | `ni-drafted` | `ai-reviewed` | `ni-reviewed` | `ai-validated` | `ni-validated`, rests on a `*-drafted` status, and every member was set by whoever rule 8 permits — not hand-added
- [ ] Every `status-mark.html` mark sits on a `#### ClickOps Implementation` / `#### Code Implementation` heading, and marks a surface that came back VERIFIED-LIVE (never SKIPPED/BLOCKED/DRIFT-CHECKED-ONLY)
- [ ] `bash scripts/validate-guides.sh` ends ALL TESTS PASSED (Windows: run via Git Bash)
- [ ] Every touched control still meets the cheat-parser contract (rule 6)
- [ ] Every pack include's section key exists in its vendor's `docs/_data/packs/*.yml` (a missing key renders nothing, silently)
- [ ] Literal `{{...}}` (Vault templates etc.) wrapped in `{% raw %}{% endraw %}`


<!-- SECURITY_RULES_START -->
# Security Rules

Auto-generated from [TikiTribe/claude-secure-coding-rules](https://github.com/TikiTribe/claude-secure-coding-rules)

## Detected Stack

- **Languages**: javascript, python, ruby, sql
- **Infrastructure**: github-actions, terraform

## Fetched Rules

- `_core/owasp-2025.md`
- `cicd/github-actions/CLAUDE.md`
- `iac/terraform/CLAUDE.md`
- `languages/javascript/CLAUDE.md`
- `languages/python/CLAUDE.md`
- `languages/ruby/CLAUDE.md`
- `languages/sql/CLAUDE.md`

<!-- SECURITY_RULES_END -->
