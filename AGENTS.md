# AI Agent Guidelines for How to Harden

Guidelines for AI assistants (Claude Code, Copilot, Cursor, etc.) working with this repository.

---

## Before You Start

**Read these files first—they are the source of truth:**

| File | What It Contains |
|------|------------------|
| [CONTRIBUTING.md](CONTRIBUTING.md) | Formatting rules, quality standards, PR process |
| [PHILOSOPHY.md](PHILOSOPHY.md) | Scope definition, design principles, what's in/out |
| [SOURCES.md](SOURCES.md) | The authoritative-source taxonomy: what counts as a hardening source (and what never does), tiered admission criteria, verification and conflict rules |
| [templates/vendor-guide-template.md](templates/vendor-guide-template.md) | Full guide structure, control template, all required sections |
| [README.md](README.md) | Project overview, repository structure |
| [docs/about.md](docs/about.md) | Categories, guide organization |

This file (AGENTS.md) provides **AI-specific guidance only**—it does not duplicate the above.

## Authoring Playbooks — Use These For Core Workflows

Four prescriptive, step-by-step playbooks live in `.claude/skills/`. They auto-load as skills in Claude Code, and they are plain markdown any agent or human can open and follow. **For the tasks below, follow the playbook rather than improvising:**

| Task | Playbook |
|------|----------|
| New vendor/product guide, platform breakout, de-stubbing | [.claude/skills/create-hth-guide/SKILL.md](.claude/skills/create-hth-guide/SKILL.md) |
| Currency update, correction, adding a control | [.claude/skills/update-hth-guide/SKILL.md](.claude/skills/update-hth-guide/SKILL.md) |
| Any Code Pack authoring or wiring | [.claude/skills/create-code-pack/SKILL.md](.claude/skills/create-code-pack/SKILL.md) |
| Pre-commit verification (every change) | [.claude/skills/verify-hth/SKILL.md](.claude/skills/verify-hth/SKILL.md) |

The Task Procedures below remain as quick reference; the playbooks are the full processes.

---

## Critical Formatting Rules

