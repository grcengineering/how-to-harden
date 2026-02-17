---
layout: guide
title: "Klaviyo Hardening Guide"
vendor: "Klaviyo"
slug: "klaviyo"
tier: "4"
category: "Marketing"
description: "E-commerce marketing security for API keys, profile protection, and export controls"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-12-14"
---


## Overview

Klaviyo is an e-commerce marketing platform managing customer data, email/SMS campaigns, and behavioral analytics. REST API with private/public API keys, webhooks, and e-commerce platform integrations access customer PII and purchase history. Compromised access enables customer database exfiltration or phishing through trusted sender domains.

### Intended Audience
- Security engineers managing marketing platforms
- Klaviyo administrators
- GRC professionals assessing e-commerce marketing compliance
- Third-party risk managers evaluating marketing integrations


### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries


### Scope
This guide covers Klaviyo security configurations including authentication, access controls, and integration security.

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

**Step 1: Configure SAML SSO (Enterprise)**
1. Navigate to: **Settings → Security → SSO**
2. Configure SAML IdP
3. Enable SSO enforcement

**Step 2: Enable 2FA**
1. Navigate to: **Settings → Security**
2. Enable: **Require 2FA for all users**
3. Configure backup methods

---

### 1.2 Role-Based Access

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### ClickOps Implementation

**Step 1: Define User Roles**

| Role | Permissions |
|------|-------------|
| Owner | Full access (1 user) |
| Admin | Manage account settings |
| Manager | Create campaigns |
| Analyst | View-only |
| Support | Limited customer access |

**Step 2: Configure Role Permissions**
1. Navigate to: **Settings → Users**
2. Assign appropriate roles
3. Review access quarterly

---

## 2. API Security

### 2.1 Secure API Keys

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Manage Klaviyo API keys securely.

#### Rationale
**Attack Scenario:** Private API key exposure enables full profile database export; customer PII and purchase history exfiltrated for fraud or targeted phishing.

#### Implementation

**API Key Types:**

| Key Type | Access Level | Exposure Risk |
|----------|--------------|---------------|
| Private API Key | Full read/write | High (never expose) |
| Public API Key | Limited (client events) | Low |

**Step 1: Rotate Private Keys**
1. Navigate to: **Settings → API Keys**
2. Generate new private key
3. Update integrations
4. Revoke old key

**Step 2: API Key Best Practices**
1. Never expose private keys in client code
2. Use environment variables
3. Limit access to production keys
4. Audit key usage

---

### 2.2 Webhook Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-8

#### Implementation

**Step 1: Secure Webhook Endpoints**
1. Use HTTPS only
2. Validate webhook signatures
3. Implement IP allowlisting

---

## 3. Data Security

### 3.1 Profile Data Protection

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### ClickOps Implementation

**Step 1: Configure Data Handling**
1. Limit profile data collection
2. Configure consent tracking
3. Enable suppression list management

**Step 2: Export Controls**
1. Restrict export permissions
2. Audit bulk exports
3. Configure data retention

---

### 3.2 Email Authentication

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SI-3

#### ClickOps Implementation

**Step 1: Configure Domain Authentication**
1. Navigate to: **Settings → Domains**
2. Configure dedicated sending domain
3. Set up DKIM/SPF records

**Step 2: Enable DMARC**
1. Configure DMARC policy
2. Monitor authentication reports
3. Move toward enforcement

---

## 4. Monitoring & Detection

### 4.1 Activity Monitoring

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### ClickOps Implementation

**Step 1: Review Account Activity**
1. Navigate to: **Settings → Activity log**
2. Monitor user logins
3. Track configuration changes

#### Detection Focus

```sql
-- Detect bulk profile exports
SELECT user_email, export_type, profile_count
FROM klaviyo_activity
WHERE action = 'export'
  AND profile_count > 10000
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect API abuse
SELECT api_key_prefix, endpoint, COUNT(*) as calls
FROM api_log
WHERE timestamp > NOW() - INTERVAL '1 hour'
GROUP BY api_key_prefix, endpoint
HAVING COUNT(*) > 5000;
```

---

## Appendix A: Edition Compatibility

| Control | Growth | Enterprise |
|---------|--------|------------|
| SAML SSO | ❌ | ✅ |
| SCIM | ❌ | ✅ |
| Audit Logs | Limited | ✅ |
| Custom Roles | ❌ | ✅ |

---

## Appendix B: References

**Official Klaviyo Documentation:**
- [Klaviyo Trust Center](https://www.klaviyo.com/trust)
- [Klaviyo Help Center](https://help.klaviyo.com/hc/en-us)
- [Account Security Best Practices](https://help.klaviyo.com/hc/en-us/articles/360052448451)
- [Klaviyo Compliance](https://help.klaviyo.com/hc/en-us/sections/14506459013147)

**API & Developer Resources:**
- [Klaviyo Developer Portal](https://developers.klaviyo.com/en)
- [Klaviyo REST API Reference](https://developers.klaviyo.com/en/reference/api-overview)
- [Klaviyo SDKs](https://developers.klaviyo.com/en/docs/sdk-overview)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27017, PCI DSS -- via [Klaviyo Trust](https://www.klaviyo.com/trust). Reports available upon request through Klaviyo support.

**Security Incidents:**
- **August 2022:** Klaviyo disclosed a phishing attack that compromised an employee's credentials, granting access to internal support tools. Attackers downloaded marketing lists for 38 cryptocurrency-related customer accounts. No passwords, payment data, or credit card numbers were exposed.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial Klaviyo hardening guide | Claude Code (Opus 4.5) |
