# [Vendor Name] [Product Name] Hardening Guide

**Version:** v0.1.0-draft
**Last Updated:** YYYY-MM-DD
**Maturity:** Draft (AI-generated, pending human review)
**Product Editions Covered:** [List supported tiers/editions]
**Authors:** How to Harden Community

---

## Overview

Brief description of the product and why hardening it matters for security.

### Intended Audience
- Security engineers
- IT administrators
- GRC professionals
- Third-party risk managers

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries (healthcare, finance, government)

### Scope
What this guide covers and what it doesn't.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Network Access Controls](#2-network-access-controls)
3. [OAuth & Integration Security](#3-oauth--integration-security)
4. [Data Security](#4-data-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Third-Party Integration Security](#6-third-party-integration-security)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 [Control Title - e.g., "Enforce Multi-Factor Authentication"]

**Profile Level:** L1 (Baseline) | L2 (Hardened) | L3 (Maximum Security)
**CIS Controls:** [Control IDs if applicable]
**NIST 800-53:** [Control IDs if applicable]

#### Description
[2-3 sentences describing WHAT to configure]

#### Rationale
**Why This Matters:**
- [Security benefit]
- [Risk if not implemented]

**Attack Prevented:** [Type of attack this mitigates]

**Real-World Incidents:**
- [Incident name/date]: [How this control would have helped]

#### Prerequisites
- [ ] [Access/permissions needed]
- [ ] [Product edition/tier required]
- [ ] [Information to gather]

#### ClickOps Implementation

**Step 1: [Action]**
1. Navigate to: [Exact path in console/UI]
2. [Specific actions with screenshots or detailed descriptions]

**Step 2: [Action]**
1. [Detailed steps]

**Time to Complete:** ~X minutes

#### Code Implementation

**Option 1: CLI**
```bash
# Commands with inline comments
# explaining what each does
```

**Option 2: API**
```bash
# curl or other API client examples
curl -X POST "https://api.example.com/endpoint" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "setting": "value"
  }'
```

**Option 3: Terraform**
```hcl
# Terraform configuration
resource "vendor_resource_type" "name" {
  setting = "value"
}
```

**Option 4: Script (Python/etc.)**
```python
# Automation script
# automation/scripts/vendor/script-name.py
```

#### Validation & Testing
**How to verify the control is working:**
1. [ ] [Test step 1]
2. [ ] [Test step 2]

**Expected result:** [What success looks like]

#### Monitoring & Maintenance
**Ongoing monitoring:**
- [What to monitor for control drift or bypass]
- [Log queries or alert configurations]

**Maintenance schedule:**
- **Monthly:** [Review task]
- **Quarterly:** [Review task]
- **Annually:** [Deeper review]

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | [None/Low/Medium/High] | [Description] |
| **System Performance** | [None/Low/Medium/High] | [Description] |
| **Maintenance Burden** | [Low/Medium/High] | [Ongoing effort] |
| **Rollback Difficulty** | [Easy/Moderate/Complex] | [How to undo] |

**Potential Issues:**
- [Issue 1]: [Description and mitigation]

**Rollback Procedure:**
[Quick steps to disable if needed]

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | [ID] | [Description] |
| **NIST 800-53** | [ID] | [Description] |
| **ISO 27001** | [ID] | [Description] |
| **PCI DSS** | [ID] | [Description] |

---

### 1.2 [Next Control in Same Category]

[Repeat same structure]

---

## 2. Network Access Controls

### 2.1 [Control Title - e.g., "Restrict API Access via IP Allowlisting"]

[Same detailed structure as 1.1]

#### 2.1.1 [Sub-section for Specific Integration - e.g., "IP Allowlisting: Restricting [Integration Name]"]

**This is where integration-specific hardening goes.**

**Integration Name:** [Vendor Integration Product]
**Data Access Level:** [High/Medium/Low]
**IP Addresses:** (verified YYYY-MM-DD)
- `X.X.X.X/32`
- `Y.Y.Y.Y/32`

**Source:** [Link to vendor documentation]

**Implementation:** [Follow parent section's ClickOps/Code methods, with these specific IPs]

**Monitoring:** [Specific queries for this integration]

---

#### 2.1.2 [Another Integration - e.g., "IP Allowlisting: Restricting [Different Integration]"]

[Repeat structure]

---

## 3. OAuth & Integration Security

### 3.1 [Control Title]

[Standard structure]

---

## 4. Data Security

### 4.1 [Control Title]

[Standard structure]

---

## 5. Monitoring & Detection

### 5.1 [Control Title - e.g., "Enable Event Logging for API Activity"]

[Standard structure]

**Detection Use Cases:**

**Anomaly 1: [Specific Attack Pattern]**
```sql
-- Query to detect this anomaly
SELECT ...
```

**Anomaly 2: [Another Pattern]**
```sql
-- Query
```

---

## 6. Third-Party Integration Security

### 6.1 Integration Risk Assessment Matrix

Table showing how to assess third-party integration risk:

| Risk Factor | Low | Medium | High |
|-------------|-----|--------|------|
| **Data Access** | Read-only, limited | Read most data | Write access, full API |
| **OAuth Scopes** | Specific scopes | Broad API access | Full/admin access |
| **Session Duration** | <2 hours | 2-8 hours | >8 hours, persistent |
| **IP Restriction** | Static IPs available | Some static IPs | Dynamic, no allowlist |
| **Vendor Security** | SOC 2 Type II | SOC 2 Type I | No certification |

**Decision Matrix:**
- **0-5 points:** Approve with standard controls
- **6-10 points:** Approve with enhanced monitoring
- **11-15 points:** Require additional security measures or reject

### 6.2 Common Integrations and Recommended Controls

#### [Integration 1 Name]

**Data Access:** [High/Medium/Low]
**Recommended Controls:**
- ✅ [Control from this guide]
- ✅ [Another control]
- ⚠️ [Note if integration has known security issues]

#### [Integration 2 Name]

[Repeat structure]

---

## 7. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | [Product] Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | [Control name] | [Section] |
| CC6.2 | [Control name] | [Section] |

### NIST 800-53 Rev 5 Mapping

| Control | [Product] Control | Guide Section |
|---------|------------------|---------------|
| AC-3 | [Control name] | [Section] |
| IA-2(1) | [Control name] | [Section] |

### ISO 27001:2022 Mapping

[Similar table]

### PCI DSS v4.0 Mapping

[Similar table]

---

## Appendix A: Edition/Tier Compatibility

| Control | [Free/Starter] | [Professional] | [Enterprise] | [Premium] | Add-on Required |
|---------|---------------|----------------|--------------|-----------|-----------------|
| [Control 1] | ✅/❌ | ✅/❌ | ✅/❌ | ✅/❌ | Yes/No |
| [Control 2] | ✅/❌ | ✅/❌ | ✅/❌ | ✅/❌ | Yes/No |

---

## Appendix B: References

**Official [Vendor] Documentation:**
- [Link to security documentation]
- [Link to API reference]
- [Link to admin guide]

**Integration Vendor Documentation:**
- [Vendor 1 IP Addresses] (link)
- [Vendor 2 Security Setup] (link)

**Supply Chain Incident Reports:**
- [Incident post-mortem link]
- [Security researcher analysis link]

**Community Resources:**
- [Relevant blog posts]
- [Security tools for this platform]

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| YYYY-MM-DD | 0.1.0 | draft | Initial guide | [Author - see guidelines below] |

### Author Attribution Guidelines

Use the appropriate format for the Author column:

| Author Type | Format | Example |
|-------------|--------|---------|
| Human contributor | GitHub handle or name | `@username`, `Jane Doe` |
| Claude Code | `Claude Code ({model})` | `Claude Code (Opus 4.5)` |
| Other AI tools | `{Tool Name} ({model})` | `GitHub Copilot (GPT-4)` |
| Community (legacy) | `How to Harden Community` | For pre-versioning entries |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/yourproject/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/yourproject/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [CONTRIBUTING.md](../../CONTRIBUTING.md)

---

**Questions or feedback?**
- GitHub Discussions: [Link]
- GitHub Issues: [Link]

---

## Template Usage Notes

**When creating a new vendor guide:**

1. Copy this template to `content/[vendor]/[product] hardening guide.md`
2. Replace all `[Vendor]`, `[Product]` placeholders
3. Fill in ALL sections (don't leave TODOs)
4. Provide BOTH ClickOps and Code implementations for each control
5. Test all commands/scripts in a real environment before submitting
6. Map to compliance frameworks (SOC 2, NIST, ISO at minimum)
7. Include real-world attack examples in Rationale sections
8. Create corresponding automation scripts in `automation/scripts/[vendor]/`
9. Update `README.md` to add your guide to the project structure

**Section Priority:**

- **Must Have:**
  - Controls 1-3 in each category (prioritize by attack relevance)
  - ClickOps AND Code implementations
  - Compliance mappings
  - Edition/tier compatibility table

- **Should Have:**
  - Controls 4+ in each category
  - Monitoring queries
  - Integration risk assessment
  - Common integrations section

- **Nice to Have:**
  - Advanced controls (L3)
  - Third-party tool integrations
  - Detailed troubleshooting

**Versioning Requirements:**

HTH uses Extended SemVer with Maturity Qualifiers, aligned with [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks). See [VERSIONS.md](../VERSIONS.md) for full documentation.

- **YAML Front Matter:** Include `version` and `maturity` fields:
  ```yaml
  ---
  layout: guide
  title: "[Vendor] Hardening Guide"
  vendor: "[Vendor]"
  version: "0.1.0"
  maturity: "draft"  # draft | reviewed | verified
  last_updated: "YYYY-MM-DD"
  ---
  ```

- **Version Increments:**
  - MAJOR: Scope expansion (net-new product, major feature area, first verified release)
  - MINOR: Incremental improvements (new controls, new sections)
  - PATCH: Editorial (typos, URL fixes, vendor UI changes)

- **Changelog Tags:** Use `[SECURITY]` for critical additions, `[BREAKING]` for disruptive changes

- **Maturity Levels:**
  - `draft`: AI-generated or unreviewed
  - `reviewed`: SME-validated content
  - `verified`: Production-tested controls

- **Changelog Entry:** Every version change requires a changelog entry with proper author attribution

**Quality Checklist:**

- [ ] Tested all ClickOps steps in real product environment
- [ ] Tested all Code examples (CLI, API, IaC all work)
- [ ] Compliance mappings verified against official framework documents
- [ ] Links to vendor documentation verified (not broken)
- [ ] Real-world incident examples included and sourced
- [ ] Integration-specific controls include current vendor IPs/settings with verification date
- [ ] At least 2 reviewers with hands-on product experience
- [ ] All Markdown tables have blank lines before and after them (required for Jekyll rendering)
- [ ] Version number updated in YAML front matter and changelog
- [ ] VERSIONS.md registry updated with new version

**Markdown Formatting Requirements:**

⚠️ **CRITICAL for Jekyll/Website Rendering:**

**Tables:** MUST have a blank line before and after each table. Without this, tables will not render properly on the website.

**Correct:**
```markdown
**Some text here**

| Column 1 | Column 2 |
|----------|----------|
| Value 1  | Value 2  |

Next paragraph here.
```

**Incorrect (will break on website):**
```markdown
**Some text here**
| Column 1 | Column 2 |
|----------|----------|
| Value 1  | Value 2  |
Next paragraph here.
```

**Other formatting guidelines:**
- Use `**bold**` for emphasis, not `__bold__`
- Use consistent heading levels (don't skip from ## to ####)
- Code blocks must specify language for syntax highlighting
- Use proper emoji syntax where applicable (✅ ❌ ⚠️)
