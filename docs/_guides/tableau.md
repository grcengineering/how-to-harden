---
layout: guide
title: "Tableau Hardening Guide"
vendor: "Tableau"
slug: "tableau"
tier: "4"
category: "Data"
description: "BI platform security for site roles, data source credentials, and embed controls"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---


## Overview

Tableau provides business intelligence and data visualization with connections to enterprise data sources. REST API, embedded credentials in workbooks, and data source connections access sensitive business data. Compromised access exposes executive dashboards, financial reports, and aggregated business intelligence.

### Intended Audience
- Security engineers managing BI platforms
- Tableau administrators
- GRC professionals assessing data governance
- Third-party risk managers evaluating analytics integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers Tableau security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Data Source Security](#2-data-source-security)
3. [Content Security](#3-content-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML single sign-on with MFA enforced through your corporate identity provider for all Tableau access.

#### Rationale
**Why This Matters:**
- Centralizes Tableau authentication in your corporate IdP, enforcing MFA and conditional access on every login
- Local Tableau password logins bypass IdP controls and are a prime target for credential stuffing and phishing
- A single compromised login can expose executive dashboards, financial reports, and the connected enterprise data sources behind them
- Session timeout limits the window an attacker can ride a hijacked or unattended session

**Attack Prevented:** Credential theft, phishing, MFA bypass, session hijacking

#### ClickOps Implementation

**Step 1: Configure SAML SSO (Tableau Cloud)**
1. Navigate to: **Settings → Authentication**
2. Configure SAML IdP
3. Enable: **SAML single sign-on**

**Step 2: Enable MFA**
1. Configure MFA through IdP
2. Enforce for all users
3. Configure session timeout

---

### 1.2 Implement Site Roles

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Assign least-privilege site roles and project-level permissions so each user receives only the access their function requires.

#### Rationale
**Why This Matters:**
- Tableau site roles (Viewer through Site Administrator Creator) determine who can view, publish, or administer content and data sources
- Over-broad roles let ordinary users publish, download, or reconfigure content and reach data sources they should never touch
- Project-level permissions and permission templates contain the blast radius if any single account is compromised
- Separating administrator roles from creator and viewer roles enforces separation of duties

**Attack Prevented:** Privilege escalation, unauthorized data access, lateral movement, insider misuse

#### ClickOps Implementation

**Step 1: Define Site Roles**

| Role | Permissions |
|------|-------------|
| Site Administrator Creator | Full site access |
| Site Administrator Explorer | Admin without publish |
| Creator | Create/publish content |
| Explorer | View and interact |
| Viewer | View only |

**Step 2: Configure Project Permissions**
1. Navigate to: **Explore → Projects**
2. Configure project-level permissions
3. Use permission templates

---

## 2. Data Source Security

### 2.1 Secure Data Source Connections

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Protect data source credentials and connections.

#### Rationale
**Why This Matters:**
- Workbooks and data sources can embed database credentials that travel with the file and can be extracted from the packaged workbook
- Dedicated service accounts with least-privilege database grants limit what an extracted credential can reach
- OAuth and prompt-for-credentials connections avoid storing long-lived secrets inside published content entirely
- Published data sources centralize connection governance instead of scattering credentials across many workbooks

**Attack Prevented:** Credential extraction, embedded secret theft, direct database access, application-control bypass

**Attack Scenario:** Embedded database credentials extracted from workbooks; direct database access bypasses application-level controls.

#### ClickOps Implementation

**Step 1: Use Service Accounts**
1. Create dedicated service accounts
2. Limit database permissions
3. Use published data sources

**Step 2: Credential Management**
1. Avoid embedding passwords in workbooks
2. Use OAuth where available
3. Prompt users for credentials

---

### 2.2 Row-Level Security

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-3

#### Description
Apply user filters and data source filters so each user sees only the rows of data they are authorized to view within a shared workbook.

#### Rationale
**Why This Matters:**
- Without row-level security, any user with access to a dashboard can see every row in the underlying data, including other regions, departments, or customers
- User-based filters scope query results to the authenticated user, enforcing data segregation inside a single shared workbook
- Applying filters at the data source prevents bypass by downloading or re-pointing the workbook
- Testing filters with different user identities verifies the control actually withholds unauthorized rows

**Attack Prevented:** Unauthorized data exposure, cross-tenant data leakage, over-broad data access

#### Implementation

**Step 1: Implement User Filters**

**Step 2: Configure Data Source Filters**
1. Create user-based filters
2. Test with different users
3. Document filter logic

---

## 3. Content Security

### 3.1 Workbook Protection

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Lock project-level permissions, remove broad "All Users" grants, and encrypt extracts at rest to protect published workbook content.

#### Rationale
**Why This Matters:**
- Default or inherited "All Users" permissions can silently expose sensitive workbooks to the entire site
- Locking permissions to the project prevents content owners from re-opening access through per-workbook overrides
- Limiting extract downloads stops users from exfiltrating full data extracts to unmanaged devices
- Encrypting extracts at rest protects cached data if the underlying storage is accessed directly

**Attack Prevented:** Unauthorized content access, data exfiltration, exposure of data at rest

#### ClickOps Implementation

**Step 1: Configure Permissions**
1. Set project-level defaults
2. Lock permissions to project
3. Remove "All Users" permissions

**Step 2: Extract Security**
1. Configure extract refresh security
2. Limit extract downloads
3. Encrypt extracts at rest

---

### 3.2 Embedding Security

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-21

#### Description
Restrict embedding to allowed domains via Connected Apps and constrain trusted-authentication ticket lifespan and trusted hosts.

#### Rationale
**Why This Matters:**
- Connected Apps and trusted authentication issue tokens or tickets that grant access to embedded views without an interactive login
- Restricting allowed domains prevents attacker-controlled sites from embedding and abusing your authenticated views
- Short ticket lifespans and a limited set of trusted hosts shrink the window and surface for token replay or forgery
- Monitoring trusted-authentication usage surfaces abuse of the embedding trust relationship

**Attack Prevented:** Token replay, clickjacking, unauthorized embedding, cross-domain content theft

#### Implementation

**Step 1: Connected Apps (Tableau Cloud)**
1. Navigate to: **Settings → Connected Apps**
2. Configure allowed domains
3. Set session timeout

**Step 2: Trusted Authentication**
1. Configure trusted hosts
2. Limit ticket lifespan
3. Monitor trusted authentication usage

---

## 4. Monitoring & Detection

### 4.1 Enable Admin Views

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Use Tableau Admin Views to monitor view traffic, data source access, and user activity for security-relevant events.

#### Rationale
**Why This Matters:**
- Admin Views surface who accessed which views and data sources, providing the audit trail needed to detect misuse
- Without monitoring, credential abuse, data scraping, and unauthorized access go undetected until after damage is done
- Reviewing traffic to views and data source access establishes a behavioral baseline so anomalies stand out
- Activity records support incident investigation and compliance evidence for access-auditing requirements

**Attack Prevented:** Undetected data access, credential abuse, insider data scraping, delayed breach detection

#### ClickOps Implementation

**Step 1: Access Admin Views**
1. Navigate to: **Status → Traffic to Views**
2. Monitor data source access
3. Review user activity

#### Detection Focus

---

## Appendix A: Edition Compatibility

| Control | Tableau Cloud | Tableau Server |
|---------|---------------|----------------|
| SAML SSO | ✅ | ✅ |
| Site Roles | ✅ | ✅ |
| Row-Level Security | ✅ | ✅ |
| Admin Views | ✅ | ✅ |

---

## Appendix B: References

**Official Tableau Documentation:**
- [Tableau Help](https://help.tableau.com/)
- [Tableau Server Security Hardening Checklist](https://help.tableau.com/current/server/en-us/security_harden.htm)
- [Salesforce Compliance Site -- Tableau Cloud](https://compliance.salesforce.com/en/services/tableau-cloud)

**API & Developer Tools:**
- [REST API Reference](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api.htm)
- [Tableau Security Bulletins](https://community.tableau.com/s/security-bulletins)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001:2022, ISO 27017, ISO 27018 -- via [Salesforce Compliance Site](https://compliance.salesforce.com/en)
- Tableau Cloud is covered under Salesforce's umbrella certifications including SOC reports, ISO certifications, and FedRAMP (Government Cloud)

**Security Incidents:**
- (2025) Multiple critical Tableau Server vulnerabilities disclosed, including CVE-2025-26496 (CVSS 9.6) allowing remote code execution and CVE-2025-52446 (CVSS 8.0) enabling arbitrary SQL execution. Patched in Tableau Server versions 2025.1.4, 2024.2.13, and 2023.3.20.
- (2018-2023) Brigham and Women's Hospital research data inadvertently exposed via a publicly accessible Tableau link, disclosing patient PII and health information. Accessible from February 2018 to June 2023.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Tableau hardening guide | Claude Code (Opus 4.5) |
