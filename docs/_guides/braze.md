---
layout: guide
title: "Braze Hardening Guide"
vendor: "Braze"
slug: "braze"
tier: "2"
category: "Marketing & CRM"
description: "Customer engagement platform hardening for Braze including SAML SSO, permission sets, and API security"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Braze is a leading customer engagement platform serving **thousands of brands** for mobile and web marketing automation. As a platform handling customer PII and engagement data, Braze security configurations directly impact data protection and marketing compliance.

### Intended Audience
- Security engineers managing marketing platforms
- IT administrators configuring Braze
- Marketing operations managing campaigns
- GRC professionals assessing marketing security

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Braze security including SAML SSO, permission sets, API key management, and data protection.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [API Security](#3-api-security)
4. [Monitoring & Compliance](#4-monitoring--compliance)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure SAML Single Sign-On

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication for Braze users.

#### Prerequisites
- [ ] Braze admin access
- [ ] SAML 2.0 compatible IdP
- [ ] SSO feature enabled (enterprise plans)

#### ClickOps Implementation

**Step 1: Access Security Settings**
1. Navigate to: **Settings** → **Security Settings**
2. Find SAML SSO section

**Step 2: Configure SAML**
1. Enable SAML SSO
2. Enter IdP metadata URL or configure manually:
   - Identity Provider URL
   - SSO URL
   - Certificate
3. Configure attribute mapping

**Step 3: Test and Enforce**
1. Test SSO authentication
2. Configure SSO enforcement
3. Document local admin fallback

**Time to Complete:** ~1-2 hours

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Braze users.

#### ClickOps Implementation

**Step 1: Enable Company-Wide 2FA**
1. Navigate to: **Settings** → **Security Settings**
2. Enable **Require two-factor authentication**
3. Applies to all users on next login

**Step 2: Configure 2FA Methods**
1. Braze supports authenticator apps
2. Users configure in profile settings
3. Generate backup codes

---

### 1.3 Configure IP Allowlisting

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Restrict dashboard access to approved IP ranges.

#### ClickOps Implementation

**Step 1: Configure IP Allowlist**
1. Navigate to: **Settings** → **Security Settings**
2. Enable IP allowlisting
3. Add approved IP ranges

**Step 2: Test Access**
1. Verify access from allowed IPs
2. Test blocking from non-allowed IPs
3. Document allowed ranges

---

## 2. Access Controls

### 2.1 Configure Permission Sets

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Braze permission sets.

#### ClickOps Implementation

**Step 1: Review Permission Sets**
1. Navigate to: **Settings** → **Company Users** → **Permission Sets**
2. Review predefined sets:
   - Admin
   - Developer
   - Marketer
   - Analyst
3. Understand permissions per set

**Step 2: Create Custom Permission Sets**
1. Create sets for specific roles
2. Define granular permissions
3. Limit data access appropriately

**Step 3: Assign Minimum Necessary Access**
1. Apply least-privilege principle
2. Regular access reviews
3. Document permission assignments

---

### 2.2 Configure Workspace Access

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control access to workspaces and app groups.

#### ClickOps Implementation

**Step 1: Review Workspace Structure**
1. Navigate to: **Settings** → **Workspaces**
2. Review workspace organization
3. Understand data separation

**Step 2: Configure Workspace Access**
1. Assign users to appropriate workspaces
2. Limit cross-workspace access
3. Separate production and test data

---

### 2.3 Limit Admin Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect administrator accounts.

#### ClickOps Implementation

**Step 1: Inventory Admin Users**
1. Navigate to: **Settings** → **Company Users**
2. Review users with Admin permission set
3. Document admin access

**Step 2: Apply Restrictions**
1. Limit admin to 2-3 users
2. Require 2FA for admins
3. Monitor admin activity

---

## 3. API Security

### 3.1 Configure API Key Management

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure API keys and access tokens.

#### ClickOps Implementation

**Step 1: Review API Keys**
1. Navigate to: **Settings** → **APIs** → **API Keys**
2. Inventory all API keys
3. Document key purposes

**Step 2: Apply Least Privilege**
1. Create keys with minimum permissions
2. Use separate keys per integration
3. Rotate keys regularly

**Step 3: Secure Key Storage**
1. Store keys in secure vault
2. Never commit to repositories
3. Audit key usage

---

### 3.2 Configure API IP Allowlisting

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Restrict API access to approved IP ranges.

#### ClickOps Implementation

**Step 1: Configure IP Restrictions**
1. Navigate to: **Settings** → **APIs**
2. Configure IP allowlist for API keys
3. Restrict to application servers

**Step 2: Monitor API Access**
1. Review API access logs
2. Alert on unauthorized attempts
3. Regular access reviews

---

## 4. Monitoring & Compliance

### 4.1 Configure Activity Logs

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor activity logs.

#### ClickOps Implementation

**Step 1: Access Activity Logs**
1. Navigate to: **Settings** → **Activity Log**
2. Review logged events
3. Configure retention

**Step 2: Monitor Key Events**
1. User authentication
2. Campaign changes
3. API key creation
4. Permission changes

---

### 4.2 Configure Data Retention

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | SI-12 |

#### Description
Configure data retention policies.

#### ClickOps Implementation

**Step 1: Review Retention Settings**
1. Configure user data retention
2. Configure event data retention
3. Align with compliance requirements

**Step 2: Configure Deletion**
1. Enable user deletion workflows
2. Configure GDPR/CCPA compliance
3. Document retention policies

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Braze Control | Guide Section |
|-----------|---------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Permission sets | [2.1](#21-configure-permission-sets) |
| CC6.6 | IP allowlisting | [1.3](#13-configure-ip-allowlisting) |
| CC7.2 | Activity logs | [4.1](#41-configure-activity-logs) |

### NIST 800-53 Rev 5 Mapping

| Control | Braze Control | Guide Section |
|---------|---------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | 2FA | [1.2](#12-enforce-two-factor-authentication) |
| AC-6 | Permission sets | [2.1](#21-configure-permission-sets) |
| SC-12 | API key security | [3.1](#31-configure-api-key-management) |
| AU-2 | Activity logs | [4.1](#41-configure-activity-logs) |

---

## Appendix A: References

**Official Braze Documentation:**
- [Braze Security Documentation](https://www.braze.com/docs/security/)
- [SAML SSO Setup](https://www.braze.com/docs/user_guide/administrative/access_braze/single_sign_on/)
- [Permission Sets](https://www.braze.com/docs/user_guide/administrative/manage_your_braze_users/user_permissions/)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, permissions, and API security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
