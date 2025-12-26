# AI Agent Guidelines for How to Harden

This document provides context and guidelines for AI assistants (Claude Code, Copilot, etc.) working with the How to Harden repository. Follow these patterns to ensure consistency across all contributions.

## Repository Overview

**How to Harden** is a community-driven, open source project providing SaaS security hardening guides with emphasis on:

- **Integration security** - Restricting third-party app access
- **Supply chain attack mitigation** - Limiting damage when vendors are compromised
- **Dual-method implementation** - Both GUI ("ClickOps") and automation ("Code") approaches

**Key insight:** You cannot control your vendors' security, but you can control how much access they have.

---

## Repository Structure

```
how-to-harden/
├── docs/                          # Jekyll site (deployed to GitHub Pages)
│   ├── _config.yml               # Jekyll configuration
│   ├── _guides/                  # Platform-specific hardening guides (53+)
│   ├── _layouts/                 # Jekyll layouts (default.html, guide.html)
│   ├── _includes/                # Reusable components (header.html, footer.html)
│   ├── assets/css/               # Styling
│   ├── index.html                # Homepage with search/filtering
│   ├── about.md                  # About page
│   └── CNAME                     # Custom domain (howtoharden.com)
├── templates/                    # Guide templates
│   └── vendor-guide-template.md  # Master template for new guides
├── references/                   # Compliance references (DISA STIGs)
│   └── DISA/STIGs/
├── CONTRIBUTING.md               # Contribution guidelines
├── PHILOSOPHY.md                 # Scope and design principles
├── AGENTS.md                     # This file - AI assistant guidance
├── README.md                     # Project overview
└── LICENSE                       # MIT License
```

---

## File Naming Conventions

### Guide Files

- **Location:** `docs/_guides/`
- **Pattern:** `{vendor-name}.md` (lowercase, hyphenated)
- **Examples:**
  - `salesforce.md`
  - `azure-devops.md`
  - `ping-identity.md`
  - `hashicorp-vault.md`

### Creating New Guides

```bash
cp templates/vendor-guide-template.md docs/_guides/[vendor-name].md
```

---

## Guide Structure

Every guide MUST follow this structure (see `templates/vendor-guide-template.md`):

### Required Front Matter

```yaml
---
layout: guide
title: "[Vendor Name] Hardening Guide"
vendor: "Vendor Name"
slug: "vendor-name"
tier: "1" or "2"
category: "Identity|Security|DevOps|Data|Productivity|HR/Finance|CRM/Marketing"
description: "Brief description for search results"
last_updated: "YYYY-MM-DD"
---
```

### Required Sections (in order)

1. **Header** - Version, last updated, editions covered, authors
2. **Overview** - Brief description, audience, how to use, scope
3. **Table of Contents** - Links to all sections
4. **Authentication & Access Controls** - MFA, SSO, RBAC, sessions
5. **Network Access Controls** - IP allowlisting, login restrictions
6. **OAuth & Integration Security** - Connected apps, API scoping
7. **Data Security** - Encryption, DLP, field-level controls
8. **Monitoring & Detection** - Event logging, anomaly detection
9. **Third-Party Integration Security** - Integration risk matrix
10. **Compliance Quick Reference** - SOC 2, NIST, ISO, PCI mappings
11. **Appendices** - Edition compatibility, references, changelog

### Control Structure

Each control follows this pattern:

