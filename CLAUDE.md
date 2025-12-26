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

## Front Matter Template

```yaml
---
layout: guide
title: "[Vendor] Hardening Guide"
vendor: "Vendor Name"
slug: "vendor-name"
tier: "1"
category: "Identity|Security|DevOps|Data|Productivity|HR/Finance|CRM/Marketing"
description: "Brief description"
last_updated: "YYYY-MM-DD"
---
```

## Control Structure (Abbreviated)

```markdown
### X.Y Control Title

**Profile Level:** L1 | L2 | L3
**CIS Controls:** [IDs]
**NIST 800-53:** [IDs]

#### Description
#### Rationale
#### Prerequisites
#### ClickOps Implementation
#### Code Implementation
#### Validation & Testing
#### Monitoring & Maintenance
#### Operational Impact
#### Compliance Mappings
```

## Compliance Frameworks (in order)

1. CIS Controls
2. NIST 800-53
3. SOC 2
4. ISO 27001
5. PCI DSS
6. DISA STIG (when applicable)

## Profile Levels

- **L1 (Baseline)** - Essential, all organizations
- **L2 (Hardened)** - Security-sensitive environments
- **L3 (Maximum)** - Regulated industries

## Out of Scope

- Infrastructure hardening (use CIS Benchmarks)
- Secret rotation (use howtorotate.com)
- Penetration testing
- Physical security

## Quality Checks Before Commit

- [ ] Tables have blank lines before AND after
- [ ] Code blocks specify language
- [ ] Both ClickOps and Code implementations provided
- [ ] Compliance mappings verified
- [ ] Changelog updated
