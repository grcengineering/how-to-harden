---
layout: page
title: "HTH Guides Roadmap: Obsidian Security Integrations"
permalink: /roadmap/obsidian-integrations/
description: "Roadmap for creating How to Harden guides covering SaaS products in Obsidian Security's integrations ecosystem"
last_updated: "2026-02-04"
---

# HTH Guides Roadmap: Obsidian Security Integrations

**Version:** 1.0.0
**Last Updated:** 2026-02-04
**Status:** Active
**Authors:** Claude Code (Opus 4.5)

---

## Executive Summary

This roadmap defines the plan for creating comprehensive How to Harden (HTH) guides for SaaS products covered by [Obsidian Security's integrations ecosystem](https://www.obsidiansecurity.com/obsidian-integrations-hub). Obsidian Security provides SaaS Security Posture Management (SSPM) for hundreds of applications, making their integration list an authoritative reference for high-value hardening targets.

**Scope:** This roadmap covers research, development, and maintenance phases for creating new HTH guides and enhancing existing ones to align with Obsidian Security's coverage.

---

## Table of Contents

1. [Obsidian Security Integration Categories](#1-obsidian-security-integration-categories)
2. [Gap Analysis: Existing HTH Guides vs. Obsidian Integrations](#2-gap-analysis-existing-hth-guides-vs-obsidian-integrations)
3. [New Guides Required](#3-new-guides-required)
4. [Research Phase Requirements](#4-research-phase-requirements)
5. [Development Phase Workflow](#5-development-phase-workflow)
6. [Prioritization Framework](#6-prioritization-framework)
7. [Timeline and Milestones](#7-timeline-and-milestones)
8. [Quality Gates](#8-quality-gates)

---

## 1. Obsidian Security Integration Categories

Obsidian Security organizes their integrations into the following categories. HTH guides should be created or enhanced for products in each category.

### 1.1 Identity & Access Management

| Product | HTH Guide Status | Priority |
|---------|-----------------|----------|
| Okta | Exists (v0.2.0-draft) | Tier 1 |
| Microsoft Entra ID (Azure AD) | **NEW REQUIRED** | Tier 1 |
| Cisco Duo | **NEW REQUIRED** | Tier 2 |
| Auth0 | **NEW REQUIRED** | Tier 2 |
| JumpCloud | **NEW REQUIRED** | Tier 2 |
| Ping Identity | Exists (v0.1.0-draft) | Tier 2 |
| CyberArk | Exists (v0.1.0-draft) | Tier 2 |
| SailPoint | Exists (v0.1.0-draft) | Tier 2 |
| BeyondTrust | Exists (v0.1.0-draft) | Tier 3 |

### 1.2 Collaboration & Productivity

| Product | HTH Guide Status | Priority |
|---------|-----------------|----------|
| Microsoft 365 | **NEW REQUIRED** | Tier 1 |
| Google Workspace | **NEW REQUIRED** | Tier 1 |
| Slack | **NEW REQUIRED** | Tier 1 |
| Zoom | Exists (v0.1.0-draft) | Tier 1 |
| Atlassian (Jira/Confluence) | Exists (v0.1.0-draft) | Tier 1 |
| Asana | Exists (v0.1.0-draft) | Tier 2 |
| Monday.com | Exists (v0.1.0-draft) | Tier 2 |
| Notion | Exists (v0.1.0-draft) | Tier 2 |
| Miro | Exists (v0.1.0-draft) | Tier 3 |
| Smartsheet | Exists (v0.1.0-draft) | Tier 3 |

### 1.3 Files & Content Management

| Product | HTH Guide Status | Priority |
|---------|-----------------|----------|
| Box | Exists (v0.1.0-draft) | Tier 2 |
| Dropbox | Exists (v0.1.0-draft) | Tier 2 |
| SharePoint (via M365) | **NEW REQUIRED** | Tier 1 |
| OneDrive (via M365) | **NEW REQUIRED** | Tier 2 |
| Google Drive (via Workspace) | **NEW REQUIRED** | Tier 1 |

### 1.4 Business Applications (CRM/ERP/HCM)

| Product | HTH Guide Status | Priority |
|---------|-----------------|----------|
| Salesforce | Exists (v0.1.0-draft) | Tier 1 |
| Workday | Exists (v0.1.0-draft) | Tier 1 |
| ServiceNow | Exists (v0.1.0-draft) | Tier 1 |
| NetSuite | Exists (v0.1.0-draft) | Tier 2 |
| SAP SuccessFactors | Exists (v0.1.0-draft) | Tier 2 |
| SAP S/4HANA | **NEW REQUIRED** | Tier 2 |
| SAP Ariba | **NEW REQUIRED** | Tier 3 |
| SAP Fieldglass | **NEW REQUIRED** | Tier 3 |
| Oracle HCM | Exists (v0.1.0-draft) | Tier 2 |
| HubSpot | Exists (v0.1.0-draft) | Tier 2 |
| Zendesk | Exists (v0.1.0-draft) | Tier 2 |
| Freshservice | Exists (v0.1.0-draft) | Tier 3 |
| Zuora | **NEW REQUIRED** | Tier 3 |

### 1.5 Data & Analytics

| Product | HTH Guide Status | Priority |
|---------|-----------------|----------|
| Snowflake | Exists (v0.1.0-draft) | Tier 1 |
| Databricks | Exists (v0.1.0-draft) | Tier 1 |
| Tableau | Exists (v0.1.0-draft) | Tier 2 |
| Looker | Exists (v0.1.0-draft) | Tier 2 |
| Power BI | Exists (v0.1.0-draft) | Tier 2 |

### 1.6 DevOps & Engineering

| Product | HTH Guide Status | Priority |
|---------|-----------------|----------|
| GitHub | Exists (v0.1.0-draft) | Tier 1 |
| GitLab | Exists (v0.1.0-draft) | Tier 2 |
| Azure DevOps | Exists (v0.1.0-draft) | Tier 2 |
| CircleCI | Exists (v0.1.0-draft) | Tier 2 |
| JFrog Artifactory | Exists (v0.1.0-draft) | Tier 2 |
| Docker Hub | Exists (v0.1.0-draft) | Tier 2 |
| Terraform Cloud | Exists (v0.1.0-draft) | Tier 2 |
| Vercel | Exists (v0.1.0-draft) | Tier 3 |
| Snyk | Exists (v0.1.0-draft) | Tier 2 |
| LaunchDarkly | Exists (v0.1.0-draft) | Tier 3 |
| Fastly | **NEW REQUIRED** | Tier 3 |

### 1.7 Security & Compliance

| Product | HTH Guide Status | Priority |
|---------|-----------------|----------|
| CrowdStrike | Exists (v0.1.0-draft) | Tier 1 |
| Datadog | Exists (v0.1.0-draft) | Tier 1 |
| Splunk | Exists (v0.1.0-draft) | Tier 2 |
| New Relic | Exists (v0.1.0-draft) | Tier 2 |
| PagerDuty | Exists (v0.1.0-draft) | Tier 2 |
| Wiz | Exists (v0.1.0-draft) | Tier 2 |
| HashiCorp Vault | Exists (v0.1.0-draft) | Tier 2 |
| Logz.io | **NEW REQUIRED** | Tier 3 |

### 1.8 Marketing & Communications

| Product | HTH Guide Status | Priority |
|---------|-----------------|----------|
| Marketo | Exists (v0.1.0-draft) | Tier 3 |
| Mailchimp | Exists (v0.1.0-draft) | Tier 3 |
| Klaviyo | Exists (v0.1.0-draft) | Tier 3 |
| SendGrid | **NEW REQUIRED** | Tier 3 |

### 1.9 AI & Automation Platforms

| Product | HTH Guide Status | Priority |
|---------|-----------------|----------|
| ChatGPT Enterprise | **NEW REQUIRED** | Tier 1 |
| Microsoft Copilot | **NEW REQUIRED** | Tier 1 |
| Salesforce Agentforce | **NEW REQUIRED** | Tier 2 |
| n8n | **NEW REQUIRED** | Tier 3 |
| Cursor | Exists (v0.1.0-draft) | Tier 2 |

### 1.10 HR & Payroll

| Product | HTH Guide Status | Priority |
|---------|-----------------|----------|
| ADP | Exists (v0.1.0-draft) | Tier 2 |
| BambooHR | Exists (v0.1.0-draft) | Tier 3 |
| Gusto | Exists (v0.1.0-draft) | Tier 3 |
| Rippling | Exists (v0.1.0-draft) | Tier 3 |

---

## 2. Gap Analysis: Existing HTH Guides vs. Obsidian Integrations

### 2.1 Summary Statistics

| Metric | Count |
|--------|-------|
| Total Obsidian Integration Products Identified | 72 |
| Existing HTH Guides | 53 |
| Guides Requiring Creation | **19** |
| Guides Requiring Enhancement | 53 |

### 2.2 Existing Guides (53)

The following HTH guides already exist and should be enhanced with additional controls based on Obsidian Security's posture management capabilities:

- adp, asana, atlassian, azure-devops, bamboohr, beyondtrust, box, circleci, crowdstrike, cursor, cyberark, databricks, datadog, dockerhub, dropbox, freshservice, github, gitlab, gusto, hashicorp-vault, hubspot, jfrog, klaviyo, launchdarkly, looker, mailchimp, marketo, miro, monday, netsuite, new-relic, notion, okta, oracle-hcm, pagerduty, ping-identity, power-bi, rippling, sailpoint, salesforce, sap-successfactors, servicenow, smartsheet, snowflake, snyk, splunk, tableau, terraform-cloud, vercel, wiz, workday, zendesk, zoom

### 2.3 New Guides Required (19)

| Product | Category | Priority | Complexity |
|---------|----------|----------|------------|
| Microsoft 365 | Collaboration | Tier 1 | High |
| Google Workspace | Collaboration | Tier 1 | High |
| Slack | Collaboration | Tier 1 | Medium |
| Microsoft Entra ID | Identity | Tier 1 | High |
| ChatGPT Enterprise | AI | Tier 1 | Medium |
| Microsoft Copilot | AI | Tier 1 | Medium |
| Cisco Duo | Identity | Tier 2 | Medium |
| Auth0 | Identity | Tier 2 | Medium |
| JumpCloud | Identity | Tier 2 | Medium |
| SAP S/4HANA | Business | Tier 2 | High |
| Salesforce Agentforce | AI | Tier 2 | Medium |
| SharePoint | Files | Tier 1 | Medium |
| OneDrive | Files | Tier 2 | Low |
| Google Drive | Files | Tier 1 | Medium |
| SAP Ariba | Business | Tier 3 | Medium |
| SAP Fieldglass | Business | Tier 3 | Medium |
| Zuora | Business | Tier 3 | Medium |
| Fastly | DevOps | Tier 3 | Medium |
| Logz.io | Security | Tier 3 | Low |
| SendGrid | Marketing | Tier 3 | Low |
| n8n | Automation | Tier 3 | Low |

---

## 3. New Guides Required

### 3.1 Tier 1 Priority (High Business Impact)

These guides should be developed first due to their widespread enterprise adoption and security criticality.

#### 3.1.1 Microsoft 365

**Justification:** Ubiquitous enterprise productivity suite with extensive attack surface including Exchange Online, SharePoint, OneDrive, Teams, and Azure AD integration.

**Key Hardening Areas:**
- Conditional Access Policies
- Data Loss Prevention (DLP)
- Information Protection Labels
- External Sharing Controls
- OAuth App Governance
- Mail Flow Rules Security
- Teams Guest Access
- Admin Role Management

#### 3.1.2 Google Workspace

**Justification:** Major enterprise collaboration platform with Gmail, Drive, Meet, and identity services requiring comprehensive hardening.

**Key Hardening Areas:**
- Admin Console Security Settings
- 2-Step Verification Enforcement
- Drive Sharing Restrictions
- OAuth App Allowlisting
- Alert Center Configuration
- Context-Aware Access
- DLP Rules
- Mobile Device Management

#### 3.1.3 Slack

**Justification:** Critical communication platform with OAuth integrations, file sharing, and extensive third-party app ecosystem.

**Key Hardening Areas:**
- Enterprise Grid Security Controls
- Slack Connect External Collaboration
- App Management and OAuth Scopes
- Data Retention Policies
- Session Management
- IP Allowlisting (Enterprise)
- Channel Management
- DLP Integration

#### 3.1.4 Microsoft Entra ID (Azure AD)

**Justification:** Core identity provider for enterprise environments with SSO, conditional access, and privileged identity management.

**Key Hardening Areas:**
- Conditional Access Policies
- Privileged Identity Management (PIM)
- Identity Protection Risk Policies
- App Registration Security
- External Identity Management
- Entitlement Management
- Access Reviews
- Legacy Authentication Blocking

#### 3.1.5 ChatGPT Enterprise / OpenAI

**Justification:** Rapidly adopted AI platform with data privacy implications and integration risks.

**Key Hardening Areas:**
- Data Retention Settings
- SSO/SCIM Configuration
- Workspace Access Controls
- Custom GPT Governance
- API Key Management
- Usage Monitoring
- Data Export Controls
- Plugin/Action Restrictions

#### 3.1.6 Microsoft Copilot

**Justification:** AI assistant integrated with Microsoft 365 with access to enterprise data.

**Key Hardening Areas:**
- Copilot Access Policies
- Data Sensitivity Labels
- Plugin Management
- Usage Analytics
- Compliance Controls
- Information Barriers
- External Data Access

### 3.2 Tier 2 Priority (Significant Security Impact)

#### Cisco Duo, Auth0, JumpCloud, SAP S/4HANA, Salesforce Agentforce, SharePoint (standalone), OneDrive (standalone)

### 3.3 Tier 3 Priority (Specialized or Lower Adoption)

#### SAP Ariba, SAP Fieldglass, Zuora, Fastly, Logz.io, SendGrid, n8n

---

## 4. Research Phase Requirements

Each new HTH guide requires comprehensive research across multiple source categories before development begins.

### 4.1 First-Party Documentation Research

**Objective:** Identify all security-relevant settings, configurations, and APIs from official vendor sources.

#### 4.1.1 Documentation Types to Review

| Documentation Type | Research Focus | Priority |
|--------------------|----------------|----------|
| **Security/Trust Center** | Security architecture, compliance certifications, shared responsibility model | Critical |
| **Admin/Configuration Guide** | All configurable security settings, default values | Critical |
| **API Reference** | Security-relevant API endpoints, authentication methods, rate limits | Critical |
| **Best Practices Guide** | Vendor-recommended security configurations | High |
| **Release Notes** | New security features, deprecated settings, breaking changes | High |
| **Compliance Documentation** | SOC 2 reports, ISO certifications, penetration test summaries | High |
| **Identity/SSO Guide** | SAML, OIDC, SCIM configuration options | Critical |
| **Audit Log Reference** | Available log events, retention, export options | High |
| **API Changelog** | API version changes, deprecated endpoints | Medium |
| **Developer Documentation** | OAuth scopes, webhook security, integration patterns | Medium |

#### 4.1.2 Research Checklist

For each SaaS product, document:

- [ ] Official security documentation URL
- [ ] Admin console security settings location
- [ ] Available authentication methods (SSO, MFA, etc.)
- [ ] Role-based access control model
- [ ] API authentication methods and scopes
- [ ] Audit logging capabilities and retention
- [ ] Data encryption options (at-rest, in-transit)
- [ ] IP allowlisting/network restrictions availability
- [ ] Session management options
- [ ] Third-party integration/OAuth app controls
- [ ] Data export and backup capabilities
- [ ] Compliance certifications held
- [ ] Edition/tier feature restrictions

#### 4.1.3 Documentation Sources by Product

| Product | Primary Security Docs | Admin Guide | API Docs |
|---------|----------------------|-------------|----------|
| Microsoft 365 | [Microsoft Security](https://security.microsoft.com), [Trust Center](https://www.microsoft.com/trust-center) | [Admin Center](https://admin.microsoft.com) | [Graph API](https://docs.microsoft.com/graph) |
| Google Workspace | [Security Center](https://admin.google.com/security), [Trust](https://workspace.google.com/security/) | [Admin Help](https://support.google.com/a) | [Admin SDK](https://developers.google.com/admin-sdk) |
| Slack | [Security at Slack](https://slack.com/trust/security), [Enterprise Grid](https://slack.com/enterprise) | [Help Center](https://slack.com/help) | [Web API](https://api.slack.com) |
| Entra ID | [Entra Documentation](https://learn.microsoft.com/entra) | [Entra Admin](https://entra.microsoft.com) | [Graph API](https://docs.microsoft.com/graph) |
| ChatGPT Enterprise | [Enterprise Security](https://openai.com/enterprise-privacy) | [Help Center](https://help.openai.com) | [API Reference](https://platform.openai.com/docs) |

### 4.2 Third-Party Security Research

**Objective:** Identify real-world attack patterns, vulnerabilities, and community-sourced hardening recommendations.

#### 4.2.1 Research Categories

| Category | Sources | Research Focus |
|----------|---------|----------------|
| **Security Incidents** | News, vendor disclosures, breach databases | Past breaches, root causes, applicable controls |
| **Vulnerability Research** | CVE databases, security advisories | Known vulnerabilities, mitigations |
| **Penetration Testing** | Published reports, bug bounties | Common attack vectors, exploitation techniques |
| **Security Blogs** | Vendor blogs, security researchers | Configuration weaknesses, hardening tips |
| **Academic Research** | Papers, conference presentations | Advanced attack techniques, defense strategies |
| **Community Forums** | Reddit, Stack Overflow, vendor forums | Real-world implementation challenges |
| **Compliance Frameworks** | CIS Benchmarks, NIST, vendor-specific | Baseline configuration requirements |

#### 4.2.2 Incident Research Sources

| Source | URL | Use Case |
|--------|-----|----------|
| CISA Alerts | https://www.cisa.gov/news-events/cybersecurity-advisories | Critical vulnerabilities |
| HaveIBeenPwned | https://haveibeenpwned.com | Historical breach data |
| Obsidian Security Blog | https://www.obsidiansecurity.com/blog | SaaS-specific threats |
| Unit 42 | https://unit42.paloaltonetworks.com | Threat intelligence |
| Mandiant | https://www.mandiant.com/resources | Incident reports |
| KrebsOnSecurity | https://krebsonsecurity.com | Breach coverage |
| BleepingComputer | https://www.bleepingcomputer.com | Security news |
| The Record | https://therecord.media | Cyber incident reporting |
| CVE Database | https://cve.mitre.org | Vulnerability tracking |
| NVD | https://nvd.nist.gov | Vulnerability details |

#### 4.2.3 Security Research Blogs & Resources

| Resource | Focus Area |
|----------|------------|
| SpecterOps Blog | Identity attacks, Azure AD |
| PushSecurity Blog | SaaS phishing, identity threats |
| Resmo Blog | SaaS security posture |
| AppOmni Blog | SaaS security research |
| Netskope Threat Labs | Cloud and SaaS threats |
| Varonis Blog | Data security, insider threats |
| Wiz Research | Cloud misconfigurations |
| Datadog Security Labs | Observability security |

#### 4.2.4 Incident Research Checklist

For each SaaS product, research and document:

- [ ] Major security incidents affecting the product (last 5 years)
- [ ] Root cause analysis of each incident
- [ ] Controls that would have prevented/detected the incident
- [ ] Vendor response and remediation actions
- [ ] Published CVEs and security advisories
- [ ] Known attack techniques (MITRE ATT&CK mapping)
- [ ] Common misconfiguration issues
- [ ] Third-party security assessments or audits

#### 4.2.5 Example Incident Research Template

```markdown
### Incident: [Incident Name]

**Date:** YYYY-MM-DD
**Product:** [Affected SaaS Product]
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

### 4.3 API and Automation Research

**Objective:** Identify programmatic methods for implementing and validating hardening controls.

#### 4.3.1 API Research Checklist

For each SaaS product, document:

- [ ] API authentication methods (OAuth, API keys, service accounts)
- [ ] API endpoints for security configuration
- [ ] API endpoints for audit log retrieval
- [ ] Rate limiting and quotas
- [ ] API versioning strategy
- [ ] Webhook availability for real-time monitoring
- [ ] SCIM provisioning support
- [ ] GraphQL vs REST availability
- [ ] SDK availability (Python, Go, etc.)
- [ ] CLI tool availability

#### 4.3.2 Infrastructure-as-Code Research

| IaC Tool | Research Focus |
|----------|----------------|
| **Terraform** | Official provider, community providers, security resource coverage |
| **Pulumi** | Provider availability, TypeScript/Python examples |
| **CloudFormation** | AWS-integrated SaaS configuration |
| **Ansible** | Modules for SaaS configuration |
| **Crossplane** | Kubernetes-native SaaS management |

#### 4.3.3 Automation Research Template

```markdown
### [Product] Automation Capabilities

**API Authentication:**
- Primary Method: [OAuth 2.0 / API Key / etc.]
- Service Account Support: [Yes/No]
- Token Expiration: [Duration]

**Security Configuration APIs:**
| Setting | API Endpoint | Method | Notes |
|---------|-------------|--------|-------|
| MFA Policy | `/api/v1/policies/mfa` | PUT | Requires admin scope |
| IP Allowlist | `/api/v1/security/ip` | POST | Enterprise only |

**Terraform Provider:**
- Provider: [Official/Community]
- Registry: [Link]
- Security Resources: [List of security-related resources]

**CLI Tool:**
- Name: [CLI name]
- Installation: [Command]
- Security Commands: [List]
```

---

## 5. Development Phase Workflow

### 5.1 Guide Development Process

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   1. RESEARCH   │────▶│   2. DRAFT      │────▶│   3. IMPLEMENT  │
│                 │     │                 │     │                 │
│ - First-party   │     │ - Structure     │     │ - ClickOps      │
│ - Third-party   │     │ - Controls      │     │ - Code/API      │
│ - API/IaC       │     │ - Compliance    │     │ - Terraform     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                      │                       │
         ▼                      ▼                       ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   4. VALIDATE   │────▶│   5. REVIEW     │────▶│   6. PUBLISH    │
│                 │     │                 │     │                 │
│ - Test controls │     │ - SME review    │     │ - Merge PR      │
│ - Verify steps  │     │ - Security scan │     │ - Update index  │
│ - Check links   │     │ - Community     │     │ - Announce      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### 5.2 Phase 1: Research (Per Guide)

**Duration Estimate:** Variable by product complexity

**Deliverables:**
1. Research notes document (`/research/[vendor]-research.md`)
2. Incident summary document
3. API capabilities matrix
4. Control inventory spreadsheet

**Research Tasks:**

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

### 5.3 Phase 2: Draft (Per Guide)

**Deliverables:**
1. Guide markdown file following template structure
2. YAML front matter with metadata
3. All 7 standard sections populated

**Drafting Tasks:**

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

### 5.4 Phase 3: Implement (Per Control)

**Deliverables:**
1. ClickOps steps verified in real environment
2. Code implementations (CLI, API, Terraform)
3. Validation steps documented

**Implementation Requirements:**

For each control:
- [ ] ClickOps steps written with exact navigation paths
- [ ] At least one code implementation (API or CLI)
- [ ] Terraform configuration if provider supports it
- [ ] Validation/testing steps documented
- [ ] Operational impact table completed
- [ ] Rollback procedure documented

### 5.5 Phase 4: Validate

**Validation Checklist:**

- [ ] All ClickOps steps tested in real product environment
- [ ] All API/CLI commands tested and working
- [ ] Terraform configurations validated with `terraform plan`
- [ ] All documentation links verified (not broken)
- [ ] Compliance mappings cross-referenced with framework documents
- [ ] Screenshots match current product UI (if included)
- [ ] Version/edition requirements verified

### 5.6 Phase 5: Review

**Review Requirements:**

| Review Type | Requirement |
|-------------|-------------|
| Technical Review | 1+ reviewer with hands-on product experience |
| Security Review | 1+ reviewer with security background |
| Community Review | Open PR for community feedback (minimum 48 hours) |
| Automated Checks | Markdown linting, link validation, spelling |

### 5.7 Phase 6: Publish

**Publication Checklist:**

- [ ] Merge PR to main branch
- [ ] Update VERSIONS.md registry
- [ ] Verify guide renders correctly on website
- [ ] Add to category index pages
- [ ] Announce in community channels (if applicable)

---

## 6. Prioritization Framework

### 6.1 Prioritization Criteria

| Criterion | Weight | Description |
|-----------|--------|-------------|
| **Enterprise Adoption** | 30% | Number of Fortune 500 companies using the product |
| **Security Criticality** | 25% | Sensitivity of data/access the product handles |
| **Attack Surface** | 20% | Complexity and exposure of the product |
| **Community Demand** | 15% | Requests from HTH community |
| **Existing Coverage** | 10% | Gap vs. other security benchmarks |

### 6.2 Tier Definitions

| Tier | Criteria | Target Maturity |
|------|----------|-----------------|
| **Tier 1** | Critical infrastructure, identity, major productivity suites | verified |
| **Tier 2** | Significant enterprise adoption, handles sensitive data | reviewed |
| **Tier 3** | Specialized use cases, lower adoption | draft |

### 6.3 Development Order

**Phase 1: Tier 1 New Guides**
1. Microsoft 365
2. Google Workspace
3. Microsoft Entra ID
4. Slack
5. ChatGPT Enterprise
6. Microsoft Copilot

**Phase 2: Tier 1 Existing Guide Enhancement**
7. Okta (v0.2.0 → v1.0.0-reviewed)
8. Salesforce (v0.1.0 → v0.2.0-draft)
9. GitHub (v0.1.0 → v0.2.0-draft)
10. Snowflake (v0.1.0 → v0.2.0-draft)

**Phase 3: Tier 2 New Guides**
11. Cisco Duo
12. Auth0
13. JumpCloud
14. SAP S/4HANA
15. Salesforce Agentforce

**Phase 4: Tier 2 Existing Guide Enhancement**
- Batch enhancement of remaining Tier 2 guides

**Phase 5: Tier 3 Guides**
- New guides and enhancements as capacity allows

---

## 7. Timeline and Milestones

### 7.1 Milestone Definitions

| Milestone | Definition |
|-----------|------------|
| **M1: Research Complete** | All research phases finished for target guides |
| **M2: Draft Complete** | Initial draft guides created |
| **M3: Implementation Complete** | All controls have ClickOps + Code implementations |
| **M4: Review Complete** | SME review passed |
| **M5: Published** | Guide merged and live on website |

### 7.2 Progress Tracking

Progress should be tracked in GitHub Issues with the following labels:

- `guide:new` - New guide creation
- `guide:enhance` - Existing guide enhancement
- `phase:research` - Research phase
- `phase:draft` - Draft phase
- `phase:implement` - Implementation phase
- `phase:review` - Review phase
- `tier:1` / `tier:2` / `tier:3` - Priority tier

---

## 8. Quality Gates

### 8.1 Research Quality Gate

Before proceeding to drafting:

- [ ] Official security documentation reviewed and cited
- [ ] At least 3 third-party security sources consulted
- [ ] Incident history documented (or confirmed no significant incidents)
- [ ] API documentation reviewed for automation capabilities
- [ ] Edition/tier restrictions identified

### 8.2 Draft Quality Gate

Before proceeding to implementation:

- [ ] All 7 standard sections populated
- [ ] Minimum 5 controls per guide
- [ ] Compliance mappings to at least SOC 2 and NIST 800-53
- [ ] Edition/tier compatibility table completed
- [ ] Prerequisites documented for each control

### 8.3 Implementation Quality Gate

Before proceeding to review:

- [ ] Every control has ClickOps implementation
- [ ] Every control has at least one code implementation
- [ ] Terraform configuration provided where provider exists
- [ ] Validation steps documented for each control
- [ ] All code tested in real environment

### 8.4 Publication Quality Gate

Before merging:

- [ ] At least 1 reviewer with product expertise approved
- [ ] No broken links
- [ ] Markdown formatting validated for Jekyll
- [ ] VERSIONS.md updated
- [ ] Changelog entry added

---

## Appendix A: Research Resources by Category

### Identity & Access Management

| Product | Security Docs | Admin Guide | API Docs |
|---------|--------------|-------------|----------|
| Okta | [Okta Security](https://www.okta.com/security/) | [Admin Docs](https://help.okta.com/en-us/Content/Topics/Security/Security.htm) | [API Reference](https://developer.okta.com/docs/reference/) |
| Entra ID | [Entra Security](https://learn.microsoft.com/entra/fundamentals/security-operations-introduction) | [Entra Admin](https://learn.microsoft.com/entra/identity/) | [Graph API](https://learn.microsoft.com/graph/api/resources/azure-ad-overview) |
| Duo | [Duo Security](https://duo.com/docs/security) | [Admin Guide](https://duo.com/docs) | [Admin API](https://duo.com/docs/adminapi) |
| Auth0 | [Auth0 Security](https://auth0.com/security) | [Manage Users](https://auth0.com/docs/manage-users) | [Management API](https://auth0.com/docs/api/management/v2) |
| JumpCloud | [JumpCloud Security](https://jumpcloud.com/security) | [Admin Guide](https://support.jumpcloud.com/s/) | [API Docs](https://docs.jumpcloud.com/api/) |

### Collaboration & Productivity

| Product | Security Docs | Admin Guide | API Docs |
|---------|--------------|-------------|----------|
| M365 | [M365 Security](https://learn.microsoft.com/microsoft-365/security/) | [Admin Center](https://learn.microsoft.com/microsoft-365/admin/) | [Graph API](https://learn.microsoft.com/graph/) |
| Google Workspace | [Security Center](https://support.google.com/a/answer/7492330) | [Admin Help](https://support.google.com/a/) | [Admin SDK](https://developers.google.com/admin-sdk) |
| Slack | [Slack Security](https://slack.com/trust/security) | [Admin Guide](https://slack.com/help/categories/360000049063) | [Web API](https://api.slack.com/) |
| Zoom | [Zoom Security](https://explore.zoom.us/en/trust/security/) | [Admin Guide](https://support.zoom.com/hc/en/admin) | [API Docs](https://developers.zoom.us/docs/api/) |

### AI Platforms

| Product | Security Docs | Admin Guide | API Docs |
|---------|--------------|-------------|----------|
| ChatGPT Enterprise | [Enterprise Privacy](https://openai.com/enterprise-privacy) | [Help Center](https://help.openai.com/en/collections/5688201-chatgpt-enterprise) | [API Reference](https://platform.openai.com/docs/api-reference) |
| Microsoft Copilot | [Copilot Security](https://learn.microsoft.com/copilot/security) | [Admin Controls](https://learn.microsoft.com/copilot/microsoft-365/microsoft-365-copilot-admin) | Via Graph API |

---

## Appendix B: Incident Database Template

Track researched incidents in a structured format:

```markdown
# [Product Name] Security Incident Database

## Incident Index

| Date | Incident Name | Severity | HTH Controls |
|------|--------------|----------|--------------|
| YYYY-MM-DD | [Name] | Critical/High/Medium/Low | [Control IDs] |

## Detailed Incident Records

### INC-001: [Incident Name]
[Full incident details using template from Section 4.2.5]
```

---

## Appendix C: Related Resources

- [HTH Contributing Guide](/contributing/)
- [HTH Versioning Guide](/versions/)
- [HTH Guide Template](/templates/vendor-guide-template.md)
- [Obsidian Security Integrations Hub](https://www.obsidiansecurity.com/obsidian-integrations-hub)
- [Obsidian Security Blog](https://www.obsidiansecurity.com/blog/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks)

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2026-02-04 | 1.0.0 | Initial roadmap creation | Claude Code (Opus 4.5) |
