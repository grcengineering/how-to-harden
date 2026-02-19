---
layout: guide
title: "Mailchimp Hardening Guide"
vendor: "Mailchimp"
slug: "mailchimp"
tier: "4"
category: "Marketing"
description: "Email marketing security for API keys, audience protection, and domain authentication"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-12-14"
---


## Overview

Mailchimp manages email marketing with audience data, campaign history, and customer engagement metrics. API keys, OAuth apps, and integrations access subscriber lists and behavioral data. Compromised access enables mass phishing distribution through trusted sender reputation, or exfiltration of subscriber databases.

### Intended Audience
- Security engineers managing marketing platforms
- Marketing administrators
- GRC professionals assessing email marketing compliance
- Third-party risk managers evaluating marketing integrations


### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries


### Scope
This guide covers Mailchimp security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API Security](#2-api-security)
3. [Audience Security](#3-audience-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### ClickOps Implementation

**Step 1: Enable Two-Factor Authentication**
1. Navigate to: **Account → Settings → Security**
2. Enable: **Two-factor authentication**
3. Configure authenticator app

**Step 2: Enforce for All Users**
1. Require 2FA for all account users
2. Configure backup methods
3. Review recovery codes

---

### 1.2 Implement Access Levels

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### ClickOps Implementation

**Step 1: Define User Levels**

| Level | Permissions |
|-------|-------------|
| Owner | Full access (1 user) |
| Admin | Manage users, full features |
| Manager | Create campaigns, manage audiences |
| Author | Create content only |
| Viewer | Read-only |

**Step 2: Configure User Access**
1. Navigate to: **Account → Settings → Users**
2. Assign minimum required level
3. Review access quarterly

---

## 2. API Security

### 2.1 Secure API Keys

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Manage Mailchimp API keys securely.

#### Rationale
**Attack Scenario:** Compromised API key exports entire subscriber list; enables mass phishing through trusted sending domain.

#### ClickOps Implementation

**Step 1: Audit API Keys**
1. Navigate to: **Account → Extras → API keys**
2. Review all active keys
3. Delete unused keys

**Step 2: Create Scoped Keys**
1. Create separate keys per integration
2. Document key purposes
3. Rotate keys annually

---

### 2.2 OAuth App Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### ClickOps Implementation

**Step 1: Review Connected Apps**
1. Navigate to: **Account → Settings → Connected apps**
2. Review all OAuth authorizations
3. Revoke unused apps

**Step 2: Integration Audit**
1. Review integration permissions
2. Remove unnecessary access
3. Document all integrations

---

## 3. Audience Security

### 3.1 Protect Subscriber Data

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### ClickOps Implementation

**Step 1: Configure Export Restrictions**
1. Limit export permissions
2. Enable export notifications
3. Audit export activity

**Step 2: Segment Access**
1. Use audience segments
2. Limit access by user level
3. Protect sensitive segments

---

### 3.2 Email Authentication

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SI-3

#### ClickOps Implementation

**Step 1: Configure Domain Authentication**
1. Navigate to: **Website → Domains**
2. Authenticate sending domains
3. Configure DKIM

**Step 2: Enable DMARC**
1. Set up SPF records
2. Configure DMARC policy
3. Monitor email deliverability

---

## 4. Monitoring & Detection

### 4.1 Account Activity

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### ClickOps Implementation

**Step 1: Review Login History**
1. Navigate to: **Account → Settings → Security**
2. Review login activity
3. Investigate suspicious logins

#### Detection Focus

{% include pack-code.html vendor="mailchimp" section="4.1" %}

---

## Appendix A: Edition Compatibility

| Control | Essentials | Standard | Premium |
|---------|------------|----------|---------|
| 2FA | ✅ | ✅ | ✅ |
| User Levels | Limited | ✅ | ✅ |
| API Access | ✅ | ✅ | ✅ |
| Audit Logs | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Mailchimp Documentation:**
- [Mailchimp Security](https://mailchimp.com/about/security/)
- [Mailchimp Help Center](https://mailchimp.com/help/)
- [Account Security Best Practices](https://mailchimp.com/help/best-practices-for-account-security/)
- [Intuit Compliance & Security](https://www.intuit.com/compliance/)

**API & Developer Resources:**
- [Mailchimp Developer Portal](https://mailchimp.com/developer/)
- [Mailchimp Marketing API](https://mailchimp.com/developer/marketing/)
- [Mailchimp Transactional API](https://mailchimp.com/developer/transactional/)

**Compliance Frameworks:**
- SOC 2 Type II, SOC 3, ISO 27001, PCI DSS (as part of Intuit) -- SOC 2 report available via [NDA request](https://mailchimp.com/about/security/soc-request/)

**Security Incidents:**
- **March 2022:** Social engineering attack compromised employee credentials; 319 accounts were viewed and audience data was exported from 102 accounts, primarily targeting cryptocurrency and finance customers.
- **August 2022:** Employees fell victim to an Okta phishing campaign (0ktapus); 214 Mailchimp accounts were accessed, again focused on cryptocurrency-related customers.
- **January 2023:** Third social engineering breach in under 12 months; unauthorized access to customer support and admin tools via phished employee credentials, affecting 133 customer accounts.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial Mailchimp hardening guide | Claude Code (Opus 4.5) |
