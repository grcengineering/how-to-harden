---
layout: guide
title: "Looker Hardening Guide"
vendor: "Looker"
slug: "looker"
tier: "5"
category: "Data"
description: "Google BI security for model access, embed secrets, and database connections"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-12-14"
---


## Overview

Looker (Google Cloud) provides business intelligence with LookML modeling and data exploration. REST API, embed secrets, and database connections access enterprise data warehouses. Compromised access exposes business metrics, customer analytics, and data warehouse credentials.

### Intended Audience
- Security engineers managing BI platforms
- Looker administrators
- GRC professionals assessing analytics security
- Third-party risk managers evaluating Google Cloud integrations


### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries


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

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

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

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

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

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3

#### Description
Control content access through folder hierarchy.

#### Rationale
**Attack Scenario:** Open folder permissions expose executive dashboards; shared folder access leaks competitive metrics.

#### ClickOps Implementation

**Step 1: Folder Structure**

{% include pack-code.html vendor="looker" section="2.1" %}

**Step 2: Configure Access**
1. Navigate to: **Browse → Folder → Manage Access**
2. Set appropriate permissions
3. Limit "View" access default

---

### 2.2 Embed Security

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-21

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

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

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

**Profile Level:** L2 (Hardened)
**NIST 800-53:** CM-7

#### Implementation

**Step 1: Configure Limits**
1. Navigate to: **Admin → General → Query**
2. Set query timeout
3. Configure row limits

---

## 4. Monitoring & Detection

### 4.1 System Activity

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### ClickOps Implementation

**Step 1: Access System Activity**
1. Navigate to: **Admin → System Activity**
2. Review dashboards:
   - User Activity
   - Query Performance
   - Content Usage

#### Detection Focus

{% include pack-code.html vendor="looker" section="4.1" %}

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
| 2025-12-14 | 0.1.0 | draft | Initial Looker hardening guide | Claude Code (Opus 4.5) |
