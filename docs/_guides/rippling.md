---
layout: guide
title: "Rippling Hardening Guide"
vendor: "Rippling"
slug: "rippling"
tier: "5"
category: "HR/IT"
description: "Workforce platform security for app provisioning, device management, and SCIM controls"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-12-14"
---


## Overview

Rippling is a unified workforce platform managing HR, IT, payroll, and spend. REST API, SSO configurations, and deep SaaS integrations through device management access employee PII, financial data, and IT systems. Compromised access has cascading effects across multiple business functions.

### Intended Audience
- Security engineers managing workforce platforms
- Rippling administrators
- GRC professionals assessing unified platform security
- Third-party risk managers evaluating HR/IT integrations

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Integration Security](#2-integration-security)
3. [Data Security](#3-data-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Configure SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### ClickOps Implementation

**Step 1: Configure SSO**
1. Navigate to: **Settings → Security → Single Sign-On**
2. Configure SAML IdP
3. Enable SSO enforcement

**Step 2: Enable MFA**
1. Navigate to: **Settings → Security → Multi-Factor Authentication**
2. Require MFA for all users
3. Configure phishing-resistant methods

---

### 1.2 Role-Based Access

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### ClickOps Implementation

**Step 1: Define Permission Sets**

| Role | Permissions |
|------|---------|----------|---------|--------|----|
| Super Admin | Full access |
| HR Admin | HR/payroll functions |
| IT Admin | Device/app management |
| Finance Admin | Spend management |
| Manager | Team access |
| Employee | Self-service |

**Step 2: Configure Custom Roles**
1. Navigate to: **Settings → Permissions**
2. Create custom permission sets
3. Apply least privilege

---

## 2. Integration Security

### 2.1 App Management Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### Description
Secure Rippling app integrations.

#### Rationale
**Attack Scenario:** Compromised Rippling admin provisions access to connected apps; single compromise cascades across all integrated SaaS.

#### ClickOps Implementation

**Step 1: Review Connected Apps**
1. Navigate to: **Apps → Installed Apps**
2. Audit all connected applications
3. Remove unused integrations

**Step 2: SCIM Security**
1. Review SCIM provisioning
2. Limit auto-provisioning scope
3. Audit deprovisioning

---

### 2.2 Device Management Security

**Profile Level:** L2 (Hardened)
**NIST 800-53:** CM-7

#### ClickOps Implementation

**Step 1: Device Policies**
1. Navigate to: **IT → Device Management**
2. Configure security policies
3. Require device enrollment

---

## 3. Data Security

### 3.1 Protect Employee Data

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### ClickOps Implementation

**Step 1: Configure Field Access**
1. Limit visibility of sensitive fields
2. Restrict SSN/bank account access
3. Configure manager visibility

**Step 2: Report Security**
1. Limit report access
2. Restrict bulk exports
3. Audit data access

---

### 3.2 Payroll Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### ClickOps Implementation

**Step 1: Payroll Access**
1. Navigate to: **Settings → Permissions**
2. Limit payroll admin access
3. Require approval for changes

---

## 4. Monitoring & Detection

### 4.1 Audit Logs

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Settings → Audit Logs**
2. Review admin activities
3. Monitor configuration changes

#### Detection Focus

```sql
-- Detect bulk data access
SELECT admin_email, action, record_count
FROM rippling_audit_log
WHERE action LIKE '%export%'
  AND record_count > 50
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect app provisioning changes
SELECT admin_email, app_name, action
FROM rippling_audit_log
WHERE action IN ('app.add_user', 'app.remove_user')
  AND timestamp > NOW() - INTERVAL '7 days';
```

---

## Appendix A: Feature Availability

| Control | Availability |
|---------|--------------|
| SAML SSO | ✅ |
| MFA | ✅ |
| Custom Roles | ✅ |
| Audit Logs | ✅ |
| SCIM | ✅ |

---

## Appendix B: References

**Official Rippling Documentation:**
- [Help Center](https://help.rippling.com/)
- [Security & Trust](https://www.rippling.com/security)
- [Trust Center](https://trust.rippling.com/)
- [7 Steps to Secure Your Rippling Tenant](https://www.rippling.com/blog/seven-powerful-simple-steps-to-secure-your-rippling-tenant)

**API & Developer Resources:**
- [REST API Documentation](https://developer.rippling.com/documentation/rest-api)

**Compliance & Certifications:**
- SOC 1 Type II, SOC 2 Type II, ISO 27001, ISO 27018, ISO 42001, CSA STAR Level 2 -- via [Rippling Trust Center](https://trust.rippling.com/)

**Security Incidents:**
- **Deel Corporate Espionage Incident (March 2025):** Rippling filed a lawsuit against competitor Deel alleging a planted insider (spy) who accessed proprietary sales data, customer information, and competitive intelligence via Slack over several months. This was not a platform breach -- it was an insider threat from a Deel-affiliated employee. Rippling detected the scheme using a honeypot trap.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial Rippling hardening guide | Claude Code (Opus 4.5) |
