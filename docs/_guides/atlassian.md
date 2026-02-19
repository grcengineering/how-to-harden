---
layout: guide
title: "Atlassian Cloud Hardening Guide"
vendor: "Atlassian Cloud"
slug: "atlassian"
tier: "2"
category: "Productivity"
description: "Jira/Confluence security for organization policies, app controls, and data residency"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-02-19"
---


## Overview

Atlassian serves **300,000+ customers** with the Atlassian Marketplace hosting **6,000+ apps**. OAuth 2.0, Connect (JWT), and Forge app frameworks create multiple attack vectors. Critical RCE vulnerabilities (CVE-2023-22515, CVSS 10.0; CVE-2022-26134, CVSS 9.8) demonstrated server-side risks. Cloud instances face OAuth token and AppLinks impersonation attacks from compromised Marketplace apps.

### Intended Audience
- Security engineers managing Atlassian products
- IT administrators configuring Jira and Confluence
- GRC professionals assessing collaboration tool security
- Third-party risk managers evaluating Marketplace apps

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Atlassian Cloud and Data Center security configurations including authentication, Marketplace app governance, API security, and AppLinks hardening.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Marketplace App Security](#2-marketplace-app-security)
3. [API & Integration Security](#3-api--integration-security)
4. [Data Security](#4-data-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Vulnerability Management](#6-vulnerability-management)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Baseline)
**CIS Controls:** 6.3, 6.5
**NIST 800-53:** IA-2(1)

#### Description
Require SAML SSO with MFA for all Atlassian Cloud access, eliminating local password authentication.

#### Rationale
**Why This Matters:**
- Jira contains vulnerability tracking and security issues
- Confluence stores technical documentation and architecture
- Compromised access exposes sensitive project information

**Attack Scenario:** Compromised Marketplace app accesses Jira vulnerability tracking and Confluence technical documentation.

#### ClickOps Implementation (Atlassian Cloud)

**Step 1: Configure SAML SSO**
1. Navigate to: **admin.atlassian.com → Security → SAML single sign-on**
2. Click **Add SAML configuration**
3. Configure:
   - **Identity provider:** Your IdP (Okta, Azure AD, etc.)
   - **Entity ID:** From IdP
   - **SSO URL:** IdP login endpoint
4. Upload IdP certificate

**Step 2: Enforce SSO**
1. Navigate to: **Security → Authentication policies**
2. Create policy:
   - **Name:** "SSO Required"
   - **Members:** All users
   - **Settings:**
     - Require SSO: Enabled
     - Allow local passwords: Disabled

**Step 3: Configure Two-Step Verification**
1. Navigate to: **Security → Two-step verification**
2. Enable: **Require two-step verification for all users**
3. Configure:
   - **Enforcement:** Required
   - **Grace period:** None (L2)

#### Code Implementation

{% include pack-code.html vendor="atlassian" section="1.1" %}

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-2(1) | MFA for network access |

---

### 1.2 Implement Granular Product Access

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure product-level and project-level access controls.

#### ClickOps Implementation

**Step 1: Configure Product Access**
1. Navigate to: **admin.atlassian.com → Products**
2. For each product, configure:
   - **Default access:** Disabled (users must be granted access)
   - **User access:** Specific groups only

**Step 2: Configure Jira Project Permissions**
1. Navigate to: **Jira → Project settings → Permissions**
2. Use permission schemes:
   - **Secure Project Scheme:** Limited browse, restricted commenting
   - **Internal Project Scheme:** Standard internal access
   - **Public Project Scheme:** Read-only for wider team

**Step 3: Configure Confluence Space Permissions**
1. Navigate to: **Confluence → Space settings → Permissions**
2. Configure:
   - **Anonymous access:** Disabled
   - **Group permissions:** Specific groups per space
   - **Default permissions:** View only for most users

---

### 1.3 Configure API Token Policies

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Control API token creation and implement expiration policies.

#### ClickOps Implementation

**Step 1: Configure Token Settings**
1. Navigate to: **admin.atlassian.com → Security → API tokens**
2. Configure:
   - **Allow users to create API tokens:** Controlled (Premium/Enterprise)
   - **Token expiration:** 90 days maximum

**Step 2: Audit Existing Tokens**
1. Navigate to: **Security → API tokens → Token controls**
2. Review active tokens
3. Revoke unused or suspicious tokens

---

## 2. Marketplace App Security

### 2.1 Implement App Approval Workflow

**Profile Level:** L1 (Baseline) - CRITICAL
**NIST 800-53:** CM-7

#### Description
Require admin approval for Marketplace app installation. Apps have broad access to Jira/Confluence data.

#### Rationale
**Why This Matters:**
- 6,000+ Marketplace apps with varying security postures
- Apps access project data, user information, and configurations
- Compromised or malicious apps enable data exfiltration

#### ClickOps Implementation

**Step 1: Configure App Installation Policy**
1. Navigate to: **admin.atlassian.com → Security → App policies**
2. Configure:
   - **Who can install apps:** Admins only
   - **User install requests:** Require approval
   - **App block list:** Add prohibited apps

**Step 2: Review Existing Apps**
1. Navigate to: **admin.atlassian.com → Apps**
2. For each app, review:
   - Permissions/scopes requested
   - Last updated date
   - Security certifications
   - User count and reviews
3. Remove unused or suspicious apps

**Step 3: Create App Evaluation Checklist**
Before approving any app:
- [ ] Review requested permissions (OAuth scopes)
- [ ] Check vendor security certifications (SOC 2, ISO 27001)
- [ ] Review app update frequency
- [ ] Check for known vulnerabilities
- [ ] Evaluate data access requirements
- [ ] Document business justification

#### Marketplace App Risk Assessment

| Permission | Risk Level | Questions to Ask |
|------------|------------|------------------|
| Read Jira issues | Medium | Which projects? |
| Write Jira issues | High | Can it delete? |
| Read Confluence content | Medium | Which spaces? |
| Admin access | Critical | Why needed? |
| User management | Critical | Business justification? |
| Act on behalf of users | High | What actions? |

---

### 2.2 Monitor App Activity

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AU-6

#### Description
Monitor Marketplace app API calls and data access.

#### Code Implementation

{% include pack-code.html vendor="atlassian" section="2.2" %}

---

## 3. API & Integration Security

### 3.1 Secure AppLinks Configuration

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-8

#### Description
Harden AppLinks between Atlassian products to prevent impersonation attacks.

#### ClickOps Implementation (Data Center)

**Step 1: Audit Existing AppLinks**
1. Navigate to: **Administration → Application links**
2. Review all configured links
3. Verify each link is still needed

**Step 2: Configure OAuth 2.0 for AppLinks**
1. For each AppLink, configure:
   - **Authentication type:** OAuth 2.0 (not OAuth 1.0a)
   - **Incoming/Outgoing trust:** Verify both directions

**Step 3: Restrict AppLinks Creation**
- Limit AppLinks creation to administrators only
- Document approved integration patterns

---

### 3.2 Configure Webhook Security

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-8

#### Description
Secure webhook configurations to prevent data leakage.

#### ClickOps Implementation

**Step 1: Audit Webhooks**
1. Navigate to: **System → Webhooks** (Jira)
2. Review all configured webhooks:
   - Destination URLs (should be internal or verified services)
   - Events subscribed
   - JQL filters (limit scope)

**Step 2: Secure Webhook Endpoints**
- Require HTTPS for all webhook URLs
- Implement webhook signature validation
- Limit events to necessary minimum

{% include pack-code.html vendor="atlassian" section="3.2" %}

---

### 3.3 OAuth Token Management

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5(13)

#### Description
Manage OAuth tokens for third-party integrations.

#### ClickOps Implementation

**Step 1: Review Authorized Applications**
1. Navigate to: **Profile → Security → Connected apps**
2. Review apps with OAuth access
3. Revoke unnecessary authorizations

**Step 2: Configure OAuth App Policies**
1. Navigate to: **admin.atlassian.com → Security → External apps**
2. Configure:
   - **App approval:** Required for new apps
   - **Scope review:** Admin approval for sensitive scopes

---

## 4. Data Security

### 4.1 Configure Data Residency

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-28

#### Description
Configure data residency for compliance with data localization requirements.

#### ClickOps Implementation (Enterprise)

**Step 1: Configure Data Residency**
1. Navigate to: **admin.atlassian.com → Data residency**
2. Select realm for data storage:
   - US
   - EU
   - Australia
3. Apply to products

---

### 4.2 Implement Data Classification

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-3

#### Description
Use data classification to restrict access to sensitive content.

#### ClickOps Implementation

**Step 1: Enable Classification (Enterprise)**
1. Navigate to: **admin.atlassian.com → Data classification**
2. Create classification levels:
   - Public
   - Internal
   - Confidential
   - Restricted

**Step 2: Apply to Spaces/Projects**
1. Classify Confluence spaces
2. Classify Jira projects
3. Configure access based on classification

---

## 5. Monitoring & Detection

### 5.1 Enable Audit Logging

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### Description
Configure and monitor Atlassian audit logs.

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **admin.atlassian.com → Security → Audit log**
2. Review events:
   - Authentication events
   - Permission changes
   - App installations
   - Data exports

**Step 2: Configure SIEM Export**
1. Navigate to: **Settings → Audit log streaming** (Enterprise)
2. Configure destination:
   - Splunk
   - Sumo Logic
   - Custom webhook

#### Detection Queries

```sql
-- Detect bulk data access
SELECT user_id, action, COUNT(*) as action_count
FROM atlassian_audit_log
WHERE action IN ('content.view', 'issue.view')
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_id, action
HAVING COUNT(*) > 100;

-- Detect permission changes
SELECT *
FROM atlassian_audit_log
WHERE action LIKE '%permission%'
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect app installations
SELECT *
FROM atlassian_audit_log
WHERE action = 'app.installed'
  AND timestamp > NOW() - INTERVAL '7 days';
```

---

### 5.2 Configure Anomaly Detection

**Profile Level:** L2 (Hardened)

#### Description
Enable Atlassian Access anomaly detection (Enterprise).

#### ClickOps Implementation

1. Navigate to: **admin.atlassian.com → Security → Anomaly detection**
2. Enable detection for:
   - Unusual login locations
   - Bulk data access
   - Permission changes
3. Configure alert recipients

---

## 6. Vulnerability Management

### 6.1 Critical CVE Response

**Profile Level:** L1 (Baseline)

#### Description
Recent critical vulnerabilities require immediate attention.

#### Recent Critical CVEs

| CVE | CVSS | Product | Description |
|-----|------|---------|-------------|
| CVE-2023-22515 | 10.0 | Confluence DC/Server | Broken access control, admin account creation |
| CVE-2023-22518 | 9.8 | Confluence DC/Server | Auth bypass, data destruction |
| CVE-2022-26134 | 9.8 | Confluence Server/DC | OGNL injection RCE |
| CVE-2021-26084 | 9.8 | Confluence Server/DC | OGNL injection RCE |

#### Response Actions

**For Data Center/Server:**
1. Apply patches immediately
2. Review access logs for exploitation attempts
3. Check for unauthorized admin accounts
4. Consider migration to Cloud

**For Cloud:**
- Atlassian manages patching
- Monitor Atlassian security advisories
- Review audit logs for suspicious activity

---

## 7. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | Atlassian Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO enforcement | 1.1 |
| CC6.2 | Product/project permissions | 1.2 |
| CC7.2 | Audit logging | 5.1 |

### NIST 800-53 Mapping

| Control | Atlassian Control | Guide Section |
|---------|------------------|---------------|
| IA-2(1) | SSO with MFA | 1.1 |
| CM-7 | App approval workflow | 2.1 |
| AU-2 | Audit logging | 5.1 |

---

## Appendix A: Edition Compatibility

| Control | Free | Standard | Premium | Enterprise |
|---------|------|----------|---------|------------|
| SSO (SAML) | ❌ | ❌ | ✅ | ✅ |
| MFA | ✅ | ✅ | ✅ | ✅ |
| Audit Logs | Basic | Basic | ✅ | ✅ |
| App Policies | ❌ | ❌ | ✅ | ✅ |
| Data Classification | ❌ | ❌ | ❌ | ✅ |
| Anomaly Detection | ❌ | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Atlassian Documentation:**
- [Trust Center](https://www.atlassian.com/trust) | [Customer Trust Center](https://customertrust.atlassian.com/) (powered by Conveyor)
- [Atlassian Support](https://support.atlassian.com/)
- [Security Best Practices](https://support.atlassian.com/security-and-access-policies/)
- [Security Practices](https://www.atlassian.com/trust/security/security-practices)
- [Security Measures](https://www.atlassian.com/legal/security-measures)
- [Vulnerability Disclosure](https://www.atlassian.com/trust/data-protection/vulnerabilities)
- [Security Advisories](https://www.atlassian.com/trust/security/advisories)

**API & Developer Tools:**
- [Atlassian Developer Portal](https://developer.atlassian.com/)
- [Jira Cloud REST API](https://developer.atlassian.com/cloud/jira/platform/rest/)
- [Confluence Cloud REST API](https://developer.atlassian.com/cloud/confluence/rest/)
- [Forge App Framework](https://developer.atlassian.com/platform/forge/) (SOC 2 and ISO 27001 compliant)
- [API Security Guide](https://developer.atlassian.com/cloud/jira/platform/security/)
- [GitHub Organization](https://github.com/atlassian)

**Compliance Frameworks:**
- SOC 2 Type II (individual product audits on a regular basis) — via [SOC 2 Compliance](https://www.atlassian.com/trust/compliance/resources/soc2)
- ISO/IEC 27001:2022 (Atlassian Trust Management System) — via [ISO 27001 Compliance](https://www.atlassian.com/trust/compliance/resources/iso27001)
- SOX compliance, PCI DSS
- [Compliance Resource Center](https://www.atlassian.com/trust/compliance/resources) | [Compliance FAQ](https://www.atlassian.com/trust/compliance/compliance-faq)

**Security Incidents:**
- **2023 — Critical Confluence CVEs:** CVE-2023-22515 (CVSS 10.0) and CVE-2023-22518 (CVSS 9.8) affected Confluence Data Center/Server with broken access control and auth bypass vulnerabilities. Actively exploited in the wild. Cloud instances were not affected. ([Security Advisories](https://www.atlassian.com/trust/security/advisories))
- **February 2023 — Employee Data Leak via Envoy:** Hackers leaked Atlassian employee records and office floorplans obtained through a breach of third-party workplace platform Envoy. No customer data was affected. ([SecurityWeek Report](https://www.securityweek.com/atlassian-investigating-security-breach-after-hackers-leak-data/))

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial Atlassian hardening guide | Claude Code (Opus 4.5) |
| 2026-02-19 | 0.2.0 | draft | Extract inline code to Code Packs (api, sdk) | Claude Code (Opus 4.6) |
