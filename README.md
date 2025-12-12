# How to Harden: SaaS Security Hardening Guides

> **First-party controls to mitigate third-party risks**

Community-driven, open source guides for hardening SaaS platforms with emphasis on **integration security and supply chain attack prevention**.

[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL%203.0-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Status: Alpha](https://img.shields.io/badge/Status-Alpha-yellow)](https://github.com/yourproject/how-to-harden/releases)

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
Like CIS Benchmarks, but free, vendor-neutral, and focused on integration controls.

- Salesforce, Microsoft 365, GitHub, Google Workspace, Slack, Okta, and more
- Covers authentication, authorization, API security, data protection
- Both **ClickOps** (GUI) and **Code** (IaC/API) implementations

### 2. Defensive Patterns (Our Unique Value)
**Relational security guidance** showing how to configure Platform A to restrict Platform B's access when B is compromised.

Example: [How to restrict Gainsight's Salesforce access via IP allowlisting](content/defensive-patterns/ip-allowlisting/salesforce-restricting-gainsight.md)

This cross-platform guidance doesn't exist in CIS Benchmarks, vendor docs, or other hardening resources.

### 3. Supply Chain Incident Case Studies
Real-world attacks (Drift, Gainsight, CircleCI, Okta) mapped to specific preventive controls that would have blocked or limited the attack.

---

## Quick Start

### For Security Practitioners

**Scenario 1: You use Salesforce + Gainsight**
```bash
# Option 1: Manual hardening (ClickOps)
1. Read: content/defensive-patterns/ip-allowlisting/salesforce-restricting-gainsight.md
2. Follow GUI steps to configure IP allowlisting in Salesforce
3. Estimated time: 10 minutes

# Option 2: Automated hardening (Code)
git clone https://github.com/yourproject/how-to-harden
cd how-to-harden/automation/scripts/salesforce
python configure-gainsight-ips.py --apply
```

**Scenario 2: Audit your current SaaS stack**
```bash
# Coming soon: Stack analyzer
how-to-harden analyze --stack salesforce,gainsight,slack,github
# Outputs prioritized hardening recommendations for your specific stack
```

### For Contributors

We need your expertise! See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- How to propose new platform guides
- How to add defensive patterns
- Template structure and quality standards

**Priority areas needing contribution:**
- [ ] Microsoft 365 + third-party app hardening
- [ ] GitHub Actions supply chain security
- [ ] Google Workspace default-sharing reduction
- [ ] Slack OAuth app governance

---

## Project Structure

```
how-to-harden/
├── content/
│   ├── platforms/              # Platform-specific guides
│   │   ├── salesforce/
│   │   ├── microsoft-365/
│   │   └── github/
│   ├── defensive-patterns/     # Cross-platform relational guides ⭐
│   │   ├── ip-allowlisting/
│   │   ├── oauth-scoping/
│   │   └── behavioral-monitoring/
│   └── supply-chain-incidents/ # Attack case studies
│       ├── salesloft-drift-2025/
│       └── gainsight-2025/
├── automation/
│   ├── scripts/                # Audit and remediation scripts
│   └── terraform/              # IaC templates
├── templates/
│   └── recommendation-template.md
├── PHILOSOPHY.md               # Scope, design principles, vision
├── CONTRIBUTING.md             # How to contribute
└── GOVERNANCE.md               # Decision-making, maintainer roles
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

### 1. Relational Over Isolated
We show how controls across platforms work together, not just individual platform hardening.

**Bad:** "Enable Salesforce IP allowlisting" (isolated, no context)
**Good:** "Restrict Gainsight's Salesforce access via IP allowlisting" (relational, shows interaction)

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

**Project Status:** 🟡 **Alpha** (Initial development, seeking co-maintainers and contributors)

**Coverage:**
- ✅ 1 platform guide (Salesforce - in progress)
- ✅ 1 defensive pattern (IP allowlisting)
- ✅ 1 incident case study (Salesloft/Drift)
- 🚧 Automation tooling (scripts available, CLI tool planned)

**Roadmap:**
- **Q1 2026:** Foundation complete (governance docs, 2-3 platform guides, 3 defensive patterns)
- **Q2 2026:** Expand to 5 platforms, build CLI analyzer tool
- **Q3-Q4 2026:** CSPM/SSPM vendor partnerships, 10+ platforms, annual SaaS Security report

See [GitHub Projects](https://github.com/yourproject/how-to-harden/projects) for detailed roadmap.

---

## Get Involved

### Ways to Contribute

**For Security Practitioners:**
- 🔍 **Review and validate** existing guides (test in your environment, provide feedback)
- 📝 **Document your stack** (submit defensive patterns for integrations you use)
- 🐛 **Report issues** (outdated guidance, broken links, vendor product changes)

**For Developers:**
- 🛠️ **Build automation** (audit scripts, Terraform modules, CLI tool)
- 📊 **Improve tooling** (machine-readable data formats, API integrations)

**For Researchers:**
- 📑 **Document incidents** (map breaches to preventive controls)
- 🔬 **Test controls** (validate effectiveness in lab environments)

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

### Communication Channels

- **GitHub Discussions:** [General Q&A, ideas, feedback](https://github.com/yourproject/how-to-harden/discussions)
- **GitHub Issues:** [Bug reports, feature requests, content proposals](https://github.com/yourproject/how-to-harden/issues)
- **Slack/Discord:** [Coming soon] `#how-to-harden` channel for real-time collaboration

---

## Recognition

All contributors are recognized in:
- [CONTRIBUTORS.md](CONTRIBUTORS.md)
- Individual guide changelogs
- Annual project reports

**Current Contributors:**
- [@your-github-handle] - Project founder, Salesforce guide lead

---

## License

This project is licensed under **AGPL-3.0** to ensure:
- ✅ Free and open access to all hardening guides
- ✅ Community contributions remain open source
- ✅ Commercial tools that integrate our data must share improvements

See [LICENSE](LICENSE) for full text.

**Why AGPL-3.0?** Following [howtorotate.com](https://howtorotate.com)'s model - strong copyleft ensures that if commercial security tools benefit from our work, their improvements flow back to the community.

---

## FAQ

**Q: How is this different from CIS Benchmarks?**
A: CIS focuses on infrastructure (AWS, Azure, Kubernetes). We focus on SaaS platforms and cross-platform integration security. CIS also requires paid membership for automation-friendly formats; we're free and open source.

**Q: I found outdated information. How do I report it?**
A: Open an issue with tag `content-outdated` and include the guide URL, what's wrong, and corrected information (with vendor documentation link).

**Q: Can I contribute a guide for a platform not yet covered?**
A: Yes! Check [CONTRIBUTING.md](CONTRIBUTING.md) for platform selection criteria and use our [recommendation template](templates/recommendation-template.md).

**Q: My company wants to sponsor this project. How?**
A: Email [maintainer contact] to discuss. We're exploring foundation affiliation (OWASP, CSA, Linux Foundation) for transparent governance.

**Q: Do you provide professional services to implement these controls?**
A: No, this is a community project. Some contributors may offer consulting independently—check their GitHub profiles.

---

## Attribution

Inspired by:
- **[howtorotate.com](https://howtorotate.com)** by Truffle Security - Elegant simplicity, tight tool integration
- **[CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks)** - Structured recommendation format, multi-profile approach
- **[MITRE ATT&CK](https://attack.mitre.org/)** - Relational knowledge framework, real-world attack grounding
- **[OWASP Projects](https://owasp.org/projects/)** - Community-driven security resources, tiered maturity model

Special thanks to **Okta's security team** for sharing their Salesloft incident response publicly, demonstrating the effectiveness of IP allowlisting and inspiring this project's focus on first-party controls.

---

## Security Reporting

If you discover a security vulnerability in our automation scripts or recommendations that could actively harm users, please email [security contact] instead of opening a public issue.

For general content corrections or improvements, use GitHub Issues.

---

**Built with ❤️ by security practitioners who are tired of third-party risk questionnaires that don't actually reduce risk.**

[⭐ Star this repo](https://github.com/yourproject/how-to-harden) | [📖 Read the docs](https://how-to-harden.dev) | [💬 Join discussions](https://github.com/yourproject/how-to-harden/discussions)
