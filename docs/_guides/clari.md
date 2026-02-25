---
layout: guide
title: "Clari Hardening Guide"
vendor: "Clari"
slug: "clari"
tier: "2"
category: "Productivity"
description: "Revenue platform hardening for Clari including SAML SSO, user permissions, and forecast data security"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Clari is a revenue operations platform providing forecasting and pipeline management. As a platform handling sensitive sales data and revenue forecasts, Clari security configurations directly impact financial data protection and operational security.

### Intended Audience
- Security engineers managing revenue platforms
- IT administrators configuring Clari
- Revenue operations managers
- GRC professionals assessing sales platform security

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Clari security including SAML SSO, user permissions, forecast visibility controls, and audit logging.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Data Security](#3-data-security)
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
Configure SAML SSO for Clari access. Clari integrates with SSO/MFA solutions via SAML 2.0.

#### Prerequisites
- Clari admin access
- Enterprise tier subscription
- Contact Clari support to enable SAML (no self-service)
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Contact Clari Support**
1. SAML configuration requires Clari support assistance
2. Request SAML SSO enablement
3. Provide IdP details

**Step 2: Configure IdP**
1. Create SAML application in IdP
2. Configure with Clari-provided settings:
   - ACS URL
   - Entity ID
   - Attribute mappings
3. Download certificate

**Step 3: Complete Configuration**
1. Work with Clari support to finalize
2. Test SSO authentication
3. Enable for users

**Note:** Directory sync works reliably with Okta. Other IdPs provide SAML SSO but no automated provisioning.

**Time to Complete:** ~2-4 hours (requires support engagement)

---

### 1.2 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all Clari users via IdP integration.

#### ClickOps Implementation

**Step 1: Configure via IdP**
1. Enable MFA in identity provider
2. All SSO users subject to IdP MFA
3. Use phishing-resistant methods for admins

**Note:** Clari relies on IdP for MFA enforcement - no native MFA configuration.

---

## 2. Access Controls

### 2.1 Configure User Permissions

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege for Clari access using custom roles.

#### ClickOps Implementation

**Step 1: Review Roles**
1. Navigate to Clari admin settings
2. Review available roles
3. Custom roles available at Enterprise tier

**Step 2: Apply Least Privilege**
1. Assign minimum necessary permissions
2. Control forecast visibility by role
3. Limit CRM data access based on role
4. Regular access reviews

---

### 2.2 Configure Forecast Visibility

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control who can view forecast data.

#### ClickOps Implementation

**Step 1: Configure Visibility Rules**
1. Set forecast visibility by hierarchy
2. Limit cross-team visibility
3. Control sensitive deal access

**Step 2: Apply Data Boundaries**
1. Restrict based on CRM access
2. Align with organizational hierarchy
3. Audit visibility settings

---

### 2.3 Manage User Lifecycle

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Manage user provisioning and deprovisioning.

#### ClickOps Implementation

**Step 1: Note SCIM Limitations**
1. Clari does not provide native SCIM
2. User management is manual (except Okta directory sync)
3. Consider third-party provisioning tools

**Step 2: Implement Manual Controls**
1. Document onboarding/offboarding process
2. Regular access reviews
3. Promptly remove departed users

---

### 2.4 Limit Admin Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect admin accounts.

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Review admin accounts
2. Document admin access

**Step 2: Apply Restrictions**
1. Limit admins to required personnel
2. Require MFA via IdP
3. Monitor admin activity via audit logs (Enterprise tier)

---

## 3. Data Security

### 3.1 Configure Audit Logging

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor audit logs (Enterprise tier).

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Audit logs available at Enterprise tier
2. Review user activity
3. Export for analysis

**Step 2: Monitor Key Events**
1. User authentication
2. Permission changes
3. Forecast modifications

---

## 4. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Clari Control | Guide Section |
|-----------|---------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | User permissions | [2.1](#21-configure-user-permissions) |
| CC7.2 | Audit logging | [3.1](#31-configure-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | Clari Control | Guide Section |
|---------|---------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| AC-3 | Forecast visibility | [2.2](#22-configure-forecast-visibility) |
| AC-6 | User permissions | [2.1](#21-configure-user-permissions) |
| AU-2 | Audit logging | [3.1](#31-configure-audit-logging) |

---

## Appendix A: Plan Compatibility

| Feature | Standard | Enterprise |
|---------|----------|------------|
| SAML SSO | Contact sales | ✅ |
| Custom Roles | Limited | ✅ |
| Audit Logs | ❌ | ✅ |
| SCIM | ❌ | ❌ (Okta only) |

---

## Appendix B: References

**Official Clari Documentation:**
- [Clari Security](https://www.clari.com/security/)
- [Clari Community](https://community.clari.com/)
- [Vulnerability Disclosure Policy](https://www.clari.com/vulnerability-disclosure-policy/)

**API Documentation:**
- [Clari Developer Portal](https://developer.clari.com/)

**Compliance Frameworks:**
- SOC 2 Type II (zero exemptions, audited by A-LIGN), ISO 27001 (certified by BSI Group with zero adverse findings) — via [Clari Security](https://www.clari.com/security/)

**Security Incidents:**
- No major public data breaches identified. Clari has experienced operational incidents (delayed data processing, module loading issues) but none involving customer data compromise.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO and access controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
