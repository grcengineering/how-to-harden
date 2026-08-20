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

Five prescriptive, step-by-step playbooks live in `.claude/skills/`. They auto-load as skills in Claude Code, and they are plain markdown any agent or human can open and follow. **For the tasks below, follow the playbook rather than improvising:**

| Task | Playbook |
|------|----------|
| New vendor/product guide, platform breakout, de-stubbing | [.claude/skills/create-hth-guide/SKILL.md](.claude/skills/create-hth-guide/SKILL.md) |
| Currency update, correction, adding a control | [.claude/skills/update-hth-guide/SKILL.md](.claude/skills/update-hth-guide/SKILL.md) |
| Any Code Pack authoring or wiring | [.claude/skills/create-code-pack/SKILL.md](.claude/skills/create-code-pack/SKILL.md) |
| Pre-commit verification (every change) | [.claude/skills/verify-hth/SKILL.md](.claude/skills/verify-hth/SKILL.md) |
| Proving ClickOps/packs/OCEAN actually work; pack-corpus integrity | [.claude/skills/validate-hth-guide/SKILL.md](.claude/skills/validate-hth-guide/SKILL.md) |

`verify-hth` asks *does this render correctly*; `validate-hth-guide` asks *does this actually work* — structural vs. semantic, and they are not substitutes.

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

### 4. Every Control Needs ClickOps AND a Documented Automation Verdict

AI generates one method and stops. The bar is not "a code block exists" — it is **"every surface this vendor actually offers for this control was enumerated, then used or ruled out with evidence."**

- **ClickOps** — GUI/console steps with exact navigation paths.
- **Code** — one pack per surface the vendor documents for this control: `terraform` (**resources AND data sources**), `api` (REST **and** GraphQL), `cli` (first-party only), `sdk`, `config`, `siem`.
- **No surface exists?** Say so in the control, in place of `#### Code Implementation`:
  `**Automation:** ClickOps only — {vendor} exposes no write interface for this setting ({url}, {date}).`
  Silently omitting *both* the pack and this line is not permitted. An omission is indistinguishable from an oversight — which is how a guide ships with a third of its controls unautomated and nobody notices.

**Enforcement and verification are different packs.** A write pack sets the control; a read pack (Terraform *data source*, read-only endpoint, audit script) proves it. A vendor with zero read packs has skipped half its surface. Corpus-wide today: 692 Terraform `resource` blocks against 40 `data` blocks.

**Never decide "no CLI exists" from memory.** [`docs/research/cli-inventory.md`](docs/research/cli-inventory.md) is the fetch-verified census of first-party CLIs — look the vendor up. A row reading `GA-Official`/`PowerShell-Only` with admin coverage **Yes** means a `cli/` pack is *expected*, not merely permitted. `None`/`Vendor-Adjacent`/`Deprecated` means a `cli/` pack would be fabrication. No row → research it and add one in the same PR.

> This rule previously read *"at least one of: CLI, API (curl), Terraform, or script."* That sentence was a standing licence for a single-type pack corpus — one Terraform file satisfied it permanently, for every control, for the whole vendor — and 14 vendors currently ship 5+ packs of exactly one type. `scripts/validate-packs.sh` checks 15–17 now measure what this rule asserts.

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

Cheat sheets are built client-side from the rendered guide DOM. A control appears as a cheat row when its `### N.N` section carries a leading `**Profile Level:** L1 (Crawl)` bold key — that key alone creates the row (`docs/_includes/cheat-sheet.html` pushes any control with a parsed level). The remaining contract pieces fill the row's cells: `#### Description` with a non-empty paragraph, and `#### Rationale` with `**Why This Matters:**` bullets plus an `**Attack Prevented:**` line. A control missing one of those still renders — as a row with a silent blank gap where that cell's content should be, which violates the fully-populated-cells quality bar and is exactly as much a defect as a missing row, just harder to spot in a quick scan.

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


### 8. Maturity Is a Matrix, and Every Cell Is Earned by an Act

