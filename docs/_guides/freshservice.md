---
layout: guide
title: "Freshservice Hardening Guide"
vendor: "Freshservice"
slug: "freshservice"
tier: "5"
category: "IT Operations"
description: "ITSM security for API tokens, CMDB access, and change management controls"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---


## Overview

Freshservice is an IT service management (ITSM) platform handling IT tickets, asset management, and change management. REST API, OAuth apps, and Freshworks Marketplace integrations access IT infrastructure data. Compromised access exposes asset inventory, configuration data, and potentially privileged access workflows.

### Intended Audience
- Security engineers managing ITSM platforms
- Freshservice administrators
- GRC professionals assessing IT service security
- Third-party risk managers evaluating ITSM integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers Freshservice security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API Security](#2-api-security)
3. [Data Security](#3-data-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML single sign-on and two-factor authentication for all Freshservice agent and admin logins.

#### Rationale
**Why This Matters:**
- Centralizes Freshservice authentication in your corporate IdP, applying MFA and conditional access to every agent and admin login
- Local password logins bypass IdP controls and are prime targets for credential stuffing and phishing
- Enforcing SSO-only login keeps departed agents from retaining standalone credentials that survive IdP deprovisioning
- Agents can read asset inventory, CMDB records, and change workflows, so a single compromised login exposes broad IT infrastructure detail

**Attack Prevented:** Credential theft, phishing, MFA bypass, orphaned-account access

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Admin → Security → Single sign-on**
2. Configure SAML IdP
3. Enable: **Login with SSO only**

**Step 2: Enable 2FA**
1. Navigate to: **Admin → Security**
2. Enable: **Two-factor authentication**
3. Require for all agents

---

### 1.2 Role-Based Access

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Define least-privilege agent roles so each agent receives only the service-desk, CMDB, or change-management permissions their job requires.

#### Rationale
**Why This Matters:**
- Least-privilege roles limit how much asset, ticket, and configuration data any single agent or integration can reach
- Broad default permissions let a compromised agent account export the full CMDB or alter change workflows
- Separating service-desk, asset-manager, and change-manager duties enforces separation of duties and contains insider misuse
- Scoped requester roles keep end users from viewing or modifying agent-only data

**Attack Prevented:** Privilege escalation, lateral movement, insider data exfiltration, unauthorized configuration changes

#### ClickOps Implementation

**Step 1: Define Roles**

| Role | Permissions |
|------|-------------|
| Admin | Full access |
| SD Agent | Service desk functions |
| Asset Manager | CMDB access |
| Change Manager | Change management |
| Requester | Submit tickets only |

**Step 2: Configure Agent Roles**
1. Navigate to: **Admin → Agent Roles**
2. Create custom roles
3. Assign minimum permissions

---

## 2. API Security

### 2.1 Secure API Keys

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Manage Freshservice API keys securely.

#### Rationale
**Attack Scenario:** Compromised API key exports CMDB; asset inventory and configuration data enable targeted attacks on infrastructure.

**Why This Matters:**
- Freshservice API keys grant programmatic access to tickets, the CMDB, and asset data without an interactive login or MFA prompt
- A leaked per-agent key inherits that agent's full permissions and can be abused silently until it is rotated
- Dedicated integration accounts with scoped roles limit blast radius and keep API activity attributable
- Regenerating keys when agents leave prevents orphaned credentials from retaining standing access

**Attack Prevented:** API key theft, CMDB exfiltration, orphaned-credential abuse, untraceable automated access

#### ClickOps Implementation

**Step 1: Audit API Keys**
1. Navigate to: **Profile → API Key**
2. Each agent has unique key
3. Limit who needs API access

**Step 2: Key Management**
1. Regenerate keys when agents leave
2. Use dedicated integration accounts
3. Monitor API usage

---

### 2.2 OAuth App Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7

#### Description
Review the connected OAuth apps and Freshworks Marketplace integrations and remove any that are unused or unnecessary.

#### Rationale
**Why This Matters:**
- Connected OAuth apps and marketplace integrations hold delegated access to Freshservice and can read tickets, assets, and configuration data
- Abandoned or over-permissioned integrations expand the attack surface and are a common supply-chain entry point
- A compromised third-party app becomes a backdoor that bypasses agent authentication and MFA entirely
- Regularly removing unused apps enforces least functionality and reduces standing third-party access

**Attack Prevented:** Supply-chain compromise, OAuth token abuse, data exfiltration via third-party apps, excessive delegated access

#### ClickOps Implementation

**Step 1: Review Connected Apps**
1. Navigate to: **Admin → Apps → Installed Apps**
2. Review all apps
3. Remove unused integrations

---

## 3. Data Security

### 3.1 Protect Asset Data

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Restrict CMDB visibility and ticket access so agents only see the asset records and tickets relevant to their group and role.

#### Rationale
**Why This Matters:**
- The CMDB is a detailed map of IT infrastructure that attackers can use to plan targeted attacks
- Limiting CMDB visibility and restricting sensitive asset types contains exposure if an agent account is compromised
- Ticket-level and agent-group restrictions keep sensitive incident data away from agents who don't need it
- Protecting asset and ticket data supports data-at-rest confidentiality and need-to-know access

**Attack Prevented:** Reconnaissance, sensitive-data disclosure, infrastructure mapping, unauthorized ticket access

#### ClickOps Implementation

**Step 1: Configure CMDB Access**
1. Navigate to: **Admin → Asset Management**
2. Limit CMDB visibility
3. Restrict sensitive asset types

**Step 2: Ticket Security**
1. Configure ticket visibility
2. Limit agent group access
3. Protect sensitive tickets

---

### 3.2 Change Management Security

**Profile Level:** L2 (Walk)
**NIST 800-53:** CM-3

#### Description
Require CAB approval workflows for changes and define a controlled emergency-change process in the Workflow Automator.

#### Rationale
**Why This Matters:**
- Mandatory CAB approval ensures changes are reviewed before they reach production IT systems
- Unapproved or self-approved changes can introduce misconfigurations, outages, or deliberately malicious modifications
- A defined emergency-change path prevents approval controls from being bypassed under time pressure
- Documented approval workflows create an auditable record of who authorized each change

**Attack Prevented:** Unauthorized changes, malicious configuration tampering, change-control bypass, unaudited production modifications

#### ClickOps Implementation

**Step 1: Approval Workflows**
1. Navigate to: **Admin → Workflow Automator**
2. Require CAB approval
3. Configure emergency change process

---

## 4. Monitoring & Detection

### 4.1 Audit Logs

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Enable and regularly review Freshservice audit logs to track agent activity and configuration changes.

#### Rationale
**Why This Matters:**
- Audit logs provide the forensic record needed to detect and investigate account compromise or insider misuse
- Reviewing configuration changes surfaces unauthorized modifications to roles, workflows, or security settings
- Monitoring agent activity helps catch anomalous access patterns such as bulk CMDB exports
- Without comprehensive logging, breaches go undetected and incident response and compliance evidence are impossible

**Attack Prevented:** Undetected breaches, insider abuse, configuration tampering, repudiation of malicious actions

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Admin → Audit Logs**
2. Review agent activities
3. Monitor configuration changes

#### Detection Focus

---

## Appendix A: Edition Compatibility

| Control | Starter | Growth | Pro | Enterprise |
|---------|---------|--------|-----|------------|
| SAML SSO | ❌ | ✅ | ✅ | ✅ |
| Custom Roles | ❌ | ❌ | ✅ | ✅ |
| Audit Logs | ❌ | ❌ | ✅ | ✅ |
| IP Restrictions | ❌ | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Freshservice/Freshworks Documentation:**
- [Freshworks Trust Center (SafeBase)](https://trust.freshworks.com/)
- [Freshworks Security](https://www.freshworks.com/security/)
- [Freshworks Security Resources](https://www.freshworks.com/security/resources/)
- [Freshservice Support Solutions](https://support.freshservice.com/support/solutions)

**API & Developer Documentation:**
- [Freshservice API Reference](https://api.freshservice.com/)
- [Freshworks Developer Portal](https://developers.freshworks.com/)

**Compliance Frameworks:**
- SOC 1 Type II, SOC 2 Type II, ISO 27001, ISO 27701 — via [Trust Center](https://trust.freshworks.com/)
- Annual independent audits by external firms
- Annual VAPT (Vulnerability Assessment and Penetration Testing)
- GDPR compliant

**Security Incidents:**
- No major public security incidents identified affecting the Freshservice platform directly.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Freshservice hardening guide | Claude Code (Opus 4.5) |
