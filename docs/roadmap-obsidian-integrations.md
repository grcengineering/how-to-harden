---
layout: page
title: "HTH Guides Roadmap: Obsidian Security Integrations"
permalink: /roadmap/obsidian-integrations/
description: "Roadmap for creating How to Harden guides covering 175+ SaaS products in Obsidian Security's integrations ecosystem"
last_updated: "2026-02-05"
---

# HTH Guides Roadmap: Obsidian Security Integrations

**Version:** 2.0.0
**Last Updated:** 2026-02-05
**Status:** Active
**Authors:** Claude Code (Opus 4.5)

---

## Executive Summary

This roadmap defines the systematic approach to developing How to Harden (HTH) guides for each SaaS product listed on [Obsidian Security's integrations hub](https://www.obsidiansecurity.com/obsidian-integrations-hub). The initiative covers research, analysis, and documentation phases for **175+ products** across **12 categories**.

**Key Statistics:**

| Metric | Count |
|--------|-------|
| Total Obsidian Integration Products | 175+ |
| Starting HTH Guides | 53 |
| New Guides Created (Phase 4 Execution) | **48** |
| New Guides Remaining | **74+** |
| Guides Requiring Enhancement | 53 |
| **Current Total Guides** | **101** |
| Estimated Total Effort | ~2,625 hours |

### Execution Progress (Phase 4)

| Batch | Guides Created | Status |
|-------|----------------|--------|
| Batch 1 (Tier 1 Core) | Microsoft 365, Google Workspace, Microsoft Entra ID, Slack, ChatGPT Enterprise, Zscaler, Cloudflare, Auth0, Duo | ✅ Complete |
| Batch 2 (Tier 1-2 Security) | JumpCloud, Netskope, SentinelOne | ✅ Complete |
| Batch 3 (Tier 1-2 Data/MDM) | MongoDB Atlas, 1Password, Jamf | ✅ Complete |
| Batch 4 (DevOps) | GitHub Enterprise, Bitbucket, Jenkins, Postman | ✅ Complete |
| Batch 5 (IAM/Security) | OneLogin, LastPass, Keeper, Mimecast | ✅ Complete |
| Batch 6 (Compliance) | Drata, Vanta, Qualys, Tenable | ✅ Complete |
| Batch 7 (Business Apps) | DocuSign, Webex, Figma, Airtable | ✅ Complete |
| Batch 8 (Platforms) | Rapid7, Fivetran, SendGrid, Workato | ✅ Complete |
| Batch 9 (Infrastructure) | Datadog, PagerDuty, Splunk, ServiceNow | ✅ Complete |
| Batch 10 (Collaboration) | Notion, Asana, Monday.com, Jira Cloud | ✅ Complete |
| Batch 11 (HR/Finance) | Paylocity, UKG Pro, Coupa, SAP Concur | ✅ Complete |
| Batch 12 (Marketing/Analytics) | Braze, Intercom, Segment, Amplitude | ✅ Complete |
| Batch 13 (Developer) | Harness, Buildkite, Sentry, Linear | ✅ Complete |

---

## Table of Contents

1. [Phase 0: Project Infrastructure](#phase-0-project-infrastructure)
2. [Phase 1: Product Triage & Prioritization](#phase-1-product-triage--prioritization)
3. [Phase 2: Research Methodology](#phase-2-research-methodology)
4. [Phase 3: Guide Development Workflow](#phase-3-guide-development-workflow)
5. [Phase 4: Execution Timeline](#phase-4-execution-timeline)
6. [Phase 5: Quality Assurance Framework](#phase-5-quality-assurance-framework)
7. [Complete Product Inventory](#complete-product-inventory)
8. [Research Resource Library](#research-resource-library)
9. [Appendices](#appendices)

---

## Phase 0: Project Infrastructure

### 0.1 Template & Standards Development

- [x] Create HTH guide template with consistent structure (`templates/vendor-guide-template.md`)
- [x] Define minimum viable content requirements per guide
- [x] Establish quality criteria and review checklists
- [x] Create metadata schema for tracking guide status (YAML front matter)
- [x] Define versioning strategy for guide updates (`VERSIONS.md`)

### 0.2 Tooling & Automation Setup

- [ ] Configure CI/CD for guide publishing (GitHub Actions)
- [ ] Create scripts for automated link checking
- [ ] Build tracking dashboard for guide completion status
- [ ] Set up RSS/webhook monitors for vendor changelog tracking
- [ ] Create CVE monitoring automation for product list

### 0.3 Research Source Inventory

- [ ] Compile master list of security research databases (MITRE ATT&CK, CISA KEV, etc.)
- [ ] Inventory breach notification databases (HaveIBeenPwned, breach trackers)
- [ ] List security conference archives (DEF CON, Black Hat, BSides)
- [ ] Catalog security researcher blogs and feeds
- [ ] Identify vendor security advisory pages for each product

---

## Phase 1: Product Triage & Prioritization

### 1.1 Category Overview

| Category | Product Count | Priority Tier |
|----------|---------------|---------------|
| Identity & Access Management | ~20 | Tier 1 (Critical) |
| Collaboration & Productivity | ~25 | Tier 1 (Critical) |
| DevOps & Engineering | ~20 | Tier 1 (Critical) |
| Security & Compliance | ~30 | Tier 2 (High) |
| Data & Analytics | ~15 | Tier 2 (High) |
| Business Applications | ~25 | Tier 2 (High) |
| Files & Content Management | ~10 | Tier 3 (Standard) |
| IT Infrastructure & Networking | ~15 | Tier 3 (Standard) |
| AI & Automation Platforms | ~10 | Tier 1 (Critical) |
| Backup & Recovery | ~5 | Tier 2 (High) |
| HR & Payroll | ~10 | Tier 3 (Standard) |
| Financial & Specialized | ~10 | Tier 4 (As-needed) |

### 1.2 Priority Scoring Matrix

Score each product (1-5) on:

| Criterion | Weight | Description |
|-----------|--------|-------------|
| Market penetration / user base | 25% | Fortune 500 adoption rate |
| Sensitivity of data handled | 25% | PII, credentials, financial data |
| Attack surface complexity | 20% | API exposure, integrations, permissions |
| Known historical incidents | 15% | CVEs, breaches, supply chain attacks |
| Regulatory relevance | 10% | SOC 2, HIPAA, PCI-DSS, FedRAMP |
| API/automation depth | 5% | IaC support, API coverage |

### 1.3 Tier Definitions

| Tier | Criteria | Target Maturity | CIS Benchmark Available |
|------|----------|-----------------|-------------------------|
| **Tier 1** | Critical infrastructure, identity, major productivity suites | verified | Often yes |
| **Tier 2** | Significant enterprise adoption, handles sensitive data | reviewed | Sometimes |
| **Tier 3** | Specialized use cases, moderate adoption | draft | Rarely |
| **Tier 4** | Niche products, as-needed basis | draft | No |

### 1.4 Tier 1 Products (Immediate Priority)

**Identity & Access:**
- Okta, Microsoft Entra, Auth0, OneLogin, Ping Identity, JumpCloud, Duo, CyberArk, SailPoint, 1Password, LastPass, Keeper

**Collaboration:**
- Google Workspace, Microsoft 365, Slack, Slack Enterprise, Zoom, Webex, Microsoft Teams (via M365)

**DevOps:**
- GitHub, GitHub Enterprise, GitLab, Azure DevOps, Atlassian (Jira/Confluence/Bitbucket), Jenkins, CircleCI, Terraform Cloud

**Data Platforms:**
- Snowflake, Databricks, MongoDB Atlas

**CRM/Business Critical:**
- Salesforce, ServiceNow, Workday

**AI Platforms:**
- OpenAI/ChatGPT Enterprise, Microsoft Copilot

---

## Phase 2: Research Methodology

### 2.1 First-Party Documentation Research

#### 2.1.1 Documentation Sources

For each product, systematically locate and analyze:

| Source Type | Typical URL Pattern | Priority |
|-------------|---------------------|----------|
| Security Center/Trust Center | `trust.[vendor].com` or `security.[vendor].com` | Critical |
| Admin Console Documentation | `help.[vendor].com/admin` or `docs.[vendor].com` | Critical |
| API Documentation | `developer.[vendor].com` or `api.[vendor].com` | Critical |
| Release Notes / Changelog | `[vendor].com/releases` or `changelog.[vendor].com` | High |
| Compliance Documentation | `compliance.[vendor].com` | High |
| Security Whitepapers | Trust center downloads | Medium |
| Architecture Diagrams | Technical docs | Medium |

#### 2.1.2 Documentation Extraction Checklist

For each SaaS product, document:

- [ ] Official security documentation URL
- [ ] Admin console security settings location
- [ ] Available authentication methods (SAML, OIDC, MFA methods)
- [ ] Authorization models (RBAC, ABAC, custom)
- [ ] API authentication methods (OAuth, API keys, service accounts)
- [ ] Audit logging capabilities and retention options
- [ ] Data encryption options (at-rest, in-transit, customer-managed keys)
- [ ] Network security controls (IP allowlisting, private connectivity)
- [ ] Integration/OAuth app management settings
- [ ] Session management controls
- [ ] Data loss prevention (DLP) features
- [ ] Compliance certifications held
- [ ] Edition/tier feature restrictions

#### 2.1.3 API Documentation Analysis

- [ ] Enumerate all security-relevant API endpoints
- [ ] Document API rate limits and abuse prevention
- [ ] Identify programmatic access to security settings
- [ ] Map API scopes and permission models
- [ ] Document webhook/event subscription capabilities
- [ ] Identify bulk operations for security automation

#### 2.1.4 Config-as-Code Research

| IaC Tool | Research Focus |
|----------|----------------|
| **Terraform** | Official provider, community providers, security resource coverage |
| **Pulumi** | Provider availability, TypeScript/Python examples |
| **CloudFormation** | AWS-integrated SaaS configuration |
| **Ansible** | Modules for SaaS configuration |
| **Crossplane** | Kubernetes-native SaaS management |
| **Vendor-native** | e.g., Salesforce DX, Okta Terraform |

### 2.2 Third-Party Security Research

#### 2.2.1 Incident & Breach Research

| Source | URL | Use Case |
|--------|-----|----------|
| CISA KEV | https://www.cisa.gov/known-exploited-vulnerabilities-catalog | Known exploited vulnerabilities |
| CISA Alerts | https://www.cisa.gov/news-events/cybersecurity-advisories | Critical vulnerabilities |
| NVD | https://nvd.nist.gov/ | CVE details and scoring |
| CVE Details | https://www.cvedetails.com/ | Product-specific CVEs |
| HaveIBeenPwned | https://haveibeenpwned.com | Historical breach data |
| Privacy Rights Clearinghouse | https://privacyrights.org/data-breaches | Breach database |
| Obsidian Incident Watch | https://www.obsidiansecurity.com/incident-watch | SaaS-specific incidents |
| Exploit-DB | https://www.exploit-db.com/ | Public exploits |

#### 2.2.2 Security Research & Conference Content

| Source | URL | Focus |
|--------|-----|-------|
| DEF CON Archives | https://media.defcon.org/ | Conference presentations |
| Black Hat Archives | https://www.blackhat.com/html/archives.html | Research papers |
| SANS Reading Room | https://www.sans.org/white-papers/ | Security whitepapers |
| arXiv Security | https://arxiv.org/list/cs.CR/recent | Academic research |

#### 2.2.3 Security Research Blogs

| Resource | Focus Area |
|----------|------------|
| SpecterOps Blog | Identity attacks, Azure AD, BloodHound |
| PushSecurity Blog | SaaS phishing, identity threats |
| Mandiant | Incident response, threat intelligence |
| Unit 42 | Threat research, malware analysis |
| CrowdStrike Blog | Adversary tracking, TTPs |
| Wiz Research | Cloud misconfigurations |
| Netskope Threat Labs | Cloud and SaaS threats |
| AppOmni Blog | SaaS security research |
| Varonis Blog | Data security, insider threats |
| Datadog Security Labs | Observability security |

#### 2.2.4 Industry Guidance Research

- [ ] Check CIS Benchmarks availability
- [ ] Review NIST guidance if applicable
- [ ] Check vendor-specific hardening guides from third parties
- [ ] Review cloud provider security best practices
- [ ] Check compliance framework mappings (SOC 2, ISO 27001, NIST CSF)

#### 2.2.5 Attack Technique Research

- [ ] Map product to MITRE ATT&CK techniques
- [ ] Research SaaS-specific attack patterns
- [ ] Document known attack chains involving the product
- [ ] Identify detection opportunities for common attacks
- [ ] Research privilege escalation paths

### 2.3 Incident Research Template

```markdown
### Incident: [Incident Name]

**Date:** YYYY-MM-DD
**Product:** [Affected SaaS Product]
**Severity:** Critical / High / Medium / Low
**Impact:** [Data exposure, service disruption, etc.]

**Summary:**
[2-3 sentence description of the incident]

**Root Cause:**
[Technical explanation of what went wrong]

**Attack Vector:**
[How the attacker gained access or exploited the vulnerability]

**HTH Controls That Would Have Helped:**
- [Control 1]: [How it would have prevented/detected]
- [Control 2]: [How it would have prevented/detected]

**Lessons Learned:**
[Key takeaways for hardening guidance]

**Sources:**
- [Link to incident report]
- [Link to vendor disclosure]
```

### 2.4 Analysis & Synthesis

#### 2.4.1 Security Setting Classification

| Dimension | Options |
|-----------|---------|
| Risk Level | Critical / High / Medium / Low |
| Default State | Secure by Default / Insecure by Default / N/A |
| Implementation Method | GUI / API / CLI / Config-as-Code / Multiple |
| Prerequisite Requirements | License tier, feature flags, dependencies |
| Monitoring Capability | Native logging / SIEM integration / Custom |

#### 2.4.2 Gap Analysis Tasks

- [ ] Compare vendor documentation to known attack vectors
- [ ] Identify undocumented security features
- [ ] Note settings with poor defaults
- [ ] Document missing security controls
- [ ] Identify areas requiring compensating controls

---

## Phase 3: Guide Development Workflow

### 3.1 Development Process

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   1. RESEARCH   │────▶│   2. DRAFT      │────▶│   3. IMPLEMENT  │
│                 │     │                 │     │                 │
│ - First-party   │     │ - Structure     │     │ - ClickOps      │
│ - Third-party   │     │ - Controls      │     │ - Code/API      │
│ - API/IaC       │     │ - Compliance    │     │ - Terraform     │
│                 │     │                 │     │                 │
│ Est: 6-10 hrs   │     │ Est: 4-8 hrs    │     │ Est: 4-6 hrs    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                      │                       │
         ▼                      ▼                       ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   4. VALIDATE   │────▶│   5. REVIEW     │────▶│   6. PUBLISH    │
│                 │     │                 │     │                 │
│ - Test controls │     │ - SME review    │     │ - Merge PR      │
│ - Verify steps  │     │ - Security scan │     │ - Update index  │
│ - Check links   │     │ - Community     │     │ - Announce      │
│                 │     │                 │     │                 │
│ Est: 2-4 hrs    │     │ Est: 2-4 hrs    │     │ Est: 1 hr       │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

**Total Time per Guide: 12-22 hours (average ~15 hours)**

### 3.2 Research Phase Tasks

| Task | Description | Output |
|------|-------------|--------|
| R1 | Review official security documentation | Security settings inventory |
| R2 | Review admin/configuration guide | Configuration options list |
| R3 | Review API documentation | API endpoint inventory |
| R4 | Search for security incidents | Incident summary with controls |
| R5 | Review vulnerability databases | CVE list with mitigations |
| R6 | Check for existing benchmarks (CIS, etc.) | Baseline control set |
| R7 | Research IaC provider availability | Terraform/Pulumi resources |
| R8 | Identify edition/tier restrictions | Feature availability matrix |

### 3.3 Drafting Phase Tasks

| Task | Description |
|------|-------------|
| D1 | Create guide file from template |
| D2 | Complete YAML front matter |
| D3 | Write Overview section |
| D4 | Draft Authentication & Access Controls (Section 1) |
| D5 | Draft Network Access Controls (Section 2) |
| D6 | Draft OAuth & Integration Security (Section 3) |
| D7 | Draft Data Security (Section 4) |
| D8 | Draft Monitoring & Detection (Section 5) |
| D9 | Draft Third-Party Integration Security (Section 6) |
| D10 | Complete Compliance Quick Reference (Section 7) |
| D11 | Complete Edition/Tier Compatibility table |
| D12 | Add References appendix |
| D13 | Add CVE History appendix |
| D14 | Add Known Attack Techniques appendix |

### 3.4 Implementation Requirements

For each control:

- [ ] ClickOps steps written with exact navigation paths
- [ ] At least one code implementation (API or CLI)
- [ ] Terraform configuration if provider supports it
- [ ] Validation/testing steps documented
- [ ] Operational impact table completed
- [ ] Rollback procedure documented

### 3.5 Maintenance Phase (Ongoing)

| Trigger | Action |
|---------|--------|
| Vendor major version update | Full guide review |
| New CVE published | Update CVE appendix, add mitigating controls |
| Significant breach/incident | Add to incident database, review controls |
| CIS Benchmark updated | Align with new benchmark |
| Quarterly scheduled review | Verify links, check for UI changes |

---

## Phase 4: Execution Timeline

### 4.1 Sprint Structure (2-week sprints)

| Sprint | Focus | Products | Deliverables |
|--------|-------|----------|--------------|
| 1-2 | Infrastructure + Tier 1 IAM | Okta, Microsoft Entra, Auth0 | Templates, 3 guides |
| 3-4 | Tier 1 IAM + Collaboration | OneLogin, Ping, Google Workspace, M365 | 4 guides |
| 5-6 | Tier 1 DevOps | GitHub, GitLab, Azure DevOps, Atlassian | 4 guides |
| 7-8 | Tier 1 Data + Business | Snowflake, Databricks, Salesforce, ServiceNow | 4 guides |
| 9-10 | Tier 1 AI + Collaboration | ChatGPT Enterprise, Copilot, Slack, Zoom | 4 guides |
| 11-14 | Tier 2 Security Tools | CrowdStrike, SentinelOne, Wiz, Zscaler, etc. | 8 guides |
| 15-18 | Tier 2 Business Apps | Workday, HubSpot, Zendesk, SAP, etc. | 8 guides |
| 19-26 | Tier 3 Products | Standard priority products | 16 guides |
| 27-32 | Tier 4 + Existing Enhancement | Remaining + quality sweep | 20+ guides |

### 4.2 Resource Estimation

| Activity | Time per Product | Notes |
|----------|------------------|-------|
| Research (comprehensive) | 6-10 hours | Varies by API complexity |
| Drafting | 4-8 hours | Template reduces variance |
| Implementation | 4-6 hours | Including code testing |
| Review | 2-4 hours | Including code testing |
| **Total per Guide** | **12-22 hours** | ~15 hour average |

**Total Project Estimate:** ~2,625 hours (175 products × 15 hours average)

### 4.3 Milestone Targets

| Milestone | Target | Products Complete |
|-----------|--------|-------------------|
| M1: Proof of Concept | Sprint 2 | 3 guides (IAM focus) |
| M2: Tier 1 Complete | Sprint 10 | 30 guides |
| M3: 50% Coverage | Sprint 18 | 87 guides |
| M4: Tier 1-3 Complete | Sprint 26 | 150 guides |
| M5: Full Coverage | Sprint 32 | 175+ guides |

### 4.4 Progress Tracking Labels

GitHub Issues should use these labels:

- `guide:new` - New guide creation
- `guide:enhance` - Existing guide enhancement
- `phase:research` - Research phase
- `phase:draft` - Draft phase
- `phase:implement` - Implementation phase
- `phase:review` - Review phase
- `tier:1` / `tier:2` / `tier:3` / `tier:4` - Priority tier
- `cis:available` - CIS Benchmark exists
- `has:terraform` - Terraform provider available

---

## Phase 5: Quality Assurance Framework

### 5.1 Quality Gates

#### Research Quality Gate

Before proceeding to drafting:

- [ ] Official security documentation reviewed and cited
- [ ] At least 3 third-party security sources consulted
- [ ] Incident history documented (or confirmed no significant incidents)
- [ ] API documentation reviewed for automation capabilities
- [ ] Edition/tier restrictions identified
- [ ] CVE search completed within last 30 days

#### Draft Quality Gate

Before proceeding to implementation:

- [ ] All 7+ standard sections populated
- [ ] Minimum 5 controls per guide
- [ ] Compliance mappings to at least SOC 2 and NIST 800-53
- [ ] Edition/tier compatibility table completed
- [ ] Prerequisites documented for each control

#### Implementation Quality Gate

Before proceeding to review:

- [ ] Every control has ClickOps implementation
- [ ] Every control has at least one code implementation
- [ ] Terraform configuration provided where provider exists
- [ ] Validation steps documented for each control
- [ ] All code tested in real environment

#### Publication Quality Gate

Before merging:

- [ ] At least 1 reviewer with product expertise approved
- [ ] No broken links
- [ ] Markdown formatting validated for Jekyll
- [ ] VERSIONS.md updated
- [ ] Changelog entry added
- [ ] Screenshots current and accurate (if included)

### 5.2 Review Checklist

**Technical Accuracy:**

- [ ] All settings verified against current product version
- [ ] API examples tested and functional
- [ ] IaC code validated (`terraform validate`, etc.)

**Completeness:**

- [ ] All template sections addressed
- [ ] CVE history researched within last 30 days
- [ ] Compliance mappings verified
- [ ] References accessible and current

**Usability:**

- [ ] Implementation steps clear and actionable
- [ ] Rationale provided for each recommendation
- [ ] Operational impact documented
- [ ] Rollback procedures included

### 5.3 Update Triggers

| Trigger | Response Time | Action |
|---------|---------------|--------|
| Critical CVE | 24-48 hours | Emergency update |
| Major breach involving product | 1 week | Add incident, review controls |
| Vendor major release | 2 weeks | Full guide review |
| CIS Benchmark update | 2 weeks | Align controls |
| Quarterly review | Scheduled | Link check, UI verification |

---

## Complete Product Inventory

### Identity & Access Management (~20 products)

| Product | HTH Status | Priority | Complexity | CIS Available |
|---------|------------|----------|------------|---------------|
| Okta | Exists (v0.2.0-draft) | Tier 1 | High | Yes |
| Microsoft Entra ID | Exists (v0.1.0-draft) | Tier 1 | High | Yes |
| Auth0 | Exists (v0.1.0-draft) | Tier 1 | Medium | No |
| OneLogin | **NEW REQUIRED** | Tier 1 | Medium | No |
| Ping Identity | Exists (v0.1.0-draft) | Tier 1 | Medium | No |
| Ping Federate | **NEW REQUIRED** | Tier 2 | Medium | No |
| JumpCloud | Exists (v0.1.0-draft) | Tier 1 | Medium | No |
| Cisco Duo | Exists (v0.1.0-draft) | Tier 1 | Medium | No |
| CyberArk | Exists (v0.1.0-draft) | Tier 1 | High | Yes |
| SailPoint | Exists (v0.1.0-draft) | Tier 1 | High | No |
| BeyondTrust | Exists (v0.1.0-draft) | Tier 2 | Medium | No |
| 1Password | Exists (v0.1.0-draft) | Tier 2 | Low | No |
| LastPass | **NEW REQUIRED** | Tier 2 | Low | No |
| Keeper | **NEW REQUIRED** | Tier 2 | Low | No |
| Opal Security | **NEW REQUIRED** | Tier 3 | Low | No |

### Collaboration & Productivity (~25 products)

| Product | HTH Status | Priority | Complexity | CIS Available |
|---------|------------|----------|------------|---------------|
| Google Workspace | Exists (v0.1.0-draft) | Tier 1 | High | Yes |
| Microsoft 365 | Exists (v0.1.0-draft) | Tier 1 | High | Yes |
| Slack | Exists (v0.1.0-draft) | Tier 1 | Medium | No |
| Slack Enterprise Grid | **NEW REQUIRED** | Tier 1 | High | No |
| Zoom | Exists (v0.1.0-draft) | Tier 1 | Medium | Yes |
| Webex | **NEW REQUIRED** | Tier 2 | Medium | No |
| Atlassian (Jira/Confluence) | Exists (v0.1.0-draft) | Tier 1 | High | Yes |
| Notion | Exists (v0.1.0-draft) | Tier 2 | Medium | No |
| Asana | Exists (v0.1.0-draft) | Tier 2 | Low | No |
| Monday.com | Exists (v0.1.0-draft) | Tier 2 | Low | No |
| ClickUp | **NEW REQUIRED** | Tier 3 | Low | No |
| Smartsheet | Exists (v0.1.0-draft) | Tier 2 | Medium | No |
| Miro | Exists (v0.1.0-draft) | Tier 3 | Low | No |
| Mural | **NEW REQUIRED** | Tier 3 | Low | No |
| Lucid | **NEW REQUIRED** | Tier 3 | Low | No |
| Airtable | **NEW REQUIRED** | Tier 2 | Medium | No |
| Coda | **NEW REQUIRED** | Tier 3 | Low | No |
| Clockify | **NEW REQUIRED** | Tier 4 | Low | No |
| Figma | **NEW REQUIRED** | Tier 2 | Medium | No |
| Grammarly | **NEW REQUIRED** | Tier 3 | Low | No |
| Dialpad | **NEW REQUIRED** | Tier 3 | Low | No |
| Trello | **NEW REQUIRED** | Tier 3 | Low | No |

### DevOps & Engineering (~20 products)

| Product | HTH Status | Priority | Complexity | CIS Available |
|---------|------------|----------|------------|---------------|
| GitHub | Exists (v0.1.0-draft) | Tier 1 | High | Yes |
| GitHub Enterprise | **NEW REQUIRED** | Tier 1 | High | Yes |
| GitLab | Exists (v0.1.0-draft) | Tier 1 | High | Yes |
| Azure DevOps | Exists (v0.1.0-draft) | Tier 1 | High | No |
| Bitbucket | **NEW REQUIRED** | Tier 2 | Medium | No |
| Jenkins | **NEW REQUIRED** | Tier 2 | High | Yes |
| CircleCI | Exists (v0.1.0-draft) | Tier 2 | Medium | No |
| Terraform Cloud | Exists (v0.1.0-draft) | Tier 2 | Medium | No |
| JFrog Artifactory | Exists (v0.1.0-draft) | Tier 2 | Medium | No |
| Docker Hub | Exists (v0.1.0-draft) | Tier 2 | Medium | No |
| Postman | **NEW REQUIRED** | Tier 2 | Medium | No |
| LaunchDarkly | Exists (v0.1.0-draft) | Tier 2 | Low | No |
| Sentry | **NEW REQUIRED** | Tier 3 | Low | No |
| Snyk | Exists (v0.1.0-draft) | Tier 2 | Medium | No |
| GitGuardian | **NEW REQUIRED** | Tier 2 | Low | No |
| Vercel | Exists (v0.1.0-draft) | Tier 3 | Medium | No |
| Fastly | **NEW REQUIRED** | Tier 2 | Medium | No |
| n8n | **NEW REQUIRED** | Tier 3 | Medium | No |

### Security & Compliance (~30 products)

| Product | HTH Status | Priority | Complexity | CIS Available |
|---------|------------|----------|------------|---------------|
| CrowdStrike | Exists (v0.1.0-draft) | Tier 1 | High | No |
| SentinelOne | Exists (v0.1.0-draft) | Tier 1 | High | No |
| Wiz | Exists (v0.1.0-draft) | Tier 1 | High | No |
| Zscaler | Exists (v0.1.0-draft) | Tier 1 | High | No |
| Zscaler Private Access | **NEW REQUIRED** | Tier 1 | High | No |
| Netskope | Exists (v0.1.0-draft) | Tier 1 | High | No |
| Cloudflare | Exists (v0.1.0-draft) | Tier 1 | High | No |
| Mimecast | **NEW REQUIRED** | Tier 2 | Medium | No |
| KnowBe4 | **NEW REQUIRED** | Tier 2 | Low | No |
| Qualys | **NEW REQUIRED** | Tier 2 | High | No |
| Tenable | **NEW REQUIRED** | Tier 2 | High | No |
| Rapid7 | **NEW REQUIRED** | Tier 2 | High | No |
| Tanium | **NEW REQUIRED** | Tier 2 | High | No |
| Drata | **NEW REQUIRED** | Tier 2 | Medium | No |
| Vanta | **NEW REQUIRED** | Tier 2 | Medium | No |
| Auditboard | **NEW REQUIRED** | Tier 3 | Medium | No |
| HackerOne | **NEW REQUIRED** | Tier 3 | Low | No |
| Invicti (Netsparker) | **NEW REQUIRED** | Tier 3 | Medium | No |
| Secure Code Warrior | **NEW REQUIRED** | Tier 3 | Low | No |
| IriusRisk | **NEW REQUIRED** | Tier 3 | Medium | No |
| Abnormal AI | **NEW REQUIRED** | Tier 2 | Medium | No |
| Checkpoint | **NEW REQUIRED** | Tier 2 | High | Yes |
| Exabeam | **NEW REQUIRED** | Tier 2 | High | No |
| Google Security Operations | **NEW REQUIRED** | Tier 2 | High | No |
| iboss | **NEW REQUIRED** | Tier 3 | Medium | No |
| HashiCorp Vault | Exists (v0.1.0-draft) | Tier 2 | High | No |
| Splunk | Exists (v0.1.0-draft) | Tier 2 | High | No |
| Datadog | Exists (v0.1.0-draft) | Tier 1 | High | No |
| New Relic | Exists (v0.1.0-draft) | Tier 2 | Medium | No |
| PagerDuty | Exists (v0.1.0-draft) | Tier 2 | Medium | No |
| Logz.io | **NEW REQUIRED** | Tier 3 | Medium | No |

### Data & Analytics (~15 products)

| Product | HTH Status | Priority | Complexity | CIS Available |
|---------|------------|----------|------------|---------------|
| Snowflake | Exists (v0.1.0-draft) | Tier 1 | High | Yes |
| Databricks | Exists (v0.1.0-draft) | Tier 1 | High | No |
| MongoDB Atlas | Exists (v0.1.0-draft) | Tier 1 | High | Yes |
| Tableau | Exists (v0.1.0-draft) | Tier 2 | Medium | No |
| Looker | Exists (v0.1.0-draft) | Tier 2 | Medium | No |
| Power BI | Exists (v0.1.0-draft) | Tier 2 | Medium | No |
| Sigma Computing | **NEW REQUIRED** | Tier 3 | Medium | No |
| Fivetran | **NEW REQUIRED** | Tier 2 | Medium | No |
| Cribl | **NEW REQUIRED** | Tier 2 | Medium | No |
| Teradata | **NEW REQUIRED** | Tier 3 | High | No |
| Confluent Cloud | **NEW REQUIRED** | Tier 2 | High | No |
| Informatica | **NEW REQUIRED** | Tier 3 | High | No |

### Business Applications (~25 products)

| Product | HTH Status | Priority | Complexity | CIS Available |
|---------|------------|----------|------------|---------------|
| Salesforce | Exists (v0.1.0-draft) | Tier 1 | High | Yes |
| Salesforce Agentforce | **NEW REQUIRED** | Tier 1 | Medium | No |
| Salesforce Commerce Cloud | **NEW REQUIRED** | Tier 2 | High | No |
| Salesforce Marketing Cloud | **NEW REQUIRED** | Tier 2 | High | No |
| ServiceNow | Exists (v0.1.0-draft) | Tier 1 | High | Yes |
| Workday | Exists (v0.1.0-draft) | Tier 1 | High | No |
| HubSpot | Exists (v0.1.0-draft) | Tier 2 | Medium | No |
| Zendesk | Exists (v0.1.0-draft) | Tier 2 | Medium | No |
| Freshdesk | **NEW REQUIRED** | Tier 3 | Low | No |
| Freshsales | **NEW REQUIRED** | Tier 3 | Low | No |
| Freshservice | Exists (v0.1.0-draft) | Tier 3 | Low | No |
| Zoho CRM | **NEW REQUIRED** | Tier 3 | Medium | No |
| SAP S/4HANA | **NEW REQUIRED** | Tier 2 | High | Yes |
| SAP Ariba | **NEW REQUIRED** | Tier 2 | High | No |
| SAP Fieldglass | **NEW REQUIRED** | Tier 3 | Medium | No |
| SAP Cloud Identity Services | **NEW REQUIRED** | Tier 2 | High | No |
| SAP SuccessFactors | Exists (v0.1.0-draft) | Tier 2 | High | No |
| Oracle Fusion Apps | **NEW REQUIRED** | Tier 2 | High | No |
| Oracle Fusion HCM | **NEW REQUIRED** | Tier 2 | High | No |
| Oracle NetSuite | Exists (v0.1.0-draft) | Tier 2 | High | No |
| Coupa | **NEW REQUIRED** | Tier 3 | Medium | No |
| Gong | **NEW REQUIRED** | Tier 3 | Low | No |
| DocuSign | **NEW REQUIRED** | Tier 2 | Medium | No |
| Adobe Sign | **NEW REQUIRED** | Tier 2 | Medium | No |
| Adobe Marketo Engage | **NEW REQUIRED** | Tier 3 | Medium | No |
| Greenhouse | **NEW REQUIRED** | Tier 3 | Low | No |
| Veeva | **NEW REQUIRED** | Tier 3 | High | No |

### Files & Content Management (~10 products)

| Product | HTH Status | Priority | Complexity | CIS Available |
|---------|------------|----------|------------|---------------|
| Box | Exists (v0.1.0-draft) | Tier 1 | High | Yes |
| Dropbox | Exists (v0.1.0-draft) | Tier 2 | Medium | No |
| ShareFile | **NEW REQUIRED** | Tier 2 | Medium | No |
| iManage | **NEW REQUIRED** | Tier 2 | High | No |
| Relativity | **NEW REQUIRED** | Tier 3 | High | No |
| SharePoint (standalone) | **NEW REQUIRED** | Tier 1 | Medium | Yes |
| OneDrive (standalone) | **NEW REQUIRED** | Tier 2 | Low | No |
| Google Drive (standalone) | **NEW REQUIRED** | Tier 1 | Medium | Yes |

### IT Infrastructure & Networking (~15 products)

| Product | HTH Status | Priority | Complexity | CIS Available |
|---------|------------|----------|------------|---------------|
| Jamf | Exists (v0.1.0-draft) | Tier 1 | High | Yes |
| Meraki | **NEW REQUIRED** | Tier 2 | High | No |
| Arista | **NEW REQUIRED** | Tier 2 | High | No |
| Juniper Mist | **NEW REQUIRED** | Tier 2 | High | No |
| Cradlepoint | **NEW REQUIRED** | Tier 3 | Medium | No |
| Versa Concerto | **NEW REQUIRED** | Tier 3 | Medium | No |
| Akamai | **NEW REQUIRED** | Tier 2 | High | No |

### AI & Automation Platforms (~10 products)

| Product | HTH Status | Priority | Complexity | CIS Available |
|---------|------------|----------|------------|---------------|
| OpenAI Platform | **NEW REQUIRED** | Tier 1 | High | No |
| ChatGPT Enterprise | Exists (v0.1.0-draft) | Tier 1 | High | No |
| Microsoft Copilot | **NEW REQUIRED** | Tier 1 | High | No |
| Glean | **NEW REQUIRED** | Tier 2 | Medium | No |
| Moveworks | **NEW REQUIRED** | Tier 3 | Medium | No |
| Workato | **NEW REQUIRED** | Tier 2 | Medium | No |
| Tines | **NEW REQUIRED** | Tier 2 | Medium | No |
| MuleSoft | **NEW REQUIRED** | Tier 2 | High | No |
| Fabric | **NEW REQUIRED** | Tier 3 | Medium | No |
| Cursor | Exists (v0.1.0-draft) | Tier 2 | Medium | No |

### Backup & Recovery (~5 products)

| Product | HTH Status | Priority | Complexity | CIS Available |
|---------|------------|----------|------------|---------------|
| Rubrik | **NEW REQUIRED** | Tier 2 | High | No |
| Cohesity | **NEW REQUIRED** | Tier 2 | High | No |
| Druva | **NEW REQUIRED** | Tier 2 | Medium | No |
| Commvault | **NEW REQUIRED** | Tier 2 | High | No |

### HR & Payroll (~10 products)

| Product | HTH Status | Priority | Complexity | CIS Available |
|---------|------------|----------|------------|---------------|
| ADP | Exists (v0.1.0-draft) | Tier 2 | Medium | No |
| BambooHR | Exists (v0.1.0-draft) | Tier 3 | Low | No |
| Gusto | Exists (v0.1.0-draft) | Tier 3 | Low | No |
| Rippling | Exists (v0.1.0-draft) | Tier 3 | Medium | No |
| Oracle HCM | Exists (v0.1.0-draft) | Tier 2 | High | No |

### Marketing & Communications (~5 products)

| Product | HTH Status | Priority | Complexity | CIS Available |
|---------|------------|----------|------------|---------------|
| Marketo | Exists (v0.1.0-draft) | Tier 3 | Medium | No |
| Mailchimp | Exists (v0.1.0-draft) | Tier 3 | Low | No |
| Klaviyo | Exists (v0.1.0-draft) | Tier 3 | Low | No |
| SendGrid | **NEW REQUIRED** | Tier 3 | Low | No |

### Financial & Specialized (~10 products)

| Product | HTH Status | Priority | Complexity | CIS Available |
|---------|------------|----------|------------|---------------|
| Fireblocks | **NEW REQUIRED** | Tier 3 | High | No |
| Expensify | **NEW REQUIRED** | Tier 4 | Low | No |
| Zuora | **NEW REQUIRED** | Tier 3 | Medium | No |
| Dealcloud | **NEW REQUIRED** | Tier 4 | Medium | No |
| Insightly | **NEW REQUIRED** | Tier 4 | Low | No |

---

## Research Resource Library

### Primary Research Sources

#### Vulnerability & Incident Databases

| Source | URL | Use Case |
|--------|-----|----------|
| NIST NVD | https://nvd.nist.gov/ | CVE details and CVSS scores |
| CISA KEV | https://www.cisa.gov/known-exploited-vulnerabilities-catalog | Actively exploited vulnerabilities |
| CVE Details | https://www.cvedetails.com/ | Product-specific CVE search |
| Exploit-DB | https://www.exploit-db.com/ | Public exploits and PoCs |
| Obsidian Incident Watch | https://www.obsidiansecurity.com/incident-watch | SaaS-specific incidents |

#### Security Research Archives

| Source | URL | Use Case |
|--------|-----|----------|
| DEF CON Media Server | https://media.defcon.org/ | Conference presentations |
| Black Hat Archives | https://www.blackhat.com/html/archives.html | Research papers |
| SANS Reading Room | https://www.sans.org/white-papers/ | Security whitepapers |
| arXiv Security Papers | https://arxiv.org/list/cs.CR/recent | Academic research |

#### Industry Benchmarks & Standards

| Source | URL | Use Case |
|--------|-----|----------|
| CIS Benchmarks | https://www.cisecurity.org/cis-benchmarks | Configuration baselines |
| NIST 800-53 | https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final | Security controls |
| MITRE ATT&CK | https://attack.mitre.org/ | Adversary tactics and techniques |

### Vendor Documentation URL Patterns

```
Common Trust Center URLs:
- trust.[vendor].com
- security.[vendor].com
- www.[vendor].com/trust
- www.[vendor].com/security

Common API Documentation URLs:
- developer.[vendor].com
- api.[vendor].com
- docs.[vendor].com/api
- www.[vendor].com/developers

Common Admin Documentation URLs:
- help.[vendor].com
- support.[vendor].com
- docs.[vendor].com
- admin.[vendor].com/help
```

### Documentation Sources by Tier 1 Products

| Product | Security Docs | Admin Guide | API Docs |
|---------|--------------|-------------|----------|
| Okta | [Okta Security](https://www.okta.com/security/) | [Admin Docs](https://help.okta.com/en-us/Content/Topics/Security/Security.htm) | [API Reference](https://developer.okta.com/docs/reference/) |
| Microsoft Entra | [Entra Security](https://learn.microsoft.com/entra/fundamentals/security-operations-introduction) | [Entra Admin](https://learn.microsoft.com/entra/identity/) | [Graph API](https://learn.microsoft.com/graph/api/resources/azure-ad-overview) |
| Google Workspace | [Security Center](https://support.google.com/a/answer/7492330) | [Admin Help](https://support.google.com/a/) | [Admin SDK](https://developers.google.com/admin-sdk) |
| Microsoft 365 | [M365 Security](https://learn.microsoft.com/microsoft-365/security/) | [Admin Center](https://learn.microsoft.com/microsoft-365/admin/) | [Graph API](https://learn.microsoft.com/graph/) |
| Slack | [Slack Security](https://slack.com/trust/security) | [Admin Guide](https://slack.com/help/categories/360000049063) | [Web API](https://api.slack.com/) |
| GitHub | [GitHub Security](https://github.com/security) | [Enterprise Docs](https://docs.github.com/en/enterprise-cloud@latest/admin) | [REST API](https://docs.github.com/en/rest) |
| Salesforce | [Salesforce Trust](https://trust.salesforce.com/) | [Security Guide](https://help.salesforce.com/s/articleView?id=sf.security_overview.htm) | [REST API](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/) |
| Snowflake | [Snowflake Security](https://www.snowflake.com/en/why-snowflake/security/) | [Security Docs](https://docs.snowflake.com/en/user-guide/security) | [SQL API](https://docs.snowflake.com/en/developer-guide/sql-api/index) |
| ChatGPT Enterprise | [Enterprise Privacy](https://openai.com/enterprise-privacy) | [Help Center](https://help.openai.com/en/collections/5688201-chatgpt-enterprise) | [API Reference](https://platform.openai.com/docs/api-reference) |
| Microsoft Copilot | [Copilot Security](https://learn.microsoft.com/copilot/security) | [Admin Controls](https://learn.microsoft.com/copilot/microsoft-365/microsoft-365-copilot-admin) | Via Graph API |

---

## Appendices

### Appendix A: Automation Opportunities

#### CVE Monitoring Automation

```python
# Example: Daily CVE monitoring for product list
# Set up daily checks against NVD API for all products
# Trigger guide review workflow on new CVE detection

import requests
from datetime import datetime, timedelta

def check_nvd_for_product(product_name):
    """Query NVD for recent CVEs affecting a product."""
    base_url = "https://services.nvd.nist.gov/rest/json/cves/2.0"
    params = {
        "keywordSearch": product_name,
        "pubStartDate": (datetime.now() - timedelta(days=30)).isoformat(),
        "pubEndDate": datetime.now().isoformat()
    }
    response = requests.get(base_url, params=params)
    return response.json()
```

#### Documentation Change Detection

```python
# Example: Monitor vendor documentation for changes
# Use web archive diffs or vendor changelog RSS
# Flag guides needing updates

import feedparser

def monitor_changelog(rss_url):
    """Parse vendor changelog RSS feed for updates."""
    feed = feedparser.parse(rss_url)
    return [entry for entry in feed.entries
            if 'security' in entry.title.lower()]
```

#### Terraform Provider Registry Monitoring

```bash
# Track new/updated Terraform providers
# https://registry.terraform.io/search/providers
# Trigger IaC section updates

curl -s "https://registry.terraform.io/v2/providers?filter[tier]=official" \
  | jq '.data[].attributes.name'
```

### Appendix B: Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Guide Coverage | 100% of integrations | Guides published / Total products |
| Time to Publish | < 3 weeks from start | Research start → Publication date |
| Update Freshness | < 90 days stale | Days since last review |
| Technical Accuracy | > 95% | Review pass rate |
| Code Functionality | 100% | Automated test pass rate |
| CIS Alignment | Where available | Mapping completion |
| Community Engagement | Growing | Stars, forks, contributions |

### Appendix C: Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Vendor documentation gaps | High | Medium | Supplement with reverse engineering, community research |
| API breaking changes | Medium | High | Version pin examples, automated testing |
| Researcher capacity constraints | Medium | High | Prioritization framework, external contributors |
| Vendor cooperation issues | Low | Medium | Rely on public documentation, responsible disclosure |
| Guide obsolescence | High | Medium | Automated monitoring, quarterly reviews |
| Security vulnerability in guide code | Low | High | Code review, automated security scanning |

### Appendix D: Guide Structure Template

```markdown
# How to Harden: [Product Name]

## Metadata
- Version:
- Last Updated:
- Product Version Tested:
- License Tier Required:
- Estimated Implementation Time:

## Executive Summary

## Quick Wins (< 15 minutes each)

## 1. Authentication & Access Controls
### 1.1 Identity Provider Integration (SSO)
### 1.2 Multi-Factor Authentication
### 1.3 Password Policies
### 1.4 Session Management

## 2. Authorization & Access Control
### 2.1 Role-Based Access Control
### 2.2 Least Privilege Implementation
### 2.3 Service Account Management
### 2.4 API Permission Scopes

## 3. Data Protection
### 3.1 Encryption Configuration
### 3.2 Data Classification
### 3.3 Data Loss Prevention
### 3.4 Backup & Recovery Security

## 4. Network Security
### 4.1 IP Allowlisting
### 4.2 Private Connectivity Options
### 4.3 TLS Configuration

## 5. Logging & Monitoring
### 5.1 Audit Log Configuration
### 5.2 Log Retention
### 5.3 SIEM Integration
### 5.4 Alerting Rules

## 6. Integration Security
### 6.1 OAuth App Management
### 6.2 Third-Party Integration Review
### 6.3 Webhook Security

## 7. API Security
### 7.1 API Authentication
### 7.2 Rate Limiting
### 7.3 API Key Management

## 8. Compliance Considerations
### 8.1 SOC 2 Mapping
### 8.2 ISO 27001 Mapping
### 8.3 NIST 800-53 Mapping
### 8.4 PCI DSS Mapping (if applicable)

## 9. Implementation as Code
### 9.1 Terraform Examples
### 9.2 API Scripts
### 9.3 Verification Scripts

## 10. Incident Response Preparation
### 10.1 Forensic Data Sources
### 10.2 Containment Procedures
### 10.3 Recovery Procedures

## Appendix A: CVE History
## Appendix B: Known Attack Techniques
## Appendix C: References
## Appendix D: Changelog
```

### Appendix E: Related Resources

- [HTH Contributing Guide](/contributing/)
- [HTH Versioning Guide](/versions/)
- [HTH Guide Template](/templates/vendor-guide-template.md)
- [Obsidian Security Integrations Hub](https://www.obsidiansecurity.com/obsidian-integrations-hub)
- [Obsidian Security Blog](https://www.obsidiansecurity.com/blog/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks)
- [MITRE ATT&CK for Enterprise](https://attack.mitre.org/matrices/enterprise/)

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2026-02-05 | 2.1.0 | Execution progress: Created 15 new guides (M365, Google Workspace, Entra ID, Slack, ChatGPT Enterprise, Zscaler, Cloudflare, Auth0, Duo, JumpCloud, Netskope, SentinelOne, MongoDB Atlas, 1Password, Jamf). Total guides now 68. | Claude Code (Opus 4.5) |
| 2026-02-04 | 2.0.0 | Reconciled roadmap with comprehensive 175+ product inventory, added Phase 0 infrastructure, automation appendices, success metrics, risk register | Claude Code (Opus 4.5) |
| 2026-02-04 | 1.0.0 | Initial roadmap creation | Claude Code (Opus 4.5) |