Every guide carries a `maturity` value drawn from a **matrix, not a ladder**: three **stages** — `drafted` → `reviewed` → `validated` — crossed with two **agents** — `ai` (artificial intelligence, a machine) and `ni` (natural intelligence, a person). Six statuses, and they are **not mutually exclusive**, so the value is a **list**:

```yaml
maturity: ["ai-drafted", "ai-validated"]
```

**The six statuses are defined once, in [VERSIONS.md](VERSIONS.md#maturity-statuses--the-matrix).** Do not restate the definitions here, in a guide, or in a PR description — link to them, so there is one copy to keep true.

The operational rule is who may write each status:

| Status | Set by |
|--------|--------|
| `ai-drafted` | An AI authoring run (`create-hth-guide`). Every AI-written guide starts here and holds nothing else until something makes contact with the product or exercises judgement over the content. |
| `ni-drafted` | The human author, in the PR that lands the content. Writing is not reviewing. |
| `ai-reviewed` | An agent review run, named in the changelog. Never hand-typed. |
| `ni-reviewed` | Maintainers, after a named human review. |
| `ai-validated` | Only a [`validate-hth-guide`](.claude/skills/validate-hth-guide/SKILL.md) run, as its Phase 6 close-out, and only when that run closed `FAIL = 0` with at least one `VERIFIED-LIVE` result. |
| `ni-validated` | Maintainers, after a named test on a real system. |

**An `ai-*` status asserts what a machine did and asserts nothing about human judgement.** `ai-validated` means an agent exercised the guidance against a real tenant or console and it survived — not that anyone decided the control was the right control. It is not a cheap `ni-reviewed` and never discharges the need for one. Writing any status by hand is not a formatting choice; it is asserting an act that did not happen.

**Statuses combine; that is how "better" is expressed.** There is no seventh status above `ai-validated`. A guide that a machine *and* a person validated holds both, and the version qualifier drops the agent prefix to say so — `v1.0.0-validated` is the strongest string in the system. The qualifier is derived by `docs/_includes/status-set.html`, never typed: furthest stage reached, agent-prefixed unless both agents reached it.

**Right now the entire NI row is empty.** All 130 guides are `ai-drafted`; two (Buildkite, Ona) are additionally `ai-validated`. No guide has ever held `ni-drafted`, `ni-reviewed`, or `ni-validated`. When writing about the corpus, say that plainly — the NI half of the matrix is a standing invitation to reviewers, not a description of anything that has happened.

**The per-surface mark.** Any status can also mark an individual **implementation surface**, via `{% include status-mark.html status="…" evidence="…" date="…" %}` appended to a `#### ClickOps Implementation` or `#### Code Implementation` heading, on that same line. In practice `ai-validated` is what gets stamped, and only where that surface came back `VERIFIED-LIVE`; `SKIPPED`, `BLOCKED`, and `DRIFT-CHECKED-ONLY` may not carry it.

The unit is the **surface, not the control** (changed 2026-08-20). A single badge at the top of a requirement averaged over two different acts — walking the console and running the Code Pack — and buildkite shows what that hid: `3.1` was validated by applying Terraform to a live organization and was never walked in the console, while `1.1` was console-only with no executed code, and both wore the same badge. Marking headings makes each claim name its own artifact, and makes **absence meaningful** — an unmarked ClickOps heading next to a marked Code heading is a true statement about what was tested.

The mark is **icon only, rendering no text node**, and that is load-bearing rather than cosmetic. Anything textual inside an `h4` lands in two places that fail silently: kramdown's auto-generated anchor (2,300+ in-guide links and every pack `guide_url` depend on those), and `node.textContent` in `docs/_includes/cheat-sheet.html`, which is compared against `'description'` / `'rationale'` to decide which section is being read — so a label would blank out cheat-sheet cells. The contract lives in the comment block of `docs/_includes/status-mark.html` — read it before stamping.

**`scripts/validate-guides.sh` Test 5b** rejects a bare scalar, any name outside the six statuses, an empty list, and any `*-reviewed`/`*-validated` claim that does not rest on a `*-drafted` claim in the same set (nothing can be reviewed or validated before it exists). It exists because an unrecognised value fails nowhere else — `docs/_includes/status-set.html` falls through to a bare `{% else %}` that resolves to `ai-drafted`, publishing a guide whose banner contradicts its own frontmatter with zero red anywhere. The test cannot tell an earned status from a typed one; that part is Rule 8.

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
| L1 | Crawl | All organizations |
| L2 | Walk | Security-sensitive environments |
| L3 | Run | Regulated industries (healthcare, finance, government) |
| L4 | Fly | Maximum-assurance environments (rare; most guides use only L1–L3) |

The canonical label written in guides is `L1 (Crawl)` / `L2 (Walk)` / `L3 (Run)` / `L4 (Fly)`. The retired `Baseline` / `Hardened` / `Maximum Security` names must not appear in new or updated controls.

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
| Automation for settings with no write API | Read-only does not mean no pack — ship a **verification** pack (Terraform data source, read-only endpoint, audit script). Claiming "none" requires evidence: the `**Automation:** ClickOps only` line with a fetched URL (Rule 4). An unevidenced "ClickOps only" is a coverage defect, not an honest note |
| One automation type for a vendor that documents several | Enumerate every surface before choosing a type (`create-code-pack` Phase 1). A single-type pack corpus is a **monoculture** — `validate-packs.sh` Check 16 flags it. Terraform is the usual default; it is frequently the *minority* of a vendor's real surface (Buildkite's security surface is mostly agent config + GraphQL) |
| Deciding "this vendor has no CLI" from memory | Look it up in `docs/research/cli-inventory.md`. 26 vendors with a documented admin-capable first-party CLI currently ship zero `cli/` packs — Check 17 lists them |
| A pack file that is 100% comments | Prose in code markers is not a Code Pack (Rule 2b). Check 15 fails it. If the honest answer is "no automation exists," that belongs in the guide as the Rule 4 `**Automation:**` line — not in a `.tf` file with nothing in it |
| Renumbering existing controls | Never — pack includes and inbound anchors depend on the numbers. New controls take the next free number at the end of their section |
| Hand-adding a `maturity` status | Each status is a claim that a specific act happened (Rule 8). `ai-validated` is written only by a `validate-hth-guide` run; every `ni-*` only by a maintainer after a named review or test. Test 5b checks the shape and the spelling, not the truth |
| Writing `maturity` as a scalar | It is a SET — `maturity: ["ai-drafted"]`, never `maturity: "ai-drafted"`. Statuses combine (a guide can be AI Drafted and NI Drafted, AI Validated and NI Validated), so the frontmatter is a list and Test 5b rejects the scalar form outright |
| Describing a guide as "reviewed" or "validated" with no agent named | That ambiguity is exactly what the agent axis removes. Say `ai-validated` or `ni-validated`; an unqualified word invites a reader to assume a human was involved when none was |
| Claiming any `ni-*` status for the corpus | No guide has ever held one. Every guide is `ai-drafted`, two are also `ai-validated`. Prose that implies human review exists is the single most damaging inaccuracy this repo can ship |
| A status badge on a control nobody exercised | The badge and the page banner render the same mark, so a badge on a `SKIPPED`/`BLOCKED`/`DRIFT-CHECKED-ONLY` control reads as the page-level claim applied to that requirement. Stamp one badge per `VERIFIED-LIVE` row in the run ledger — never from memory of what the run "basically covered" |
| Badge placed anywhere but between the `### N.N` heading and `**Profile Level:**` | Every other slot fails silently — corrupted heading anchor, control dropped from the cheat sheet, or the badge eaten as the description cell (Rule 8) |
| Correcting a validated guide and leaving the status standing | A currency pass that moves a console path invalidates the validation. Remove the statuses that finding invalidates (usually back to `["ai-drafted"]`) and strip the badges on the controls you changed — nothing in the lint compares a badge to the text beside it |
| SOURCES.md example URL left as an unverified placeholder | Every row in every standing-list table needs a real, specific, fetch-verified, currently-live example URL — never ship an italicized "described, not verified" placeholder; that notation is a research-in-progress state only, not a final answer. "Relevant" is broader than literal "hardening guide" wording: product docs, threat-intel writeups, and detection-engineering posts all count if they teach prevention, detection, deception, remediation, or recovery for a specific platform |

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
| Versioning + the maturity matrix (canonical) | `VERSIONS.md` |
| Status mark contract | `docs/_includes/status-mark.html` (comment block) |
| Status set → chips + version qualifier | `docs/_includes/status-set.html` (comment block) |
| Status icon (stage = glyph, AI = spark) | `docs/_includes/status-icon.html` (comment block) |
| Jekyll config | `docs/_config.yml` |