```markdown
### X.Y Control Title

**Profile Level:** L1 (Baseline) | L2 (Hardened) | L3 (Maximum Security)
**CIS Controls:** [Control IDs]
**NIST 800-53:** [Control IDs]
**DISA STIG:** [Control IDs if applicable]

#### Description
[2-3 sentences of WHAT to configure]

#### Rationale
**Why This Matters:**
- [Security benefit]

**Attack Prevented:** [Attack type]

**Real-World Incidents:**
- **[Incident Name] ([Date]):** [How this control would have helped]

#### Prerequisites
- [ ] [Access/permissions needed]
- [ ] [Product edition required]

#### ClickOps Implementation
**Step 1: [Action]**
1. Navigate to: [Exact path]
2. [Detailed GUI steps]

**Time to Complete:** ~X minutes

#### Code Implementation
**Option 1: CLI**
```bash
# Commands with inline comments
```

**Option 2: API**
```bash
curl -X METHOD "url" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{...}'
```

**Option 3: Terraform**
```hcl
resource "vendor_type" "name" {
  setting = "value"
}
```

#### Validation & Testing
**How to verify the control is working:**
1. [ ] [Test step]

**Expected result:** [Success criteria]

#### Monitoring & Maintenance
**Ongoing monitoring:**
- [What to monitor]

**Maintenance schedule:**
- **Monthly:** [Task]
- **Quarterly:** [Task]
- **Annually:** [Task]

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|---------|
| **User Experience** | None/Low/Medium/High | [Description] |
| **System Performance** | None/Low/Medium/High | [Description] |
| **Maintenance Burden** | Low/Medium/High | [Effort] |
| **Rollback Difficulty** | Easy/Moderate/Complex | [How to undo] |

**Potential Issues:**
- [Issue]: [Mitigation]

**Rollback Procedure:**
[Steps to disable if needed]

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | [ID] | [Description] |
| **NIST 800-53** | [ID] | [Description] |
| **ISO 27001** | [ID] | [Description] |
| **PCI DSS** | [ID] | [Description] |
```

---

## Critical Formatting Requirements

### Tables - MUST Have Blank Lines

**This is the #1 cause of broken rendering on the Jekyll site.**

```markdown
<!-- CORRECT - Tables render properly -->
**Some text here**

| Column 1 | Column 2 |
|----------|----------|
| Value 1  | Value 2  |

Next paragraph here.

<!-- INCORRECT - Tables will NOT render -->
**Some text here**
| Column 1 | Column 2 |
|----------|----------|
| Value 1  | Value 2  |
Next paragraph here.
```

### Code Blocks - Always Specify Language

```markdown
<!-- CORRECT -->
```bash
echo "Hello"
```

```hcl
resource "aws_instance" "example" {}
```

```sql
SELECT * FROM users;
```

<!-- INCORRECT -->
```
echo "Hello"
```
```

### Other Formatting Rules

| Rule | Correct | Incorrect |
|------|---------|-----------|
| Bold text | `**bold**` | `__bold__` |
| Heading hierarchy | Don't skip levels (## → ###) | ## → #### |
| List markers | Consistent (`-` or `*`) | Mixed |
| Emphasis | Proper Markdown syntax | HTML tags |

---

## Compliance Framework Mappings

Every control must map to these frameworks (in this order):

1. **CIS Controls** - e.g., 6.3, 6.5, 5.1
2. **NIST 800-53** - e.g., IA-2, AC-3, SC-7, AU-2
3. **SOC 2** - e.g., CC6.1, CC6.2, CC7.1
4. **ISO 27001** - e.g., A.9.4.1, A.12.4.1
5. **PCI DSS** - e.g., 1.3, 2.2, 8.3
6. **DISA STIG** - When applicable (e.g., VID-XXXXX)

