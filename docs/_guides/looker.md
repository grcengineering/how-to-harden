---
layout: guide
title: "Looker Hardening Guide"
vendor: "Looker"
slug: "looker"
tier: "5"
category: "Data"
description: "Google BI security for model access, embed secrets, and database connections"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---


## Overview

Looker (Google Cloud) provides business intelligence with LookML modeling and data exploration. REST API, embed secrets, and database connections access enterprise data warehouses. Compromised access exposes business metrics, customer analytics, and data warehouse credentials.

### Intended Audience
- Security engineers managing BI platforms
- Looker administrators
- GRC professionals assessing analytics security
- Third-party risk managers evaluating Google Cloud integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers Looker security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Content Security](#2-content-security)
3. [Database Connection Security](#3-database-connection-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML or Google OAuth single sign-on with MFA for all Looker access and disable local Looker password logins.

#### Rationale
**Why This Matters:**
- Centralizes Looker authentication in your corporate IdP so MFA and conditional access apply to every login to the BI platform
- Local Looker password accounts bypass IdP controls and are prime targets for credential stuffing and phishing
- SSO with directory provisioning deprovisions departed users automatically, eliminating orphaned accounts with standing access to dashboards and data
- Looker brokers direct connections to enterprise data warehouses, so a single compromised login can expose business metrics and customer analytics

**Attack Prevented:** Credential theft, phishing, MFA bypass, orphaned-account access

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Admin → Authentication → SAML**
2. Configure SAML IdP
3. Enable: **Bypass login page**

**Step 2: Google OAuth**
1. Navigate to: **Admin → Authentication → Google**
2. Enable Google OAuth
3. Configure domain restrictions

---

### 1.2 Role-Based Access

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Define least-privilege roles by pairing Looker permission sets with model sets, and assign each user the minimum role they need (Admin, Developer, User, or Viewer).

#### Rationale
**Why This Matters:**
- Looker roles combine permission sets and model sets to scope both what a user can do and which LookML models (and underlying data) they can reach
- Over-broad roles let ordinary users develop LookML, manage connections, or view content outside their need-to-know
- The Admin role can change database connections, embed secrets, and authentication settings, so it must be tightly restricted to a small group
- Least privilege limits the blast radius if any single account is compromised

**Attack Prevented:** Privilege escalation, unauthorized data access, lateral movement, insider misuse

#### ClickOps Implementation

**Step 1: Define Roles**

| Role | Permissions |
|------|-------------|
| Admin | Full access |
| Developer | Model development |
| User | Explore and save |
| Viewer | View only |

**Step 2: Configure Model Sets**
1. Navigate to: **Admin → Roles**
2. Create custom roles
3. Assign model/permission sets

---

## 2. Content Security

### 2.1 Configure Folder Permissions

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3

#### Description
Control content access through folder hierarchy.

#### Rationale
**Attack Scenario:** Open folder permissions expose executive dashboards; shared folder access leaks competitive metrics.

**Why This Matters:**
- Folder permissions are the primary control over who can view and manage dashboards, Looks, and saved content
- Default-open or broadly shared folders expose executive dashboards and competitive metrics to users outside their need-to-know
- Granular access levels (View versus Manage) prevent users from editing or resharing content beyond their role

**Attack Prevented:** Unauthorized content access, data leakage, oversharing of sensitive dashboards

#### ClickOps Implementation

**Step 1: Folder Structure**

**Step 2: Configure Access**
1. Navigate to: **Browse → Folder → Manage Access**
2. Set appropriate permissions
3. Limit "View" access default

---

### 2.2 Embed Security

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-21

#### Description
Rotate embed secrets, restrict embedding to an allowlisted set of domains, and use signed SSO embed URLs with short session lengths and user attributes to scope the data each viewer can see.

#### Rationale
**Why This Matters:**
- Embed secrets sign the URLs that grant access to embedded Looker content, so a leaked or stale secret lets an attacker forge authenticated embed sessions
- A domain allowlist prevents attacker-controlled sites from hosting your embedded dashboards and harvesting data
- User attributes in signed SSO embeds enforce row-level and access filtering so each embedded viewer sees only their own data
- Short session lengths limit how long a stolen or replayed embed URL remains usable

**Attack Prevented:** Embed URL forgery, secret leakage, cross-tenant data exposure, unauthorized embedding

#### Implementation

**Step 1: Manage Embed Secrets**
1. Navigate to: **Admin → Platform → Embed**
2. Rotate embed secrets
3. Configure embed domain allowlist

**Step 2: SSO Embed**
1. Use signed embed URLs
2. Set short session lengths
3. Implement user attributes

---

## 3. Database Connection Security

### 3.1 Secure Database Connections

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Configure Looker database connections to use SSL/TLS with a least-privilege, read-only service account, and use separate restricted credentials with limited temp-schema access for persistent derived tables (PDTs).

#### Rationale
**Why This Matters:**
- Looker stores the credentials it uses to query your data warehouse, making the connection account a high-value target
- A read-only service account ensures a compromised Looker instance cannot modify or delete source data
- SSL/TLS protects warehouse credentials and query results in transit from interception
- Separate, scoped PDT credentials with restricted temp-schema access confine write access to only the schemas Looker actually needs

**Attack Prevented:** Credential theft, data tampering, man-in-the-middle interception, lateral movement into the data warehouse

#### ClickOps Implementation

**Step 1: Connection Security**
1. Navigate to: **Admin → Database → Connections**
2. Use SSL/TLS connections
3. Configure service account with read-only

**Step 2: PDT Credentials**
1. Limit PDT write permissions
2. Use separate credentials
3. Restrict temp schema access

---

### 3.2 Query Cost Controls

**Profile Level:** L2 (Walk)
**NIST 800-53:** CM-7

#### Description
Set query timeouts and row limits so that a single Explore or query cannot exhaust data warehouse resources.

#### Rationale
**Why This Matters:**
- Unbounded queries can consume excessive data warehouse compute, driving runaway costs and starving other workloads
- Query timeouts and row limits cap the resources any single user or query can consume
- These limits blunt denial-of-service attempts and accidental runaway queries against shared infrastructure
- Predictable resource ceilings protect availability for all users sharing the database connection

**Attack Prevented:** Denial of service, resource exhaustion, runaway query cost abuse

#### Implementation

**Step 1: Configure Limits**
1. Navigate to: **Admin → General → Query**
2. Set query timeout
3. Configure row limits

---

## 4. Monitoring & Detection

### 4.1 System Activity

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Review Looker's built-in System Activity dashboards to monitor user activity, query performance, and content usage for anomalies.

#### Rationale
**Why This Matters:**
- System Activity surfaces who is logging in, what they are querying, and which content they access — the data needed to detect misuse
- Without regular review, credential compromise, data scraping, and privilege abuse can go undetected
- Query and content-usage dashboards reveal anomalous bulk extraction or access to sensitive dashboards
- Activity records support incident investigation and compliance audit requirements

**Attack Prevented:** Undetected account compromise, data exfiltration, insider misuse, audit gaps

#### ClickOps Implementation

**Step 1: Access System Activity**
1. Navigate to: **Admin → System Activity**
2. Review dashboards:
   - User Activity
   - Query Performance
   - Content Usage

#### Detection Focus

---

## Appendix A: Edition Compatibility

| Control | Standard | Enterprise | Embed |
|---------|----------|------------|-------|
| SAML SSO | ✅ | ✅ | ✅ |
| Custom Roles | ✅ | ✅ | ✅ |
| System Activity | ✅ | ✅ | ✅ |
| SSO Embed | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Looker / Google Cloud Documentation:**
- [Google Cloud Trust Center](https://cloud.google.com/security)
- [Looker Documentation](https://docs.cloud.google.com/looker/docs)
- [How to Keep Looker Secure](https://cloud.google.com/looker/docs/best-practices/how-to-keep-looker-secure)
- [Google Cloud Compliance Reports Manager](https://cloud.google.com/security/compliance/compliance-reports-manager)

**API & Developer Resources:**
- [Looker REST API Reference](https://docs.cloud.google.com/looker/docs/reference/looker-api/latest)
- [Looker SDK](https://cloud.google.com/looker/docs/api-sdk)

**Compliance Frameworks:**
- SOC 2 Type II, SOC 3, ISO 27001 (as part of Google Cloud Platform) -- via [Google Cloud Compliance](https://cloud.google.com/security/compliance). Looker (Google Cloud) inherits GCP compliance certifications including SOC 2, ISO 27001, ISO 27017, ISO 27018, FedRAMP, and HIPAA.

**Security Incidents:**
- No major Looker-specific public security breaches identified. Looker inherits the security posture of Google Cloud Platform. Google Cloud publishes security bulletins at [cloud.google.com/support/bulletins](https://cloud.google.com/support/bulletins).

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Looker hardening guide | Claude Code (Opus 4.5) |
