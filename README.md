# How to Harden: SaaS Security Hardening Guides

> Community-developed, open source security hardening guides focused on **integration security and supply chain attack prevention**. Like CIS Benchmarks, but for SaaS platforms, free, and uniquely focused on cross-platform integration controls.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Guides: 130](https://img.shields.io/badge/Guides-130-blueviolet)](https://howtoharden.com)
[![Code Packs: 76](https://img.shields.io/badge/Code%20Packs-76-orange)](packs/)

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

Like CIS Benchmarks, but free, vendor-neutral, and focused on integration controls. Currently **130 guides** across 10 categories:

| Category | Count | Examples |
|----------|-------|---------|
| Productivity | 25 | Slack, Airtable, Asana, Notion |
| Security | 21 | CrowdStrike, Snyk, Wiz, Zscaler |
| Data | 17 | Snowflake, Databricks, MongoDB Atlas |
| DevOps | 17 | GitHub, GitLab, Jenkins, Buildkite |
| Identity | 13 | Okta, Auth0, Microsoft Entra ID, Duo |
| HR/Finance | 11 | BambooHR, ADP, Workday, Stripe |
| AI/ML Platform | 9 | Anthropic (Claude Enterprise, Claude Code, API), ChatGPT Enterprise, Ona, LangChain |
| Marketing | 9 | HubSpot, Braze, SendGrid, Twilio |
| IT Operations | 6 | ServiceNow, Jamf, PagerDuty, Windows 11 |
| IaC | 2 | Terraform Cloud, Pulumi |

Every control includes:
- **ClickOps** (GUI/console) steps for manual implementation
- **Code** (CLI/API/IaC) for automation and repeatability
- Four profile levels: **L1** (Crawl), **L2** (Walk), **L3** (Run), **L4** (Fly)
- Compliance mappings to SOC 2, NIST 800-53, ISO 27001, and PCI DSS

### 2. Code Packs -- Executable Security Controls

**76 vendor Code Packs** turn guide controls into runnable code. Each pack provides multiple language types:

| Language Type | Directory | What It Does |
|---------------|-----------|-------------|
| Config-as-Code | `terraform/` | Terraform modules to enforce controls declaratively |
| API Scripts | `api/` | bash + curl + jq against vendor REST APIs |
| CLI Scripts | `cli/` | First-party vendor CLIs (`gh`, `vault`, `databricks`, `az`) |
| SDK Scripts | `sdk/` | Python, PowerShell, Go vendor SDK integrations |
| DB Queries | `db/` | Vendor-native queries (Snowflake/Databricks SQL, BigQuery export SQL, SOQL, DAX) |
| SIEM Queries | `siem/` | Splunk SPL and Sentinel KQL detection queries |
| Detection Rules | `siem/sigma/` | Sigma rules (convert to Splunk, Elastic, Sentinel) |
| Config Files | `config/` | Vendor-native settings files and config-emitting scripts |

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
│   ├── _guides/                          # Platform hardening guides (125 guides)
│   │   ├── salesforce.md
│   │   ├── okta.md
│   │   ├── github.md
│   │   └── ... (120+ more platform guides)
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
├── packs/                                # Code Packs (76 vendors)
│   ├── README.md                         # Code Pack Ontology documentation
│   ├── schema/                           # YAML schema definitions
│   ├── okta/                             # Example vendor pack
│   │   ├── terraform/                    # Terraform modules
│   │   ├── api/                          # API scripts (bash + curl)
│   │   └── siem/sigma/                   # Sigma detection rules
│   └── ... (50+ more vendor packs)
├── scripts/
│   └── sync-packs-to-data.sh            # Sync pack excerpts → Jekyll data YAML
├── templates/
│   └── vendor-guide-template.md          # Template for new vendor guides
├── references/                           # Reference materials (DISA STIGs, etc.)
├── .claude/skills/                       # Authoring playbooks (plain markdown, any agent/human)
│   ├── create-hth-guide/SKILL.md         # New guide authoring process
│   ├── update-hth-guide/SKILL.md         # Currency-update process
│   ├── create-code-pack/SKILL.md         # Pack authoring process
│   ├── verify-hth/SKILL.md               # Pre-commit verification battery
│   └── validate-hth-guide/SKILL.md       # Active validation: does it actually work?
├── VERSIONS.md                           # Central version registry for all guides
├── PHILOSOPHY.md                         # Project scope and design principles
├── SOURCES.md                            # Authoritative-source taxonomy for guide content
├── CONTRIBUTING.md                       # Contribution guidelines
├── AGENTS.md                             # AI agent task procedures
└── LICENSE                               # MIT License
```

### Authoring Playbooks (for humans and any AI agent)

The five playbooks under `.claude/skills/` are prescriptive, step-by-step processes for the project's core workflows. They load automatically as skills in Claude Code, but they are **plain markdown** — contributors and any other AI tool (Cursor, Copilot, etc.) can open and follow them directly:

| Playbook | Use it when |
|----------|-------------|
| [`create-hth-guide`](.claude/skills/create-hth-guide/SKILL.md) | Writing a new vendor/product guide, breaking a platform into product guides, de-stubbing a placeholder |
| [`update-hth-guide`](.claude/skills/update-hth-guide/SKILL.md) | Refreshing a guide with current guidance, fixing an inaccuracy, adding a control |
| [`create-code-pack`](.claude/skills/create-code-pack/SKILL.md) | Adding or fixing any Code Pack, wiring pack includes |
| [`verify-hth`](.claude/skills/verify-hth/SKILL.md) | The pass/fail verification battery — run before every commit |
| [`validate-hth-guide`](.claude/skills/validate-hth-guide/SKILL.md) | Proving ClickOps steps, Code Packs, and OCEAN scanning actually work — and iterating until they do |

Source-selection standards (what counts as a "hardening guide" vs a Trust Center, and which third parties are authoritative) live in [SOURCES.md](SOURCES.md).

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

**Guide maturity system --- a matrix, not a ladder.** Every guide carries a `maturity` value that says how much contact it has had with reality, split across two axes that were previously being collapsed into one number: **what was done** (drafted -> reviewed -> validated) and **who did it** (`ai`, a machine; `ni`, natural intelligence -- a person). Six statuses, and a guide holds a *set* of them rather than a position on a line. Defined once, canonically, in [VERSIONS.md](VERSIONS.md#maturity-statuses--the-matrix); summarised here:

| | **Drafted** --- it exists | **Reviewed** --- someone judged it | **Validated** --- it was applied to a real system |
|--|---------------------------|------------------------------------|--------------------------------------------------|
| **AI** (a machine did it) | `ai-drafted` | `ai-reviewed` | `ai-validated` |
| **NI** (a person did it) | `ni-drafted` | `ni-reviewed` | `ni-validated` |

The statuses **combine**: a guide can be AI Drafted and NI Drafted at once, and holding both AI Validated and NI Validated is strictly better than holding either alone -- that pairing is the strongest thing this vocabulary can express. A guide's version qualifier names the furthest stage it reached, agent-prefixed unless *both* agents got there, so `v1.0.0-validated` is the strongest string in the system.

**An `ai-*` status is a claim about a machine's act, and asserts nothing about human judgement.** An agent can prove a console path is where the guide says it is; it cannot decide whether that control is the right control for your organization. So an AI status never discharges the need for its NI twin -- a guide sitting at AI Validated is a guide still waiting for its human reviewer, however long it sits there.

**Current coverage:**
- 130 hardening guides across 10 categories --- **all 130 `ai-drafted`**, of which **2 also hold `ai-validated`** (Buildkite, Ona)
- **No guide holds any `ni-*` status.** Nothing here has been drafted, reviewed, or validated by a person -- the entire NI row of the matrix is empty, and it is the half that matters most
- 76 vendor Code Packs with Terraform, API, CLI, SDK, config, DB, and Sigma implementations
- Full Jekyll site with search, six-status filtering, and dark/light themes

**What we need:**
- **Expert reviewers** --- the ceiling on this project. Read a guide against your platform experience and add **NI Reviewed**. This is needed whether or not a guide is AI Validated: no amount of machine validation produces a human judgement, and no guide in the corpus has this status yet
- **Practitioners who apply the controls** and report what happened, adding **NI Validated** --- also currently at zero across all 130 guides
- Live validation runs to add **AI Validated** --- console paths re-read off the real UI, Code Packs executed against a real tenant
- Code Pack contributions for CLI, SDK, and DB language types

---

## Get Involved

### Ways to Contribute

**For Security Practitioners:**
- Review existing guides against your platform experience --- this is what adds `ni-reviewed`, a status no guide holds yet
- Apply and test controls in your environment and report results --- this is what adds `ni-validated`, likewise at zero
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

**Q: Why is every guide only "AI Drafted"?**
A: They were AI-generated to provide comprehensive structural coverage, and `ai-drafted` says exactly that and nothing more: a machine wrote it from vendor documentation, and every console path in it is a claim transcribed from a document. Moving beyond that means adding statuses from the [matrix](VERSIONS.md#maturity-statuses--the-matrix), and the two axes move independently. A `validate-hth-guide` run exercises the guidance against a live tenant and adds **AI Validated** (two guides have cleared this). A human practitioner reading it against their own platform experience adds **NI Reviewed**, and one applying the controls on a real system adds **NI Validated** --- **no guide has either yet.** The NI half is what we are short of, and it is the highest-impact contribution you can make: an AI-validated guide is still an unreviewed guide.

**Q: What does "NI" mean?**
A: Natural intelligence --- a person. It is the counterpart to `ai` on the agent axis, and it is spelled out rather than implied because "reviewed" with no agent named is exactly the ambiguity this vocabulary exists to remove. Every status says who did the thing, so a reader never has to guess whether a human was involved.

**Q: What does the "AI Validated" badge on a control actually assert?**
A: That an AI agent went to a real tenant or console and exercised that specific requirement -- read the console path off the live UI, or ran the Code Pack against a live tenant -- and the guidance survived. It asserts nothing about human review, and it is only ever applied to requirements that came back verified live; controls that were skipped, blocked, or only checked against documentation do not get the mark. The page-level status is the sum of those per-control marks, which is why they render as the same icon.

**Q: How do I read the badges and chips?**
A: Each mark encodes both axes. The **glyph** is the stage --- pencil for drafted, eye for reviewed, check for validated. The **spark** in the top-right corner means a machine did it; no spark means a person did. An AI mark and its NI twin are otherwise identical, so "AI Validated + NI Validated" reads as one thing done twice rather than two unrelated badges. A control can carry more than one badge for the same reason a guide can hold more than one status: they add, they do not replace.

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
