# Philosophy and Scope

## The Problem We're Solving

**Third-party risk management in information security is fundamentally broken.**

Organizations conduct vendor security assessments, review SOC 2 reports, and add vendors to risk registers—but still get breached when those vendors are compromised. The Salesloft/Drift supply chain attack (August 2025) compromised **700+ organizations** including major cybersecurity vendors, despite many victims having conducted thorough vendor assessments of Salesloft and Drift.

Traditional third-party risk management asks: *"Is this vendor secure?"*

**We ask a better question:** *"What first-party controls can I implement to limit the damage when this vendor gets compromised?"*

## Our Core Insight

**You cannot control your vendors' security posture, but you can control how much access they have.**

When Okta was targeted in the Salesloft/Drift attack, they were protected—not because Salesloft was more secure for them, but because **Okta had configured their own Salesforce instance** to restrict API access via IP allowlisting. When attackers used stolen OAuth tokens to access victim Salesforce instances, Okta's requests were blocked because they originated from infrastructure IPs Okta hadn't allowlisted.

This is the defensive paradigm we're building:

> **First-party controls** (configurations you control) that mitigate **third-party risks** (vendors you don't control).

## What This Project Provides

How to Harden is a community-driven, open source guide to **SaaS security hardening with emphasis on integration security and supply chain attack mitigation**.

### Vendor-Organized Comprehensive Guides

Like CIS Benchmarks, we organize hardening guidance by **vendor/product** (Salesforce, Microsoft 365, GitHub, etc.). Each guide is a comprehensive document covering multiple control categories:

- **Authentication & Access Controls** (MFA, SSO, session management)
- **Network Access Controls** (IP allowlisting, login restrictions)
- **OAuth & Integration Security** (Connected Apps, API scoping)
- **Data Security** (encryption, DLP, field-level controls)
- **Monitoring & Detection** (event logs, anomaly detection)
- **Third-Party Integration Security** (vendor-specific hardening)

### Our Unique Contribution: Integration-Focused Controls

Within each vendor guide, we emphasize **how to configure that platform to restrict third-party integrations**. Examples:

- **Salesforce guide** includes: "How to IP-allowlist Gainsight/Drift/HubSpot API access"
- **GitHub guide** includes: "How to restrict third-party Actions workflows"
- **Microsoft 365 guide** includes: "How to limit OAuth app permissions for Zoom/Slack"

This relational approach—configuring Platform A to limit Platform B's access when B is compromised—doesn't exist in CIS Benchmarks or vendor documentation.

### Supply Chain Attack Analysis

Each guide references **real-world incidents** where controls would have prevented or limited attacks:
- Salesforce guide → Drift/Gainsight breaches, Okta's successful defense
- GitHub guide → CircleCI breach, CodeCov compromise
- Microsoft 365 guide → OAuth token theft campaigns

## What We Are NOT

To keep this project focused and sustainable, we explicitly exclude:

**❌ Infrastructure hardening** - Use CIS Benchmarks for AWS, Azure, GCP, Kubernetes, etc.

**❌ Secret rotation procedures** - Use [howtorotate.com](https://howtorotate.com) for post-breach remediation

**❌ Vendor security assessments** - We don't rate vendor security; we help you limit exposure

**❌ Compliance-first guidance** - Compliance mappings are included, but controls are prioritized by **attack relevance**, not audit requirements

**❌ Penetration testing** - We document defensive configurations, not offensive techniques

## Scope Definition: What Belongs in This Project?

A hardening recommendation belongs here if it meets **at least one** of these criteria:

### Primary Criteria (High Priority)
- **Integration security controls** - Configurations that restrict third-party integrations, OAuth apps, API access, or connected applications
- **Supply chain attack mitigation** - Controls that limit damage when a vendor/integration is compromised
- **Cross-platform defensive patterns** - Guidance requiring coordination between multiple SaaS platforms

### Secondary Criteria (Include If Relevant)
- **Authentication/authorization hardening** specific to SaaS platforms (MFA, session management, conditional access)
- **Data access controls** that limit breach radius (least privilege, DLP, encryption)
- **Monitoring and detection** for anomalous API activity or integration behavior

### Examples of In-Scope Content
✅ IP allowlisting for Salesforce Connected Apps (integration control)
✅ GitHub Actions third-party workflow restrictions (supply chain control)
✅ Microsoft 365 OAuth consent policies (integration governance)
✅ Slack workspace app approval workflows (third-party app control)
✅ Okta sign-on policies for SaaS applications (conditional access)

### Examples of Out-of-Scope Content
❌ AWS VPC security group configurations (infrastructure, not SaaS)
❌ Database encryption at rest (infrastructure layer)
❌ How to rotate a leaked API key (covered by howtorotate.com)
❌ Physical security controls
❌ Employee security awareness training

**Gray areas** (case-by-case): Developer tools (GitHub, GitLab, Jira) blur SaaS/infrastructure lines. We include **application-level** hardening (OAuth apps, third-party integrations, API access controls) but exclude infrastructure hardening (self-hosted runner security, Kubernetes configurations for GitLab).

## Target Audiences

We optimize for three personas with different needs:

### Security Engineers / Cloud Security Teams
**Needs:** Technical depth, automation, CLI/API examples, IaC templates
**Workflow:** Audit → Configure → Enforce → Monitor
**Integration points:** CSPM/SSPM tools, IaC scanners, CI/CD pipelines

### GRC Professionals / Compliance Teams
**Needs:** Compliance framework mappings, audit procedures, evidence collection
**Workflow:** Assess → Document → Remediate → Report
**Integration points:** GRC platforms, audit workpapers, risk registers

### IT Administrators / SaaS Admins
**Needs:** Simple checklists, GUI-based instructions, clear prioritization
**Workflow:** Identify → Implement → Verify
**Integration points:** Admin consoles, vendor support documentation

**Our documentation serves all three** via structured format (Description, Rationale, Audit Procedure, Remediation) in multiple formats (Markdown, YAML, interactive checklists).

## Design Principles

### 1. Relational Over Isolated
We emphasize how controls across platforms work together, not just individual platform hardening.

**Bad:** "Enable Salesforce IP allowlisting" (platform-specific, no context)
**Good:** "Restrict Gainsight's Salesforce API access via IP allowlisting" (relational, shows interaction)

### 2. Attack-Informed Over Compliance-Driven
We prioritize controls based on **real attack patterns**, not just audit requirements.

Compliance mappings are provided (SOC 2, NIST 800-53, etc.) but recommendations are ordered by:
1. Recent supply chain attacks (e.g., Drift/Gainsight)
2. Common attack patterns (OAuth token abuse, credential theft)
3. Blast radius reduction (limit damage when breach occurs)

### 3. Actionable Over Theoretical
Every recommendation includes:
- **Audit procedure** - How to check current state (ClickOps and Code methods)
- **Remediation steps** - GUI method ("ClickOps"), CLI/API method, and IaC example ("Code")
- **Operational impact** - What might break, rollback procedure

**Dual-Method Approach:**
We provide **both "ClickOps" (GUI-based) and "Code" (automation-based)** implementations for every control:

- **ClickOps** = Console/GUI-based configuration with screenshots
  - For IT admins without IaC expertise
  - For quick manual implementation
  - For organizations early in DevOps maturity

- **Code** = CLI commands, API calls, IaC templates (Terraform, scripts)
  - For security engineers who need repeatability
  - For drift detection and enforcement
  - For organizations with mature automation

This dual approach makes guides accessible to **all organizations regardless of technical maturity**.

We avoid abstract guidance like "implement least privilege" without specifics.

### 4. Vendor-Neutral But Vendor-Informed
We maintain independence from vendors while incorporating their security capabilities accurately.

- We don't require vendor approval for content
- We welcome vendor engineer contributions (with attribution)
- We correct documentation based on vendor product updates
- We call out when vendor defaults are insecure

### 5. Community-Driven Quality
Like CIS Benchmarks, we use **consensus-based development**:
- Recommendations require multiple reviewer approvals
- Breaking changes (e.g., deprecating a control) need community discussion
- Real-world testing before merging (ideally 2+ organizations validate)

## Governance Model

**Maintainer Structure:**
- 2-3 co-leads from different organizations (reduces single-vendor bias, increases truck factor)
- Contributor → Reviewer → Maintainer progression based on sustained involvement
- Meritocratic decision-making (technical merit over organizational affiliation)

**Content Review:**
- All new recommendations require 2+ reviewer approvals
- At least one reviewer must have hands-on experience with the platform
- Quarterly content review cycle to catch outdated guidance

**Versioning:**
- Individual platform guides have version numbers tied to platform updates
- Defensive pattern guides versioned independently
- Machine-readable data (YAML) follows semantic versioning

**Conflict Resolution:**
- Technical disagreements resolved by majority vote among maintainers
- Security vs. usability tradeoffs documented explicitly (L1 baseline vs. L2 hardened profiles)

## Success Metrics

We measure impact through:

**Adoption Metrics:**
- GitHub stars, forks, contributors (community health)
- Downloads / page views (reach)
- Tool integrations (CSPM/SSPM vendors using our data)

**Content Quality:**
- Platform coverage (% of top 50 SaaS platforms with guides)
- Defensive pattern coverage (% of common integration pairs documented)
- Freshness (% of guides updated within last 6 months)

**Community Engagement:**
- Contributors per quarter
- Organizations represented among contributors
- Issue/PR velocity

**Real-World Impact (Self-Reported):**
- "I used this guide to harden X" testimonials
- Blog posts / conference talks referencing project
- Incident post-mortems citing preventive controls from our guides

## Long-Term Vision

**Phase 1 (Months 1-6):** Foundation + Proof of Concept
- Core governance documents (this file, CONTRIBUTING.md, GOVERNANCE.md)
- One comprehensive platform guide (Salesforce)
- One cross-platform defensive pattern (IP allowlisting)
- One incident case study (Drift attack)

**Phase 2 (Months 7-12):** Expansion + Tooling
- Top 5 platform guides (Salesforce, Microsoft 365, GitHub, Google Workspace, Slack)
- 3-5 defensive patterns (IP allowlisting, OAuth scoping, certificate auth)
- CLI tool for stack analysis (`how-to-harden analyze`)
- CSPM/SSPM vendor partnerships

**Phase 3 (Year 2+):** Ecosystem Integration
- 15+ platform guides covering most enterprise SaaS
- Defensive pattern matrix for common integration pairs
- CI/CD integrations (GitHub Actions, GitLab CI)
- Annual "State of SaaS Security" research report

**Ultimate Goal:** When a security practitioner evaluates a new SaaS vendor, their first question is: *"What How to Harden controls should I implement to limit our exposure?"*

---

## Contributing to This Philosophy

This document defines project scope and principles. If you believe something is missing or incorrect, please:

1. Open an issue with tag `philosophy`
2. Provide rationale for the change
3. Include real-world examples if suggesting scope expansion
4. Be prepared for community discussion

**Major changes** (e.g., expanding scope beyond SaaS, changing target audiences) require maintainer consensus.

Last updated: 2025-12-12
Maintainers: [To be defined]
