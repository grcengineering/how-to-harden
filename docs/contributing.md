---
layout: default
title: Contributing
permalink: /contributing/
---

<div class="about-page" markdown="1">

# Contributing to How to Harden

Thank you for your interest in contributing to How to Harden! This document provides guidelines for contributing new guides, improvements, and fixes.

## Quick Links

- [Project README](https://github.com/grcengineering/how-to-harden)
- [Guide Template](https://github.com/grcengineering/how-to-harden/blob/main/templates/vendor-guide-template.md)
- [Version Registry](https://github.com/grcengineering/how-to-harden/blob/main/VERSIONS.md)
- [Report Issues](https://github.com/grcengineering/how-to-harden/issues)

## Ways to Contribute

### 1. Report Issues or Bugs

- **Outdated information:** Open an issue with tag `content-outdated`
- **Broken links:** Open an issue with tag `broken-link`
- **Formatting issues:** Open an issue with tag `formatting`
- **Security concerns:** See [Security Reporting](#security-reporting)

### 2. Improve Existing Guides

- Fix typos, clarify instructions, update screenshots
- Add missing controls or detection queries
- Update compliance mappings
- Verify and update vendor IP addresses for integrations

### 3. Create New Guides

- Use the [vendor guide template](https://github.com/grcengineering/how-to-harden/blob/main/templates/vendor-guide-template.md)
- Follow the structure and quality checklist
- Test all commands and configurations
- Submit a pull request

## Markdown Formatting Requirements

⚠️ **CRITICAL:** Our website uses Jekyll with kramdown for Markdown rendering. Certain formatting rules MUST be followed or content will not render correctly.

### Tables

**Tables MUST have blank lines before and after them.**

✅ **Correct:**

```markdown
**Step 1: Configure Settings**

| Setting | Value |
|---------|-------|
| Option  | Value |

**Step 2: Next Action**
```

❌ **Incorrect (will break on website):**

```markdown
**Step 1: Configure Settings**
| Setting | Value |
|---------|-------|
| Option  | Value |
**Step 2: Next Action**
```

### Other Formatting Guidelines

- **Code blocks:** Always specify the language for syntax highlighting
- **Headings:** Use consistent levels (don't skip from `##` to `####`)
- **Emphasis:** Use `**bold**` for emphasis, not `__bold__`
- **Lists:** Use consistent list markers (all `-` or all `*`, not mixed)

## Versioning

HTH uses **Extended SemVer with a derived maturity qualifier**, aligned with [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks) versioning practices. See [VERSIONS.md](https://github.com/grcengineering/how-to-harden/blob/main/VERSIONS.md) for full documentation.

### Version Format

```
v{MAJOR}.{MINOR}.{PATCH}-{qualifier}

The qualifier is DERIVED from the maturity set, never typed alongside it: it names
the furthest stage reached, agent-prefixed unless BOTH agents reached that stage.

Examples:
  v0.1.0-ai-drafted    # Initial AI-drafted guide
  v0.1.1-ai-drafted    # Typo fixes (PATCH)
  v0.2.0-ai-drafted    # New control added (MINOR)
  v0.2.0-ai-validated  # Same content, exercised against a live tenant by an agent
  v0.2.0-ni-reviewed   # Same content, now vouched for by a human practitioner
  v1.0.0-ni-validated  # First release a person applied and tested (MAJOR milestone)
  v1.0.0-validated     # ...and a machine validated it too — the strongest string
  v2.0.0-validated     # Net-new product added (MAJOR scope expansion)
```

### When to Increment Versions

| Bump | Signals | Triggers |
|------|---------|----------|
| **MAJOR** | Scope expansion or milestone | Net-new product, major feature area, first `ni-validated` release, structural overhaul |
| **MINOR** | Incremental improvements | New controls, new sections, compliance mappings |
| **PATCH** | Editorial/maintenance | Typos, URL fixes, vendor UI changes, clarifications |

### Changelog Tags

Use tags to signal special circumstances (version bump follows normal rules):

| Tag | When to Use | Example |
|-----|-------------|---------|
| `[SECURITY]` | Addresses active/prevalent threat | `[SECURITY] Add L1: Phishing-resistant MFA` |
| `[BREAKING]` | May disrupt existing implementations | `[BREAKING] Remove deprecated OAuth control` |

### Maturity Statuses

Maturity is a **matrix, not a ladder**: three stages (`drafted` -> `reviewed` -> `validated`) crossed with two agents (`ai`, a machine; `ni`, natural intelligence -- a person). Six statuses, and they are **not mutually exclusive** -- a guide holds a set of them, so `maturity` in frontmatter is a list:

```yaml
maturity: ["ai-drafted", "ai-validated"]
```

**What each status asserts -- and, just as importantly, what it does not -- is defined once in [VERSIONS.md](https://github.com/grcengineering/how-to-harden/blob/main/VERSIONS.md#maturity-statuses--the-matrix).** Don't restate it here or in a guide; link to it.

What matters when you are contributing is who is allowed to add each one:

| Status | Who Can Set |
|--------|-------------|
| `ai-drafted` | An AI authoring run. Every AI-written guide starts here. |
| `ni-drafted` | The human author of the content, in the PR that lands it. Authoring is not reviewing — you cannot review your own draft. |
| `ai-reviewed` | An agent review run, recorded in the changelog. Never hand-typed. |
| `ni-reviewed` | Maintainers only, after a named human review. |
| `ai-validated` | Only a [`validate-hth-guide`](https://github.com/grcengineering/how-to-harden/blob/main/.claude/skills/validate-hth-guide/SKILL.md) run, as its close-out step. **Never hand-typed** — the value is a claim that a live tenant was exercised, so typing it without that run is a false claim, not a formatting choice. |
| `ni-validated` | Maintainers only, after a named test on a real system. |

**An `ai-*` status asserts what a machine did and nothing about human judgement.** It never discharges the need for its `ni-*` twin: an agent can prove a console path exists; it cannot judge whether the control is the right control for your organization. Holding both agents at the same stage is the strongest thing the vocabulary can say, and it is the only way "better than AI Validated" is expressed — there is no rung above it to climb to.

**No guide in this repository currently holds any `ni-*` status.** Every one of the 130 guides is `ai-drafted`, two are additionally `ai-validated`, and the entire natural-intelligence half of the matrix is empty. If you are a practitioner reading this, that row is the contribution nobody else can make.

### Author Attribution in Changelog

**Properly attribute all contributions:**

| Author Type | Format | Example |
|-------------|--------|---------|
| Human contributor | GitHub handle or name | `@username`, `Jane Doe` |
| Claude Code | `Claude Code ({model})` | `Claude Code (Opus 4.5)` |
| Other AI tools | `{Tool Name} ({model})` | `GitHub Copilot (GPT-4)` |

### Required Updates for Version Changes

1. **YAML front matter:** Update `version` field
2. **Changelog table:** Add new row with date, version, the full maturity set (` · `-joined), changes, author
3. **VERSIONS.md:** Update the central registry

## Creating a New Guide

### 1. Choose a Platform

Priority platforms that need guides:

- Microsoft 365
- Google Workspace
- Slack
- AWS (integration security focus)
- Azure (integration security focus)

### 2. Use the Template

```bash
cp templates/vendor-guide-template.md docs/_guides/[vendor-name].md
```

### 3. Fill Out All Sections

See the [template usage notes](https://github.com/grcengineering/how-to-harden/blob/main/templates/vendor-guide-template.md#template-usage-notes) for detailed guidance.

### 4. Test Everything

- [ ] Test all ClickOps steps in a real environment
- [ ] Verify all CLI/API commands work
- [ ] Validate compliance mappings against official framework documents
- [ ] Check all external links
- [ ] Verify table formatting (blank lines before/after)

### 5. Set Version and Maturity

For new guides:

- Set `version: "0.1.0"` in YAML front matter
- Set `maturity: ["ai-drafted"]` in YAML front matter (a list, not a string) if an agent wrote it, or `["ni-drafted"]` if you wrote it yourself — **and nothing else, no matter how carefully the guide was researched.** The drafted stage is where authorship lands; every later status is earned by someone else making contact with the product or exercising judgement over the content
- Add initial changelog entry with proper author attribution
- Add guide to VERSIONS.md registry

**Do not hand-add statuses.** `ai-validated` is set only by a `validate-hth-guide` run; `ni-reviewed` and `ni-validated` are set only by maintainers after a named review or test. `scripts/validate-guides.sh` Test 5b rejects anything that is not a list of the six statuses, and rejects a `*-reviewed`/`*-validated` claim that does not rest on a `*-drafted` one — but it cannot tell a promotion that was earned from one that was typed. That part is on you.

### 6. Submit a Pull Request

- Create a descriptive PR title: `Add [Vendor] hardening guide v0.1.0` or `Update [Vendor] guide to v0.2.0: [what changed]`
- Reference any related issues
- Ensure changelog entry is added with proper author attribution

## Pull Request Process

1. **Fork the repository** and create a branch from `main`
2. **Make your changes** following the guidelines above
3. **Test locally** if possible (see [Local Development](#local-development))
4. **Submit a PR** with a clear description of changes
5. **Respond to review feedback** from maintainers
6. **Celebrate!** Your contribution helps the security community

## Local Development

To test the Jekyll site locally:

```bash
# Install dependencies
cd docs
bundle install

# Run local server
bundle exec jekyll serve

# View at http://localhost:4000
```

This allows you to verify that your Markdown renders correctly before submitting a PR.

## Style Guide

### Writing Style

- **Clear and concise:** Security professionals are busy
- **Action-oriented:** Use imperative mood ("Configure X" not "You should configure X")
- **Specific:** Include exact paths, button names, and settings
- **Vendor-neutral:** Focus on security benefits, not vendor marketing

### Code Examples

- **Inline comments:** Explain what each command does
- **Working examples:** Test before submitting
- **Multiple options:** Provide ClickOps, CLI, API, and IaC where applicable
- **Error handling:** Include validation steps

### Security Focus

- **Attack-informed:** Explain what attacks the control prevents
- **Risk-based:** Prioritize by impact and likelihood
- **Real-world examples:** Reference actual incidents when relevant
- **Operational impact:** Document user experience and maintenance burden

## Compliance Mappings

When adding compliance mappings:

1. **Verify against official sources:**
   - [NIST 800-53](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final)
   - [CIS Controls](https://www.cisecurity.org/controls)
   - [ISO 27001](https://www.iso.org/isoiec-27001-information-security.html)

2. **Be specific:** Map to exact control IDs, not just categories

3. **Explain the relationship:** Why does this technical control satisfy the compliance requirement?

## Security Reporting

If you discover a security vulnerability in our automation scripts or recommendations that could actively harm users:

- **DO NOT** open a public GitHub issue
- **Email:** security@howtoharden.com
- **Include:** Detailed description, impact, and suggested fix

For general content corrections or improvements, use GitHub Issues.

## Recognition

All contributors are recognized in:

- Individual guide changelogs
- The project CONTRIBUTORS.md file
- Annual project reports

## Questions?

- **GitHub Discussions:** General questions and ideas
- **GitHub Issues:** Bug reports and feature requests
- **Email:** contribute@howtoharden.com

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for helping make the security community stronger!**

</div>
