---
layout: guide
title: "Intercom Hardening Guide"
vendor: "Intercom"
slug: "intercom"
tier: "2"
category: "Marketing"
description: "Customer messaging platform hardening for Intercom including SAML SSO, workspace security, and data protection"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Intercom is a leading customer messaging platform serving **thousands of businesses** for support, marketing, and customer engagement. As a platform handling customer conversations and PII, Intercom security configurations directly impact customer privacy and data protection.

### Intended Audience
- Security engineers managing customer platforms
- IT administrators configuring Intercom
- Support operations managing messaging
- GRC professionals assessing communication security

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Intercom security including SAML SSO, workspace access, conversation security, and data protection.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Data Protection](#3-data-protection)
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
Configure SAML SSO to centralize authentication for Intercom teammates.

#### Prerequisites
- [ ] Intercom admin access
- [ ] Enterprise or Pro plan
- [ ] SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access Security Settings**
1. Navigate to: **Settings** → **Security**
2. Find SAML/SSO section

**Step 2: Configure SAML**
1. Enable SAML SSO
2. Configure IdP settings:
   - SSO URL
   - Entity ID
   - Certificate
3. Configure attribute mapping

**Step 3: Test and Enforce**
1. Test SSO authentication
2. Enable SSO enforcement
3. Document admin fallback

**Time to Complete:** ~1-2 hours

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Intercom teammates.

#### ClickOps Implementation

**Step 1: Enable Workspace 2FA**
1. Navigate to: **Settings** → **Security**
2. Enable **Require two-factor authentication**
3. All teammates must configure 2FA

**Step 2: Verify Compliance**
1. Review 2FA enrollment status
2. Follow up with non-compliant users
3. Document exceptions

---

### 1.3 Configure Session Security

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Configure session timeout and security settings.

#### ClickOps Implementation

**Step 1: Configure Timeout**
1. Navigate to: **Settings** → **Security**
2. Configure session timeout
3. Balance security with usability

---

## 2. Access Controls

### 2.1 Configure Team Roles

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Intercom roles.

#### ClickOps Implementation

**Step 1: Review Roles**
1. Navigate to: **Settings** → **Teammates**
2. Review available roles:
   - Owner
   - Admin
   - Teammate
3. Understand role capabilities

**Step 2: Assign Appropriate Roles**
1. Apply least-privilege principle
2. Limit admin access
3. Regular access reviews

---

### 2.2 Configure Inbox Access

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control access to conversation inboxes.

#### ClickOps Implementation

**Step 1: Configure Inbox Permissions**
1. Navigate to: **Settings** → **Inbox**
2. Configure team inbox access
3. Limit visibility by team

**Step 2: Configure Assignment Rules**
1. Configure conversation routing
2. Restrict reassignment permissions
3. Audit conversation access

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
1. Review all admin accounts
2. Document admin access
3. Identify unnecessary privileges

**Step 2: Apply Restrictions**
1. Limit admin/owner to 2-3 users
2. Require 2FA for admins
3. Monitor admin activity

---

## 3. Data Protection

### 3.1 Configure Data Export Controls

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control data export capabilities.

#### ClickOps Implementation

**Step 1: Review Export Permissions**
1. Understand export capabilities
2. Limit export access to admins
3. Audit export activities

**Step 2: Configure Data Policies**
1. Define data handling policies
2. Configure retention settings
3. Document compliance requirements

---

### 3.2 Configure Conversation Security

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Protect sensitive conversation data.

#### ClickOps Implementation

**Step 1: Configure Data Masking**
1. Enable sensitive data masking
2. Configure PII detection
3. Apply masking rules

**Step 2: Configure Deletion Policies**
1. Configure conversation retention
2. Enable deletion workflows
3. Support GDPR/CCPA requests

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

**Step 1: Access Logs**
1. Navigate to: **Settings** → **Security** → **Activity Log**
2. Review logged events
3. Configure monitoring

**Step 2: Monitor Key Events**
1. Teammate authentication
2. Role changes
3. Data exports
4. Configuration changes

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Intercom Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Team roles | [2.1](#21-configure-team-roles) |
| CC7.2 | Activity logs | [4.1](#41-configure-activity-logs) |

### NIST 800-53 Rev 5 Mapping

| Control | Intercom Control | Guide Section |
|---------|------------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | 2FA | [1.2](#12-enforce-two-factor-authentication) |
| AC-6 | Team roles | [2.1](#21-configure-team-roles) |
| AU-2 | Activity logs | [4.1](#41-configure-activity-logs) |

---

## Appendix A: References

**Official Intercom Documentation:**
- [Trust Center](https://trust.intercom.com/)
- [Intercom Security](https://www.intercom.com/security)
- [Help Center](https://www.intercom.com/help/en/)
- [Security & Privacy Collection](https://www.intercom.com/help/en/collections/384-security-privacy)
- [SAML SSO Setup](https://www.intercom.com/help/en/articles/2729674-set-up-saml-sso)
- [Team Management](https://www.intercom.com/help/en/collections/3181-teammates-and-permissions)
- [Security Policy](https://www.intercom.com/legal/security-policy)

**API & Developer Tools:**
- [Intercom Developer Hub](https://developers.intercom.com/)
- [Intercom REST API Reference](https://developers.intercom.com/docs/references/rest-api/api.intercom.io/Articles/article/)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001:2022, ISO 27018, ISO 27701, ISO/IEC 42001:2023 (AI), HIPAA, GDPR, CCPA -- via [Trust Center](https://trust.intercom.com/)
- [Accessing Security and Compliance Documents](https://www.intercom.com/help/en/articles/7053674-accessing-security-and-compliance-documents)

**Security Incidents:**
- No major public security incidents identified as of February 2026.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, roles, and data protection | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
