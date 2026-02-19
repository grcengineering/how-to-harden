# AI Agent Guidelines for How to Harden

Guidelines for AI assistants (Claude Code, Copilot, Cursor, etc.) working with this repository.

---

## Before You Start

**Read these files first—they are the source of truth:**

| File | What It Contains |
|------|------------------|
| [CONTRIBUTING.md](CONTRIBUTING.md) | Formatting rules, quality standards, PR process |
| [PHILOSOPHY.md](PHILOSOPHY.md) | Scope definition, design principles, what's in/out |
| [templates/vendor-guide-template.md](templates/vendor-guide-template.md) | Full guide structure, control template, all required sections |
| [README.md](README.md) | Project overview, repository structure |
| [docs/about.md](docs/about.md) | Categories, guide organization |

This file (AGENTS.md) provides **AI-specific guidance only**—it does not duplicate the above.

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

**Pack types:** `terraform/` (.tf), `api/` (.sh), `cli/` (.sh, .yml, .txt, .ini), `sdk/` (.py, .js, .groovy), `db/` (.sql, .kql, .spl), `siem/sigma/` (.yml)

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

`Identity` | `Security` | `DevOps` | `Data` | `Productivity` | `HR/Finance` | `CRM/Marketing`

See [docs/about.md](docs/about.md) for category descriptions and examples.

---

## Common AI Mistakes to Avoid

| Mistake | How to Avoid |
|---------|--------------|
| Inline code blocks in guides | ALL code must be in Code Packs — ZERO fenced blocks in guide files |
| Missing blank lines around tables | Check EVERY table before committing |
| Bare code blocks without language | Always specify: `bash`, `hcl`, `sql`, etc. (non-guide files) |
| Only ClickOps OR only Code | Always provide BOTH implementation methods |
| Skipped heading levels (## → ####) | Use sequential levels: ## → ### → #### |
| Leaving template placeholders | Replace ALL `[bracketed placeholders]` |
| Inventing compliance control IDs | Verify against official sources (linked in CONTRIBUTING.md) |
| Missing changelog entry | Always update changelog when modifying a guide |
| Generic incident references | Use specific incidents with dates from the table above |

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

## When in Doubt

1. **For structure questions:** Check `templates/vendor-guide-template.md`
2. **For formatting questions:** Check `CONTRIBUTING.md`
3. **For scope questions:** Check `PHILOSOPHY.md`
4. **For an example:** Read `docs/_guides/okta.md` (most complete guide)

---

## Changelog

| Date | Changes |
|------|---------|
| 2025-12-27 | Restructured to reference source files, removed duplications |
| 2025-12-26 | Initial creation |