These are the most common AI mistakes. The rules themselves are defined in [CONTRIBUTING.md](CONTRIBUTING.md#markdown-formatting-requirements).

### 1. Tables Break Without Blank Lines

**This is the #1 AI mistake.** Jekyll will not render tables without blank lines before AND after.

```markdown
<!-- WRONG - AI often generates this -->
**Configure settings:**
| Setting | Value |
|---------|-------|
| Option  | Value |
**Next step:**

<!-- CORRECT -->
**Configure settings:**

| Setting | Value |
|---------|-------|
| Option  | Value |

**Next step:**
```

### 2. ZERO Inline Code Blocks in Guides

**This is a hard rule.** Guide files (`docs/_guides/*.md`) must contain ZERO fenced code blocks. All code lives in the Code Pack system.

**Instead of inline code:**
1. Create a pack source file in `packs/{vendor}/{type}/hth-{vendor}-{N.NN}-{slug}.{ext}`
2. Add `HTH Guide Excerpt: begin/end` markers around the extractable content
3. Run `bash scripts/sync-packs-to-data.sh` to generate YAML data
4. Use `{% include pack-code.html vendor="{vendor}" section="X.X" %}` in the guide

**Pack types:**

| Type | Content | Extensions |
|------|---------|------------|
| `terraform/` | Config-as-Code from a real provider | `.tf` |
| `api/` | bash+curl against documented REST APIs | `.sh` |
| `cli/` | First-party vendor CLI only (`gh`, `vault`, `databricks`…) — no first-party CLI means no cli/ pack | `.sh`, `.yml` |
| `sdk/` | Official SDK scripts | `.py`, `.ps1`, `.js`, `.go`, `.groovy`, `.rb` |
| `db/` | Vendor-NATIVE queries only: Snowflake/Databricks SQL, BigQuery log-export SQL, SOQL, DAX | `.sql`, `.kql`, `.dax` |
| `siem/` | SIEM-resident detections (Splunk SPL, Sentinel KQL) — these run in the SIEM, never file them under db/ | `.spl`, `.kql` |
| `siem/sigma/` | Sigma rules (the only type allowing multiple files per section) | `.yml` |
| `config/` | Vendor-native config files and config-emitting scripts | `.jsonc`, `.yml`, `.sh` |

**Collision rule:** the sync keeps ONE file per (section, type) — last alphabetically wins, silently. Except `siem/sigma/`, a second same-type file on the same section shadows the first. Check existing files for the section before numbering.

**Verify:** `grep -cE '^ *```' docs/_guides/{vendor}.md` must return 0.

### 3. Code Blocks Need Language Specifiers (non-guide files)

In files other than guides (README, AGENTS.md, etc.):

```markdown
<!-- WRONG -->
```
echo "hello"
```

<!-- CORRECT -->
```bash
echo "hello"
```
```

Valid languages: `bash`, `hcl`, `python`, `sql`, `yaml`, `json`, `markdown`

### 4. Every Control Needs Both ClickOps AND Code

AI often generates only one method. Always provide:
- **ClickOps** - GUI/console steps with exact navigation paths
- **Code** - At least one of: CLI, API (curl), Terraform, or script

### 5. Revision Dates Reflect the Publish Date, Not the Drafting Date

`last_updated` (frontmatter) and the new changelog row's `Date` column **must both be set to the date the change is actually committed and pushed to `main`** — not the date the draft was started. If a guide is drafted over multiple days, update both fields to the final commit date right before pushing.

**Right before `git commit`, do this:**

```bash
TODAY=$(date +%F)   # YYYY-MM-DD in your local timezone
# Update frontmatter `last_updated:` to $TODAY
# Update the new changelog row's Date column to $TODAY
```

**Why this matters:** the `last_updated` field is what users see at the top of the rendered guide ("Last updated: 2026-MM-DD"). A stale date misleads readers about how current the content is. The dates in frontmatter and changelog must agree.

**Common failure mode (avoid):** drafting a guide on day N, leaving `last_updated: "N"`, then pushing on day N+8. The published guide claims to be 8 days older than it actually is. **Always re-stamp both fields immediately before commit.**

### 6. The Cheat-Sheet Parser Contract

Cheat sheets are built client-side from the rendered guide DOM. A control appears as a cheat row ONLY if its `### N.N` section carries ALL of: a leading `**Profile Level:** L1 (Crawl)` bold key, `#### Description` with a non-empty paragraph, and `#### Rationale` with `**Why This Matters:**` bullets plus an `**Attack Prevented:**` line. A control missing any of these silently vanishes from the cheat sheet.

Reference sections ("Key Events to Monitor", "Integration Risk Assessment Matrix", compliance quick-reference subsections) and `### N.N.N` implementation walk-throughs must NOT carry `**Profile Level:**` — omitting it is what correctly excludes them.

### 7. Hardening-Guide Links Must Be Literal Hardening Docs

`hardening_docs` in `docs/_data/doc_links.yml` points at actual hardening/security-configuration documentation or an authoritative benchmark (CIS, CISA SCuBA) — NEVER a Trust Center, marketing security page, or compliance-badge page. If no honest link exists, omit the key: no button beats a dishonest one. Verify every URL by fetching it; hosts that block fetchers need a real-browser check. Multiple sources use the list form (renders an expandable button):

```yaml
hardening_docs:
  - label: "Vendor Hardening Guide"
    url: "https://..."
  - label: "CIS Benchmark"
    url: "https://..."
```

---

## Task Procedures

Step-by-step procedures for common tasks. Follow the template and source files for content structure.

### Creating a New Platform Guide

1. **Copy template:**
   ```bash
   cp templates/vendor-guide-template.md docs/_guides/[vendor-name].md
   ```

2. **Set front matter** (see template for required fields):
   - `layout: guide`
   - `vendor`, `slug`, `tier`, `category`, `description`, `last_updated`

3. **Complete ALL sections** from the template—don't leave placeholders

4. **For each control:**
   - Follow the exact control structure in the template
   - Include both ClickOps AND Code implementations
   - Map to compliance frameworks (order defined in template)
   - Add real-world incident references where relevant

5. **Before committing:**
   - Verify blank lines around ALL tables
   - Verify language on ALL code blocks
   - Update the changelog at the bottom

### Adding a Control to an Existing Guide

1. Read the existing guide to understand its style and numbering
2. Place the control in the correct section (1-7 as defined in template)
3. Use next sequential number (e.g., existing 2.3 → new 2.4)
4. Follow the exact control structure from the template
5. Include both ClickOps and Code implementations
6. Update the guide's changelog

### Creating a Product Guide in a Multi-Product Platform

Platforms whose products have distinct hardening surfaces (Google Workspace, Anthropic) split into a hub guide plus product guides:

1. **Hub guide** keeps org-wide "Common Controls" (SSO, roles, integration governance) and sets frontmatter `platform`, `platform_slug`, and `product: "Common Controls"`.
2. **Product guides** set the same `platform`/`platform_slug` with their own `product`, open with a one-line "This is a product guide within the [platform](/guides/{hub-slug}/)" pointer, and cross-reference the hub instead of duplicating platform-wide controls.
3. The homepage groups all guides sharing a `platform_slug` into one expandable platform card automatically.
4. Product-specific doc links go in `docs/_data/doc_links.yml` per product slug; pack includes may reference the platform's shared pack dir via the explicit `vendor=` parameter.

Reference implementations: `google-workspace` + gmail/google-chat/google-drive; `anthropic-claude` + claude-enterprise/claude-code/anthropic-api.

### Adding Integration-Specific IP Allowlisting

1. Add as a sub-section under Section 2 (Network Access Controls)
2. Use format: `#### 2.X.Y IP Allowlisting: Restricting [Vendor Name]`
3. Follow the integration sub-section pattern in the template (section 2.1.1)
4. **Always include:**
   - Verification date for IP addresses
   - Link to vendor's official IP documentation
   - Data access level (High/Medium/Low)

---

## Quick Reference Data

Information frequently needed when generating content.

### Real-World Incidents for Rationale Sections

Reference these when justifying controls:

| Incident | Date | Key Lesson |
|----------|------|------------|
| Salesloft/Drift breach | Aug 2025 | 700+ orgs compromised via OAuth tokens; IP allowlisting blocked attack at Okta |
| Gainsight breach | Nov 2025 | Salesforce integration compromise; affected 200+ orgs |
| Okta support breach | Oct 2023 | HAR file token theft; FIDO2 MFA would have prevented |
| CircleCI breach | Jan 2023 | Developer secrets exposed; secret rotation required |
| Snowflake breach | 2024 | 165+ orgs via credential stuffing; MFA would have prevented |
| BeyondTrust breach | Dec 2024 | API key compromise led to Treasury access |
| Storm-2372 device-code phishing | Feb 2025 | OAuth device code flow steals MFA-satisfying tokens; block via Conditional Access authentication-flows policy |
| ELUSIVE COMET Zoom abuse | Apr 2025 | Fake "Zoom" prompts trick victims into granting remote control; lock the setting off account-wide |
| UNC6040/ShinyHunters vishing | 2025 | Fake "Data Loader" connected app authorized by phone-socialed employees; API access control + connected-app allowlisting |
| Cyata Vault zero-days | 2025 | Nine flaws incl. Vault's first public RCE via policy-normalization and audit-device abuse; patch + audit policy writes |

**Usage format:**
```markdown
**Real-World Incidents:**
- **Okta support breach (Oct 2023):** FIDO2 MFA would have prevented token theft since phishing-resistant authenticators don't expose replayable credentials.
```

### Compliance Framework Order

When mapping controls, use this order (defined in template):

1. CIS Controls (e.g., 6.3, 6.5)
2. NIST 800-53 (e.g., IA-2, AC-3, SC-7)
3. SOC 2 (e.g., CC6.1, CC6.2)
4. ISO 27001 (e.g., A.9.4.1)
5. PCI DSS (e.g., 8.3.1)
6. DISA STIG (when applicable)

### Profile Levels

| Level | Name | Use For |
|-------|------|---------|
| L1 | Baseline | All organizations |
| L2 | Hardened | Security-sensitive environments |
| L3 | Maximum Security | Regulated industries (healthcare, finance, government) |

### Valid Categories

For guide front matter `category` field:

`Identity` | `Security` | `DevOps` | `Data` | `Productivity` | `HR/Finance` | `Marketing` | `AI/ML Platform` | `IaC` | `IT Operations`

This list is enforced by `scripts/validate-guides.sh` (Test 5). When adding a new category, update the validator, [docs/about.md](docs/about.md), and this section together.

See [docs/about.md](docs/about.md) for category descriptions and examples.

---

## Common AI Mistakes to Avoid

| Mistake | How to Avoid |
|---------|--------------|
| Inline code blocks in guides | ALL code must be in Code Packs — ZERO fenced blocks in guide files |
| Fabricated/hallucinated code in packs | EVERY pack file must contain real code verified against official vendor docs. No fabricated SQL tables, no fake API endpoints, no invented CLI commands |
| Non-code files (.txt) in packs | Packs contain ONLY executable code. No tree diagrams, checklists, or prose. If it's not runnable, it doesn't belong in a pack |
| SQL for platforms without SQL | Only create `.sql` pack files for vendors with real SQL interfaces (Snowflake, Databricks, Salesforce SOQL, BigQuery, etc.). Most SaaS platforms use REST APIs, not SQL |
| Missing blank lines around tables | Check EVERY table before committing |
| Bare code blocks without language | Always specify: `bash`, `hcl`, `sql`, etc. (non-guide files) |
| Only ClickOps OR only Code | Always provide BOTH implementation methods |
| Skipped heading levels (## → ####) | Use sequential levels: ## → ### → #### |
| Leaving template placeholders | Replace ALL `[bracketed placeholders]` |
| Inventing compliance control IDs | Verify against official sources (linked in CONTRIBUTING.md). CIS benchmark numbering shifts between major versions — when the exact ID can't be verified, map by control NAME with a version note. Prefer CISA SCuBA policy IDs (GWS.*, MS.*) where a baseline exists |
| Missing changelog entry | Always update changelog when modifying a guide |
| Stale `last_updated` / changelog date | Set both to the actual commit-day date right before `git commit` — never carry over the drafting date |
| Generic incident references | Use specific incidents with dates from the table above |
| Literal `{{...}}` eaten by Jekyll | Vault templates, Handlebars, etc. in prose or inline code must be wrapped in `{% raw %}...{% endraw %}` (lint Test 8 catches this) |
| Control invisible on the cheat sheet | It's missing part of the parser contract (Rule 6): Profile Level + Description H4 + Rationale/Why bullets |
| Same-section same-type pack files | The sync silently keeps only the last alphabetically (Collision rule, Rule 2) — check before numbering |
| Automation for settings with no write API | Many admin surfaces are ClickOps-only (read-only Policy APIs). State that honestly; ship verification-style packs (assessment tools, read-only audits) or none |
| Renumbering existing controls | Never — pack includes and inbound anchors depend on the numbers. New controls take the next free number at the end of their section |

---

## File Quick Reference

| Purpose | File Path |
|---------|-----------|
| Guide template | `templates/vendor-guide-template.md` |
| All guides | `docs/_guides/*.md` |
| Contribution rules | `CONTRIBUTING.md` |
| Scope/philosophy | `PHILOSOPHY.md` |
| Project structure | `README.md` |
| Categories | `docs/about.md` |
| Jekyll config | `docs/_config.yml` |

---

## Verification Before Every Commit

Run the battery (Windows: through Git Bash — the scripts carry cygpath/UTF-8 shims for native Python):

1. `bash scripts/validate-guides.sh` → must end `ALL TESTS PASSED`
2. `grep -rcE '^ *```' docs/_guides/*.md | grep -v ':0'` → must print nothing (zero fences)
3. If packs/includes changed: `bash scripts/sync-packs-to-data.sh` → every vendor `✓`, and every include's section key must exist in its vendor yml (a missing key renders nothing, silently)
4. Cheat parity on touched guides: every `**Profile Level:**` section has `#### Description` + Rationale/Why (Rule 6)

Claude Code users: the repo ships skills that encode these workflows end-to-end — `create-hth-guide`, `update-hth-guide`, `create-code-pack`, `verify-hth` (in `.claude/skills/`).

---

## When in Doubt

1. **For structure questions:** Check `templates/vendor-guide-template.md`
2. **For formatting questions:** Check `CONTRIBUTING.md`
3. **For scope questions:** Check `PHILOSOPHY.md`
4. **For an example:** Read `docs/_guides/okta.md` (most complete guide) or `docs/_guides/gmail.md` (cleanest parser-contract example)
5. **For multi-product platforms:** Read `docs/_guides/google-workspace.md` (hub) and `docs/_guides/gmail.md` (product guide)

---

## Changelog

| Date | Changes |
|------|---------|
| 2026-08-08 | Post-audit refresh: full pack-type table (config/, siem/ split from db/, first-party-CLI rule) with the (section,type) collision rule; Rule 6 cheat-sheet parser contract; Rule 7 hardening-link standard with multi-source list form; multi-product platform procedure; verification battery section; incident table extended (Storm-2372, ELUSIVE COMET, UNC6040, Cyata Vault); new mistake rows (Liquid raw-escape, invisible cheat rows, pack collisions, no-write-API honesty, renumbering ban); pointer to the .claude/skills authoring skills. |
| 2026-05-06 | Added Rule 5: revision dates must reflect the commit/push date, not the drafting date. Added matching Common Mistakes row. |
| 2025-12-27 | Restructured to reference source files, removed duplications |
| 2025-12-26 | Initial creation |
