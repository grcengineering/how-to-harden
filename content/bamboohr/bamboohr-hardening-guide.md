# BambooHR Hardening Guide

**Version:** 1.0
**Last Updated:** 2025-12-14
**Product Editions Covered:** BambooHR (Essentials, Advantage)
**Authors:** How to Harden Community

---

## Overview

BambooHR is a cloud-based HR platform managing employee records, benefits, and performance data. REST API, webhook integrations, and third-party app marketplace access sensitive employee PII. Compromised access exposes SSN, compensation data, and performance reviews.

### Intended Audience
- Security engineers managing HR systems
- BambooHR administrators
- GRC professionals assessing HR compliance
- Third-party risk managers evaluating HRIS integrations

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API Security](#2-api-security)
3. [Data Security](#3-data-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Settings → Security → Single Sign-On**
2. Configure SAML IdP
3. Enable SSO requirement

**Step 2: Enable 2FA**
1. Navigate to: **Settings → Security**
2. Enable: **Require 2FA**
3. Configure backup methods

---

### 1.2 Access Level Configuration

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### ClickOps Implementation

**Step 1: Define Access Levels**
| Level | Permissions |
|-------|-------------|
| Admin | Full access |
| HR Manager | HR functions |
| Manager | Team access |
| Employee | Self-service |

**Step 2: Configure Field Permissions**
1. Navigate to: **Settings → Access Levels**
2. Create custom access levels
3. Configure field-level visibility

---

## 2. API Security

### 2.1 Secure API Keys

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Manage BambooHR API keys securely.

#### Rationale
**Attack Scenario:** Compromised API key enables full employee database export; SSN, compensation, and personal data exposed.

#### ClickOps Implementation

**Step 1: Audit API Keys**
1. Navigate to: **Settings → API Keys**
2. Review all active keys
3. Remove unused keys

**Step 2: Key Best Practices**
1. Create separate keys per integration
2. Document key purposes
3. Rotate keys annually

---

### 2.2 Third-Party App Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### ClickOps Implementation

**Step 1: Review Connected Apps**
1. Navigate to: **Apps → Installed Apps**
2. Review all connected apps
3. Remove unused integrations

**Step 2: App Approval**
1. Require admin approval for new apps
2. Review OAuth scopes
3. Audit app access quarterly

---

## 3. Data Security

### 3.1 Protect Sensitive Fields

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### ClickOps Implementation

**Step 1: Configure Field Security**
1. Navigate to: **Settings → Employee Fields**
2. Identify sensitive fields (SSN, salary, bank info)
3. Restrict visibility by access level

**Step 2: Mask Sensitive Data**
1. Configure SSN masking
2. Limit bank account visibility
3. Audit sensitive data access

---

### 3.2 Report Security

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-21

#### ClickOps Implementation

**Step 1: Restrict Report Access**
1. Navigate to: **Reports**
2. Limit who can create reports
3. Restrict report sharing

---

## 4. Monitoring & Detection

### 4.1 Activity Monitoring

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### ClickOps Implementation

**Step 1: Review Login History**
1. Navigate to: **Settings → Security → Login History**
2. Monitor failed logins
3. Investigate suspicious access

#### Detection Focus

```sql
-- Detect bulk data exports
SELECT user_email, report_name, record_count
FROM bamboo_activity
WHERE action = 'report_export'
  AND record_count > 100
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect API abuse
SELECT api_key, endpoint, COUNT(*) as calls
FROM api_log
WHERE timestamp > NOW() - INTERVAL '1 hour'
GROUP BY api_key, endpoint
HAVING COUNT(*) > 500;
```

---

## Appendix A: Edition Compatibility

| Control | Essentials | Advantage |
|---------|------------|-----------|
| SAML SSO | Add-on | ✅ |
| 2FA | ✅ | ✅ |
| Custom Access Levels | ✅ | ✅ |
| API Access | ✅ | ✅ |

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial BambooHR hardening guide | How to Harden Community |