---

## Verification Before Every Commit

Run the battery (Windows: through Git Bash — the scripts carry cygpath/UTF-8 shims for native Python):

1. `bash scripts/validate-guides.sh` → must end `ALL TESTS PASSED`
2. `grep -rcE '^ *```' docs/_guides/*.md | grep -v ':0'` → must print nothing (zero fences)
3. If packs/includes changed: `bash scripts/sync-packs-to-data.sh` → every vendor `✓`, and every include's section key must exist in its vendor yml (a missing key renders nothing, silently)
4. Cheat parity on touched guides: every `**Profile Level:**` section has `#### Description` + Rationale/Why (Rule 6)
5. If a guide's `maturity` set or any status badge changed: the value is a list drawn from the six statuses, every status was written by whoever Rule 8 permits, and the mark count equals the run ledger's per-surface `VERIFIED-LIVE` count — `grep -c 'include status-mark.html' docs/_guides/{slug}.md`
6. If packs changed: `bash scripts/validate-packs.sh [vendor]` → zero FAILs, and **read the coverage warnings** (checks 15–17). They are the only thing in this repo that measures whether Rule 4 was actually followed; a green run with an ignored monoculture warning is how the corpus got here.

Claude Code users: the repo ships skills that encode these workflows end-to-end — `create-hth-guide`, `update-hth-guide`, `create-code-pack`, `validate-hth-guide`, `verify-hth` (in `.claude/skills/`).

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
| 2026-08-20 | Moved the validation mark from the control to the **surface**: `status-badge.html` (one badge above `**Profile Level:**`) is retired in favour of `status-mark.html`, appended to the `#### ClickOps Implementation` / `#### Code Implementation` heading whose artifact was actually exercised. A single per-control badge averaged two different acts — buildkite `3.1` was Terraform-applied against a live org and never console-walked, `1.1` was console-only, and both wore the same badge. Marks are icon-only by contract (a text node inside an `h4` silently rewrites the kramdown anchor and blinds the cheat-sheet parser). The cheat sheet now harvests marks from headings and names the surface. |
| 2026-08-20 | Rewrote Rule 8 for the maturity **matrix**: three stages × two agents (`ai` / `ni`), six non-exclusive statuses held as a list, who may write each, the derived version qualifier, the `status-badge.html` placement contract, and Test 5b's list/name/`*-drafted` rules. Recorded that no guide holds any `ni-*` status. Added Common Mistakes rows for scalar `maturity`, agent-less status words, and claiming human review that does not exist. |
| 2026-08-20 | Added Rule 8: machine validation entered the vocabulary as `ai-validated` — superseded the same day by the matrix. |
| 2026-08-08 | Post-audit refresh: full pack-type table (config/, siem/ split from db/, first-party-CLI rule) with the (section,type) collision rule; Rule 6 cheat-sheet parser contract; Rule 7 hardening-link standard with multi-source list form; multi-product platform procedure; verification battery section; incident table extended (Storm-2372, ELUSIVE COMET, UNC6040, Cyata Vault); new mistake rows (Liquid raw-escape, invisible cheat rows, pack collisions, no-write-API honesty, renumbering ban); pointer to the .claude/skills authoring skills. |
| 2026-05-06 | Added Rule 5: revision dates must reflect the commit/push date, not the drafting date. Added matching Common Mistakes row. |
| 2025-12-27 | Restructured to reference source files, removed duplications |
| 2025-12-26 | Initial creation |
