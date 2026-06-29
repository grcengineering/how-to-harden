---
layout: guide
title: "Power BI Hardening Guide"
vendor: "Power BI"
slug: "power-bi"
tier: "5"
category: "Data"
description: "Microsoft BI security for tenant settings, gateway credentials, and embed controls"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---


## Overview

Microsoft Power BI provides business intelligence with data connections across enterprise sources. REST API, embed tokens, and dataflows access sensitive business data. Compromised access exposes executive dashboards, financial reports, and aggregated business intelligence through the Microsoft 365 ecosystem.

### Intended Audience
- Security engineers managing BI platforms
- Power BI administrators
- GRC professionals assessing analytics security
- Third-party risk managers evaluating Microsoft integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers Power BI security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Content Security](#2-content-security)
3. [Data Source Security](#3-data-source-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Conditional Access

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require Azure AD Conditional Access policies (MFA and device compliance) for all Power BI access and enable Microsoft Information Protection sensitivity labels on tenant content.

#### Rationale
**Why This Matters:**
- Conditional Access enforces MFA and device-compliance checks on every Power BI sign-in, closing the gap that password-only authentication leaves open
- Power BI inherits Azure AD identity, so policies set centrally apply uniformly across the Microsoft 365 ecosystem instead of per-report
- Sensitivity labels travel with exported reports and datasets, keeping protection in place when content leaves the service
- Executive dashboards and financial reports are high-value targets, and unconditional access lets a single stolen credential reach all of them

**Attack Prevented:** Credential theft, phishing, MFA bypass, access from unmanaged or non-compliant devices

#### ClickOps Implementation

**Step 1: Configure Conditional Access (Azure AD)**
1. Navigate to: **Azure AD → Conditional Access**
2. Create policy for Power BI
3. Require MFA
4. Configure device compliance

**Step 2: Enable Sensitivity Labels**
1. Navigate to: **Power BI Admin Portal → Tenant settings**
2. Enable: **Information protection**
3. Configure label inheritance

---

### 1.2 Workspace Access Controls

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Assign least-privilege workspace roles (Admin, Member, Contributor, Viewer) per team and limit external sharing so users receive only the access their function requires.

#### Rationale
**Why This Matters:**
- Granular workspace roles enforce least privilege, so a Viewer cannot publish or alter datasets and a Contributor cannot reassign permissions
- Per-team workspaces contain the blast radius of a compromised account to that team's content rather than the whole tenant
- Restricting external sharing at the workspace level prevents sensitive reports from leaking to guests or unmanaged identities
- Over-broad Admin and Member grants are a common path to privilege escalation and unauthorized data exposure

**Attack Prevented:** Privilege escalation, unauthorized data modification, lateral movement, oversharing to external users

#### ClickOps Implementation

**Step 1: Define Workspace Roles**

| Role | Permissions |
|------|-------------|
| Admin | Full workspace control |
| Member | Edit and publish |
| Contributor | Edit only |
| Viewer | View only |

**Step 2: Configure Workspace Settings**
1. Create workspaces per team
2. Assign minimum required roles
3. Limit external sharing

---

## 2. Content Security

### 2.1 Configure Sharing Defaults

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-21

#### Description
Control report and dashboard sharing.

#### Rationale
**Attack Scenario:** Public publish to web exposes financial reports; embed tokens enable unauthorized dashboard access.

**Why This Matters:**
- Disabling Publish to web prevents reports from being exposed anonymously on the public internet where anyone with the link can read them
- Restricting external sharing keeps business intelligence inside the organization's identity boundary
- Limiting and auditing export formats stops data from being copied out of governed reports into ungoverned spreadsheets
- Default-open sharing settings are a common cause of accidental financial and customer-data exposure in Power BI

**Attack Prevented:** Anonymous public data exposure, data exfiltration via export, oversharing to external users

#### ClickOps Implementation

**Step 1: Tenant Settings**
1. Navigate to: **Power BI Admin Portal → Tenant settings**
2. Configure:
   - **Publish to web:** Disabled
   - **Share content externally:** Restricted
   - **Allow external users to edit:** Disabled

**Step 2: Export Controls**
1. Configure: **Export data** settings
2. Limit export formats
3. Audit export activity

---

### 2.2 Embed Security

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-21

#### Description
Secure embedded analytics by using the app-owns-data pattern with a service principal, enforcing row-level security, setting short token expirations, and restricting who can generate embed tokens.

#### Rationale
**Why This Matters:**
- The app-owns-data pattern with a service principal keeps master credentials out of client code and centralizes embed authorization
- Row-level security ensures an embed token only returns the rows the end user is entitled to, even though the app authenticates as a single identity
- Short-lived embed tokens limit the window in which an intercepted or leaked token can be replayed
- Unrestricted embed-token generation lets any developer mint access to sensitive dashboards outside governed sharing controls

**Attack Prevented:** Embed token theft and replay, cross-user and cross-tenant data leakage, unauthorized dashboard access

#### Implementation

**Step 1: Secure Embed Tokens**
1. Use app owns data pattern with service principal
2. Implement row-level security
3. Set token expiration

**Step 2: Embed Controls**
1. Navigate to: **Tenant settings → Developer settings**
2. Restrict who can embed
3. Limit embed token generation

---

## 3. Data Source Security

### 3.1 Gateway Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Limit on-premises data gateway administrators, review stored data source credentials, use dedicated service accounts with minimal database permissions, and rotate those credentials regularly.

#### Rationale
**Why This Matters:**
- The gateway stores credentials to on-premises databases, so a compromised gateway admin can reach every connected source
- Limiting gateway administrators reduces the number of identities that can repoint connections or read stored credentials
- Service accounts scoped to least-privilege database permissions cap what a leaked credential can actually do
- Regular credential rotation shrinks the value of any credential that is captured or exposed

**Attack Prevented:** Credential theft, lateral movement into on-premises databases, standing-credential abuse, privilege escalation

#### ClickOps Implementation

**Step 1: Manage Gateway Users**
1. Navigate to: **Settings → Manage gateways**
2. Limit gateway admins
3. Review data source credentials

**Step 2: Data Source Credentials**
1. Use service accounts
2. Limit database permissions
3. Rotate credentials periodically

---

### 3.2 Row-Level Security

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-3

#### Description
Define and test row-level security (RLS) roles so users only see the dataset rows they are authorized to view, then validate enforcement with the "View as" feature.

#### Rationale
**Why This Matters:**
- RLS enforces data segregation inside a shared dataset, so one report can serve many audiences without exposing each other's rows
- Without RLS, any user with report access can see all underlying records, including other regions, teams, or customers
- Testing with "View as" catches misconfigured filters before they leak data in production
- RLS is the primary control preventing horizontal data exposure in multi-tenant or multi-team dashboards

**Attack Prevented:** Unauthorized data access, horizontal data exposure across tenants and teams, broken access control

#### Implementation

**Step 1: Define RLS Roles**

{% include pack-code.html vendor="power-bi" section="3.2" %}

**Step 2: Test RLS**
1. Use "View as" feature
2. Test with different users
3. Audit RLS effectiveness

---

## 4. Monitoring & Detection

### 4.1 Activity Log

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Enable and retain the Power BI activity log (or the Microsoft 365 unified audit log) to record user and admin actions such as sharing, exports, and access changes.

#### Rationale
**Why This Matters:**
- Activity logs provide the audit trail needed to detect suspicious sharing, mass exports, or unexpected admin changes
- Without retained logs, incident responders cannot reconstruct what data was accessed or exfiltrated and when
- Centralizing in the Microsoft 365 unified audit log correlates Power BI events with the rest of the tenant's activity
- Adequate retention satisfies compliance evidence requirements and supports forensic investigation

**Attack Prevented:** Undetected data exfiltration, insider abuse, delayed breach detection, audit-trail gaps

#### ClickOps Implementation

**Step 1: Access Activity Log**
1. Navigate to: **Power BI Admin Portal → Audit logs**
2. Or use: **Microsoft 365 Compliance → Audit**
3. Configure log retention

#### Detection Focus

{% include pack-code.html vendor="power-bi" section="4.1" %}

---

## Appendix A: Edition Compatibility

| Control | Pro | Premium |
|---------|-----|---------|
| Conditional Access | ✅ | ✅ |
| Sensitivity Labels | ✅ | ✅ |
| Audit Logs | ✅ | ✅ |
| BYOK Encryption | ❌ | ✅ |

---

## Appendix B: References

**Official Microsoft Documentation:**
- [Microsoft Trust Center](https://www.microsoft.com/en-us/trust-center)
- [Power BI Security](https://powerbi.microsoft.com/en-us/security/)
- [Power BI Documentation](https://learn.microsoft.com/en-us/power-bi/)
- [Power BI Security Whitepaper](https://learn.microsoft.com/en-us/power-bi/guidance/white-paper-powerbi-security)
- [Compliance and Data Privacy](https://learn.microsoft.com/en-us/power-platform/admin/wp-compliance-data-privacy)

**API Documentation:**
- [Power BI REST API Reference](https://learn.microsoft.com/en-us/rest/api/power-bi/)

**Compliance Frameworks:**
- SOC 1 Type II, SOC 2 Type II, ISO 27001, ISO 27018, FedRAMP, HIPAA BAA, PCI DSS, FINRA, IL6, EU Model Clauses, UK G-Cloud, and 100+ additional standards — via [Microsoft Trust Center](https://www.microsoft.com/en-us/trust-center)

**Security Incidents:**
- No major public security incidents specific to Power BI have been identified. Power BI security is managed as part of the broader Microsoft 365 / Azure ecosystem. Refer to the [Microsoft Security Response Center](https://msrc.microsoft.com/) for Microsoft-wide security advisories.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Power BI hardening guide | Claude Code (Opus 4.5) |