**Verification sources:**
- [NIST 800-53 Rev 5](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final)
- [CIS Controls v8](https://www.cisecurity.org/controls)
- [ISO 27001:2022](https://www.iso.org/isoiec-27001-information-security.html)

---

## Real-World Incident References

Include actual incidents in Rationale sections to justify controls:

**Commonly Referenced:**
- **Salesloft/Drift breach (Aug 2025)** - 700+ orgs compromised via OAuth tokens
- **Gainsight breach (Nov 2025)** - Salesforce integration compromise
- **Okta support breach (Oct 2023)** - HAR file token theft
- **CircleCI breach (Jan 2023)** - Developer secrets exposed
- **Snowflake breach (2024)** - Customer data exfiltration

**Format:**
```markdown
**Real-World Incidents:**
- **Okta support breach (Oct 2023):** FIDO2 MFA would have prevented token theft from HAR files since phishing-resistant authenticators don't expose replayable credentials.
```

---

## Integration-Specific Controls

When documenting IP allowlisting or network controls for specific integrations:

```markdown
#### 2.1.1 IP Allowlisting: Restricting [Vendor Integration Name]

**Integration Name:** [Vendor Product]
**Data Access Level:** High | Medium | Low
**IP Addresses:** (verified YYYY-MM-DD)
- `X.X.X.X/32`
- `Y.Y.Y.Y/32`

**Source:** [Link to vendor's official IP documentation]

**Implementation:** [Reference parent section's ClickOps/Code methods with these specific IPs]

**Monitoring:** [Queries to detect traffic from non-allowlisted IPs]
```

Always include:
- Verification date for IP addresses
- Link to vendor's official documentation
- Data access level assessment

---

## Profile Levels

Use consistent terminology:

| Level | Name | Description |
|-------|------|-------------|
| **L1** | Baseline | Essential controls for all organizations |
| **L2** | Hardened | Enhanced controls for security-sensitive environments |
| **L3** | Maximum Security | Strictest controls for regulated industries |

---

## Common Tasks

### Adding a New Platform Guide

1. Copy template: `cp templates/vendor-guide-template.md docs/_guides/[vendor-name].md`
2. Fill in front matter with correct category
3. Complete ALL sections (don't leave placeholders)
4. Provide BOTH ClickOps AND Code implementations
5. Test all commands in a real environment
6. Verify compliance mappings against official sources
7. Include real-world incident examples
8. Add changelog entry

### Adding a New Control to Existing Guide

1. Follow the exact control structure template
2. Place in the appropriate section (1-7)
3. Use next sequential numbering (e.g., 1.3 → 1.4)
4. Include all sub-sections (Description through Compliance Mappings)
5. Add both ClickOps and Code implementations
6. Update changelog

### Adding Integration-Specific IP Allowlisting

1. Add as sub-section under Network Access Controls (Section 2)
2. Use format: `#### 2.X.Y IP Allowlisting: Restricting [Vendor Name]`
3. Include verified IP addresses with date
4. Link to vendor's official IP documentation
5. Assess data access level (High/Medium/Low)

### Updating Compliance Mappings

1. Verify against official framework documents (linked above)
2. Use exact control IDs, not categories
3. Include brief control description
4. Map to ALL applicable frameworks

---

## Quality Checklist

Before submitting any changes:

- [ ] All ClickOps steps tested in real environment
- [ ] All Code examples (CLI, API, IaC) verified working
- [ ] Compliance mappings verified against official sources
- [ ] All external links verified (not broken)
- [ ] Real-world incident examples included with sources
- [ ] **Tables have blank lines before AND after** (critical!)
- [ ] Code blocks specify language
- [ ] Heading hierarchy is consistent (no skipped levels)
- [ ] Changelog updated with date, version, changes, author

---

## What's IN Scope

- Integration security controls (OAuth, Connected Apps, API restrictions)
- Supply chain attack mitigation
- Cross-platform defensive patterns
- SaaS authentication/authorization hardening
- Data access controls
- Monitoring and detection for API activity

## What's OUT of Scope

- Infrastructure hardening (use CIS Benchmarks for AWS/Azure/GCP)
- Secret rotation (use howtorotate.com)
- Vendor security assessments
- Penetration testing techniques
- Physical security
- Self-hosted infrastructure configuration

---

## Categories

Valid categories for guide front matter:

| Category | Examples |
|----------|----------|
| Identity | Okta, Ping Identity, SailPoint |
| Security | CrowdStrike, CyberArk, Wiz, Snyk |
| DevOps | GitHub, GitLab, CircleCI, Terraform Cloud |
| Data | Snowflake, Databricks, Datadog, Splunk |
| Productivity | Zoom, Notion, Asana, Miro |
| HR/Finance | Workday, BambooHR, NetSuite, ADP |
| CRM/Marketing | Salesforce, HubSpot, Zendesk |

---

## Local Development

To test changes locally:

```bash
cd docs
bundle install
bundle exec jekyll serve
# View at http://localhost:4000
```

---

## Key Files to Reference

| Purpose | File |
|---------|------|
| Guide template | `templates/vendor-guide-template.md` |
| Contribution guidelines | `CONTRIBUTING.md` |
| Project philosophy/scope | `PHILOSOPHY.md` |
| Jekyll config | `docs/_config.yml` |
| Example well-structured guide | `docs/_guides/okta.md` |

---

## Design Principles

1. **Relational over Isolated** - Show platform interactions, not just individual hardening
2. **Attack-Informed over Compliance-Driven** - Prioritize by real attacks
3. **Actionable over Theoretical** - Every recommendation includes audit + remediation
4. **Dual-Method Approach** - Both ClickOps (GUI) and Code (automation)
5. **Vendor-Neutral but Vendor-Informed** - Independent but accurate

---

## Changelog for This File

| Date | Changes | Author |
|------|---------|--------|
| 2025-12-26 | Initial creation | Claude Code |
