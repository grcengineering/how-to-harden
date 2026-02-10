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

### 2. Code Blocks Must Specify Language

Always use: ` ```bash `, ` ```hcl `, ` ```sql `, ` ```python `, etc.

Never use bare ` ``` ` without a language.

### 3. Every Control Needs Both Methods

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

- [ ] Tables have blank lines before AND after
- [ ] Code blocks specify language
- [ ] Both ClickOps and Code implementations provided
- [ ] Compliance mappings verified
- [ ] Changelog updated
