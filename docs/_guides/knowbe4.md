---
layout: guide
title: "KnowBe4 Hardening Guide"
vendor: "KnowBe4"
slug: "knowbe4"
tier: "2"
category: "Security"
description: "Security awareness training platform hardening for KnowBe4 including SAML SSO, admin access, and campaign security"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

KnowBe4 is a leading security awareness training platform providing phishing simulations and training. As a platform managing employee training data and conducting security tests, KnowBe4 security configurations directly impact training integrity and data protection.

### Intended Audience
- Security engineers managing awareness programs
- IT administrators configuring KnowBe4
- Security awareness managers
- GRC professionals assessing training programs

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers KnowBe4 console security including SAML SSO, admin access, campaign configuration, and audit logging.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Campaign Security](#3-campaign-security)
4. [Compliance Quick Reference](#4-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure SAML Single Sign-On

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO for KnowBe4 console access.

#### Prerequisites
- [ ] KnowBe4 admin access
- [ ] Platinum or Diamond subscription
- [ ] SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Account Settings** → **Account Integrations** → **SAML**
2. Enable SAML authentication

**Step 2: Configure SAML**
1. Configure IdP settings:
   - Entity ID
   - SSO URL
   - Certificate
2. Download KnowBe4 metadata for IdP

**Step 3: Test and Enforce**
1. Test SSO authentication
2. Enable SSO enforcement
3. Configure admin fallback

**Time to Complete:** ~1-2 hours

---

### 1.2 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all KnowBe4 admin users.

#### ClickOps Implementation

**Step 1: Enable Console MFA**
1. Navigate to: **Account Settings** → **Security Settings**
2. Enable MFA requirement
3. Configure MFA methods

**Step 2: Configure via IdP**
1. Enable MFA in identity provider
2. Use phishing-resistant methods

---

## 2. Access Controls

### 2.1 Configure Admin Roles

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege for admin access.

#### ClickOps Implementation

**Step 1: Review Admin Types**
1. Navigate to: **Account Settings** → **Admins**
2. Review admin roles:
   - Account Owner
   - Full Admin
   - Reports Only
   - Sub-Account Admin
3. Assign minimum necessary role

**Step 2: Apply Least Privilege**
1. Use Reports Only for viewers
2. Limit Full Admin access
3. Regular access reviews

---

### 2.2 Limit Admin Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect admin accounts.

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Review all admin accounts
2. Document admin access

**Step 2: Apply Restrictions**
1. Limit owners to 2-3 users
2. Require MFA for all admins
3. Monitor admin activity

---

## 3. Campaign Security

### 3.1 Configure Phishing Campaign Security

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 17.3 |
| NIST 800-53 | AT-2 |

#### Description
Secure phishing simulation campaigns.

#### ClickOps Implementation

**Step 1: Configure Campaign Notifications**
1. Notify IT/security of campaigns
2. Allowlist simulation domains
3. Configure landing pages securely

**Step 2: Protect Campaign Data**
1. Limit access to results
2. Configure data retention
3. Protect employee privacy

---

### 3.2 Configure API Security

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure API access.

#### ClickOps Implementation

**Step 1: Review API Keys**
1. Navigate to: **Account Settings** → **API**
2. Review API access
3. Document key purposes

**Step 2: Secure Keys**
1. Store keys securely
2. Rotate regularly
3. Monitor usage

---

## 4. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | KnowBe4 Control | Guide Section |
|-----------|-----------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Admin roles | [2.1](#21-configure-admin-roles) |

### NIST 800-53 Rev 5 Mapping

| Control | KnowBe4 Control | Guide Section |
|---------|-----------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| AC-6 | Admin roles | [2.1](#21-configure-admin-roles) |
| AT-2 | Training | [3.1](#31-configure-phishing-campaign-security) |

---

## Appendix B: References

**Official KnowBe4 Documentation:**
- [Trust Center (SafeBase)](https://trust.knowbe4.com/)
- [Security Statement](https://www.knowbe4.com/legal/security)
- [Knowledge Base](https://support.knowbe4.com/hc/en-us)
- [SAML Integration Overview](https://support.knowbe4.com/hc/en-us/articles/206293387-SAML-Integration-Overview)
- [SCIM Configuration Guide](https://support.knowbe4.com/hc/en-us/articles/360052380374-SCIM-Configuration-Guide)

**API Documentation:**
- [KnowBe4 Developer Portal](https://developer.knowbe4.com/)
- [Reporting API Overview](https://support.knowbe4.com/hc/en-us/articles/115016090908-Reporting-API-Overview)

**Compliance Frameworks:**
- SOC 2 Type 2, ISO 27001:2022, ISO 27701, ISO 27017, ISO 27018, FedRAMP Moderate, CSA STAR — via [Security Statement](https://www.knowbe4.com/legal/security)
- [FedRAMP Moderate Authorization Announcement](https://www.knowbe4.com/press/knowbe4-is-now-fedramp-federal-risk-and-authorization-management-program-moderate-authorized)

**Security Incidents:**
- [How a North Korean Fake IT Worker Tried to Infiltrate Us (July 2024)](https://blog.knowbe4.com/how-a-north-korean-fake-it-worker-tried-to-infiltrate-us)
- [North Korean Fake IT Worker FAQ](https://blog.knowbe4.com/north-korean-fake-it-worker-faq)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO and campaign security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
