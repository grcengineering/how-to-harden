# How to Harden: SaaS Security Hardening Guides

> Community-developed, open source security hardening guides focused on **integration security and supply chain attack prevention**. Like CIS Benchmarks, but for SaaS platforms, free, and uniquely focused on cross-platform integration controls.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Guides: 116](https://img.shields.io/badge/Guides-116-blueviolet)](https://howtoharden.com)
[![Code Packs: 61](https://img.shields.io/badge/Code%20Packs-61-orange)](packs/)

**Website:** [howtoharden.com](https://howtoharden.com) | **Organization:** [GRC Engineering](https://grc.engineering)

---

## The Problem

**Third-party risk management in InfoSec is fundamentally broken.**

In August 2025, the **Salesloft/Drift supply chain attack** compromised 700+ organizations including Cloudflare, Palo Alto Networks, and Zscaler. Three months later, **Gainsight** was breached the same way, affecting 200+ more organizations including F5, GitLab, and CrowdStrike.

Victims had conducted vendor security assessments. They had reviewed SOC 2 reports. They still got breached.

**What worked?** Organizations like **Okta** that had configured **their own Salesforce instances** to restrict API access via IP allowlisting. When attackers used stolen OAuth tokens, Okta's requests were blocked because they originated from IPs Okta hadn't allowlisted.

This is defense-in-depth done right: **First-party controls you configure** to limit damage **when third-party vendors get compromised**.

---

## What We Provide

### 1. Platform-Specific Hardening Guides

Like CIS Benchmarks, but free, vendor-neutral, and focused on integration controls. Currently **116 guides** across 9 categories:

| Category | Count | Examples |
|----------|-------|---------|
| Productivity | 23 | Slack, Airtable, Asana, Notion |
| Security | 21 | CrowdStrike, Snyk, Wiz, Zscaler |
| Data | 17 | Snowflake, Databricks, MongoDB Atlas |
| DevOps | 16 | GitHub, GitLab, Jenkins, Terraform Cloud |
| Identity | 13 | Okta, Auth0, Microsoft Entra ID, Duo |
| HR/Finance | 11 | BambooHR, ADP, Workday, Stripe |
| Marketing | 9 | HubSpot, Braze, SendGrid, Twilio |
| IT Operations | 4 | ServiceNow, Jamf, PagerDuty |
| IaC | 2 | Terraform Cloud, Pulumi |

Every control includes:
- **ClickOps** (GUI/console) steps for manual implementation
- **Code** (CLI/API/IaC) for automation and repeatability
- Three profile levels: **L1** (Baseline), **L2** (Hardened), **L3** (Maximum Security)
- Compliance mappings to SOC 2, NIST 800-53, ISO 27001, and PCI DSS

### 2. Code Packs -- Executable Security Controls

**61 vendor Code Packs** turn guide controls into runnable code. Each pack provides multiple language types:

| Language Type | Directory | What It Does |
|---------------|-----------|-------------|
| Config-as-Code | `terraform/` | Terraform modules to enforce controls declaratively |
| API Scripts | `api/` | bash + curl + jq against vendor REST APIs |
| CLI Scripts | `cli/` | Vendor-native CLIs (`gh`, `okta`, `gcloud`, `az`) |
| SDK Scripts | `sdk/` | Python, PowerShell, Go vendor SDK integrations |
| DB Queries | `db/` | SQL queries for Snowflake, Databricks, MongoDB |
| Detection Rules | `siem/sigma/` | Sigma rules (convert to Splunk, Elastic, Sentinel) |

Code Packs are profile-level gated -- set `HTH_PROFILE_LEVEL=1` for baseline, `2` for hardened, or `3` for maximum security. See [packs/README.md](packs/README.md) for the full Code Pack Ontology.

### 3. Integration-Focused Controls (Our Unique Value)

Within each vendor guide, we emphasize **how to configure that platform to restrict third-party integrations**:

- **Salesforce:** IP-allowlist Gainsight, Drift, and HubSpot API access
- **GitHub:** Restrict third-party Actions workflows and OAuth app permissions
- **Microsoft 365:** Limit OAuth app permissions for Zoom/Slack integrations

This integration security focus doesn't exist in CIS Benchmarks or vendor documentation.

### 4. Supply Chain Incident Case Studies

Real-world attacks (Drift, Gainsight, CircleCI, Okta) mapped to specific preventive controls that would have blocked or limited the attack.

---

## Quick Start

### Browse Online

Visit [howtoharden.com](https://howtoharden.com) to search, filter, and read all guides.

### Run Locally

```bash
git clone https://github.com/grcengineering/how-to-harden
cd how-to-harden/docs
bundle install
bundle exec jekyll serve
# Open http://localhost:4000
```

### Use a Code Pack

```bash
cd packs/okta/terraform
export HTH_PROFILE_LEVEL=2
terraform init && terraform plan
```

### For Contributors

See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- How to propose new platform guides
- How to add Code Pack implementations
- Template structure and quality standards

---

## Project Structure

```
how-to-harden/
├── docs/                                 # Jekyll documentation site
│   ├── _config.yml                       # Jekyll configuration
│   ├── Gemfile                           # Ruby dependencies
│   ├── CNAME                             # Custom domain (howtoharden.com)
│   ├── index.html                        # Homepage with search, filter, sort
│   ├── about.md                          # About page
│   ├── _guides/                          # Platform hardening guides (116 guides)
│   │   ├── salesforce.md
│   │   ├── okta.md
│   │   ├── github.md
│   │   └── ... (110+ more platform guides)
│   ├── _data/
│   │   └── packs/                        # Auto-generated YAML for code pack rendering
│   ├── _layouts/                         # Jekyll layouts
│   │   ├── default.html
│   │   └── guide.html
│   ├── _includes/                        # Reusable Jekyll components
│   │   ├── header.html
│   │   ├── footer.html
│   │   └── pack-code.html               # Code Pack rendering template
│   └── assets/
│       └── css/
│           └── style.css                 # Dark + light theme stylesheet
├── packs/                                # Code Packs (61 vendors)
│   ├── README.md                         # Code Pack Ontology documentation
│   ├── schema/                           # YAML schema definitions
│   ├── okta/                             # Example vendor pack
│   │   ├── terraform/                    # Terraform modules
│   │   ├── api/                          # API scripts (bash + curl)
│   │   └── siem/sigma/                   # Sigma detection rules
│   └── ... (60 more vendor packs)
├── scripts/
│   └── sync-packs-to-data.sh            # Sync pack excerpts → Jekyll data YAML
├── templates/
│   └── vendor-guide-template.md          # Template for new vendor guides
├── references/                           # Reference materials (DISA STIGs, etc.)
├── VERSIONS.md                           # Central version registry for all guides
├── PHILOSOPHY.md                         # Project scope and design principles
├── CONTRIBUTING.md                       # Contribution guidelines
├── AGENTS.md                             # AI agent task procedures
└── LICENSE                               # MIT License
```

---

## Why This Project Exists

Existing resources are excellent for their domains, but leave critical gaps:

| Resource | Strength | Gap |
|----------|----------|-----|
| **CIS Benchmarks** | Infrastructure hardening (AWS, Azure, Kubernetes) | SaaS platforms; third-party integration controls |
| **howtorotate.com** | Secret rotation procedures | Proactive hardening (not post-breach remediation) |
| **Vendor documentation** | Feature details | Security-first guidance; vendor-neutral |
| **OWASP** | Application security | SaaS-specific configurations |

**We focus on the intersection nobody else covers:** SaaS integration security, OAuth governance, and supply chain attack prevention through first-party controls.

See [PHILOSOPHY.md](PHILOSOPHY.md) for full vision and scope definition.

---

## Principles

### 1. Integration-Focused Over Platform-Only
We emphasize how to configure platforms to restrict third-party integrations, not just platform hardening in isolation.

**Typical guide:** "Enable Salesforce IP allowlisting" (what, but not when or for whom)
**Our approach:** "Restrict Gainsight's Salesforce access via IP allowlisting" (specific integration context, attack relevance)

### 2. Attack-Informed Over Compliance-Driven
We prioritize controls based on **real attack patterns**, not just audit requirements.

Compliance mappings (SOC 2, NIST 800-53, etc.) are included, but recommendations are ordered by:
1. Recent supply chain attacks
2. Common attack patterns
3. Blast radius reduction

### 3. Accessible to All Maturity Levels
Every control includes:
- **ClickOps** (GUI/console) for IT admins without automation expertise
- **Code** (CLI/API/IaC) for security engineers who need repeatability

### 4. Vendor-Neutral But Vendor-Informed
We maintain independence while accurately representing platform capabilities. We don't require vendor approval for content, but we welcome vendor engineer contributions.

---

## Current Status

**Guide maturity system:**
- **Draft** -- AI-generated initial content, structurally complete
- **Reviewed** -- Expert-validated by a practitioner with platform experience
- **Verified** -- Production-tested in a real environment

**Current coverage:**
- 116 hardening guides across 9 categories (all currently at draft maturity)
- 61 Code Packs with Terraform, API, CLI, SDK, DB, and Sigma implementations
- Full Jekyll site with search, category filtering, and dark/light themes

**What we need:**
- Expert reviewers to validate draft guides and advance them to **reviewed** maturity
- Code Pack contributions for CLI, SDK, and DB language types
- Real-world testing to advance guides to **verified** maturity

---

## Get Involved

### Ways to Contribute

**For Security Practitioners:**
- Review and validate existing guides against your platform experience
- Test controls in your environment and report results
- Submit new guides for platforms not yet covered

**For Developers:**
- Contribute Code Packs (Terraform, API scripts, CLI scripts, Sigma rules)
- Improve the sync and rendering pipeline
- Build audit tooling on top of the structured pack data

**For Researchers:**
- Document supply chain incidents and map them to preventive controls
- Test control effectiveness in lab environments

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

### Communication Channels

- **GitHub Issues:** [Bug reports, feature requests, content proposals](https://github.com/grcengineering/how-to-harden/issues)
- **GitHub Discussions:** [General Q&A, ideas, feedback](https://github.com/grcengineering/how-to-harden/discussions)

---

## License

This project is licensed under the **MIT License** -- see [LICENSE](LICENSE) for full text.

You are free to use, modify, and distribute this work for any purpose.

---

## FAQ

**Q: How is this different from CIS Benchmarks?**
A: CIS focuses on infrastructure (AWS, Azure, Kubernetes). We focus on SaaS platforms and cross-platform integration security. CIS also requires paid membership for automation-friendly formats; we're free and open source.

**Q: Why are all guides at "draft" maturity?**
A: The initial 116 guides were AI-generated to provide comprehensive structural coverage. We need expert practitioners to review and validate them against real platform behavior. This is the highest-impact contribution you can make.

**Q: Can I contribute a guide for a platform not yet covered?**
A: Yes! Check [CONTRIBUTING.md](CONTRIBUTING.md) for platform selection criteria and use our [guide template](templates/vendor-guide-template.md).

**Q: What are Code Packs?**
A: Executable implementations of guide controls. Instead of just reading "enable MFA enforcement," you get Terraform modules, API scripts, and Sigma detection rules that actually implement and monitor the control. See [packs/README.md](packs/README.md).

---

## Attribution

Inspired by:
- **[howtorotate.com](https://howtorotate.com)** by Truffle Security -- Elegant simplicity, tight tool integration
- **[CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks)** -- Structured recommendation format, multi-profile approach
- **[MITRE ATT&CK](https://attack.mitre.org/)** -- Relational knowledge framework, real-world attack grounding
- **[OWASP Projects](https://owasp.org/projects/)** -- Community-driven security resources, tiered maturity model

Special thanks to **Okta's security team** for sharing their Salesloft incident response publicly, demonstrating the effectiveness of IP allowlisting and inspiring this project's focus on first-party controls.

---

**Built by [GRC Engineering](https://grc.engineering) and contributors who believe third-party risk management needs to be about first-party controls, not questionnaires.**

[Browse Guides](https://howtoharden.com) | [View Code Packs](packs/) | [Contribute](CONTRIBUTING.md)
