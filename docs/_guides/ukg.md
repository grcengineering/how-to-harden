---
layout: guide
title: "UKG Pro Hardening Guide"
vendor: "UKG"
slug: "ukg"
tier: "2"
category: "HR & Finance"
description: "HCM platform hardening for UKG Pro including SAML SSO configuration, authentication upgrade features, and access controls"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

UKG (Ultimate Kronos Group) Pro is a leading cloud-based human capital management platform serving **thousands of organizations** worldwide. As a repository for sensitive employee data, payroll, and workforce management, UKG Pro security configurations directly impact data protection and compliance.

### Intended Audience
- Security engineers managing HR systems
- HR administrators configuring UKG Pro
- IT administrators managing SSO integration
- GRC professionals assessing HCM security

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers UKG Pro security including SAML SSO, authentication features, role-based access control, and session security.

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
Configure SAML SSO to centralize authentication for UKG Pro users.

#### Prerequisites
- [ ] Contact UKG Pro support to enable SAML SSO
- [ ] Include UFSSO@ukg.com in communications
- [ ] Obtain ACS URL and Entity ID from UKG

#### ClickOps Implementation

**Step 1: Request SSO Enablement**
1. Contact your UKG Pro SSO Engineer
2. Include UFSSO@ukg.com in recipient list
3. If no assigned engineer, email UFSSO@ukg.com
4. Request SAML SSO enablement and configuration values

**Step 2: Configure Identity Provider**
1. Create SAML application in IdP (Okta, Entra, etc.)
2. Configure with UKG-provided ACS URL and Entity ID
3. Download IdP certificate and metadata

**Step 3: Send Configuration to UKG**
1. Send Certificate (Base64) to UKG support
2. Send SSO URL and configuration
3. UKG configures SAML SSO connection on their side

**Step 4: Test and Verify**
1. Test SSO authentication
2. Verify proper user mapping
3. Enable for production users

**Time to Complete:** ~1-2 weeks (includes UKG support coordination)

---

### 1.2 Configure Multiple Identity Providers

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2 |

#### Description
Configure multiple IdPs for different user populations.

#### Rationale
**Why This Matters:**
- UKG Authentication Upgrade supports multiple IdPs
- Each IdP has unique vanity URL
- Employees navigate to correct sign-in page
- Supports complex organizational structures

#### ClickOps Implementation

**Step 1: Plan IdP Structure**
1. Identify user populations
2. Determine IdP requirements per population
3. Document vanity URL needs

**Step 2: Configure Additional IdPs**
1. Work with UKG SSO team
2. Configure each IdP separately
3. Test each configuration

---

### 1.3 Configure Single Logout (SLO)

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Enable IdP Service Level Objective (SLO) for session termination.

#### Rationale
**Why This Matters:**
- UKG supports IDP SLO functionality for SAML2
- Eliminates risks from not terminating IdP sessions
- Ensures complete logout across systems

#### ClickOps Implementation

**Step 1: Configure SLO in IdP**
1. Enable SLO in identity provider
2. Configure logout URL
3. Test logout functionality

**Step 2: Verify SLO**
1. Test complete logout flow
2. Verify IdP session terminated
3. Verify UKG session terminated

---

### 1.4 Configure SAML Response Signing

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Ensure SAML responses are properly signed.

#### Rationale
**Why This Matters:**
- UKG Workforce Central v8.1.2+ requires signed SAML responses
- In addition to signed SAML assertions
- Reflects security best practices

#### ClickOps Implementation

**Step 1: Configure IdP Signing**
1. Enable SAML response signing in IdP
2. Enable SAML assertion signing
3. Use strong signing algorithms (SHA-256)

**Step 2: Verify Configuration**
1. Test authentication flow
2. Verify signatures validated
3. Document configuration

---

## 2. Access Controls

### 2.1 Configure Role-Based Access Control

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using UKG's role model.

#### ClickOps Implementation

**Step 1: Review Security Roles**
1. Review predefined roles
2. Understand role capabilities
3. Document role assignments

**Step 2: Apply Least Privilege**
1. Assign minimum necessary access
2. Separate HR and Payroll admin functions
3. Avoid over-assigning admin roles

**Step 3: Regular Access Reviews**
1. Quarterly access reviews
2. Review terminated employees
3. Update role assignments

---

### 2.2 Limit Admin Access

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
2. Document admin access levels
3. Identify unnecessary privileges

**Step 2: Apply Restrictions**
1. Limit admin accounts to 2-3 users
2. Require MFA for all admins
3. Monitor admin activity

---

### 2.3 Configure System Settings Security

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Configure system security settings.

#### ClickOps Implementation

**For UKG Workforce Central:**
1. Log on as SuperUser
2. Navigate to: **Setup** → **System Configuration** → **System Settings**
3. Click **Security** tab
4. Configure SSO and security settings

---

## 3. Data Protection

### 3.1 Configure Data Access Controls

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control access to sensitive employee data.

#### ClickOps Implementation

**Step 1: Classify Data**
1. Identify sensitive fields (SSN, salary, etc.)
2. Classify by sensitivity level
3. Document classification

**Step 2: Apply Access Controls**
1. Restrict access based on role
2. Limit sensitive data visibility
3. Audit data access

---

### 3.2 Configure Report Security

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control access to HR reports and analytics.

#### ClickOps Implementation

**Step 1: Review Report Access**
1. Audit report permissions
2. Identify sensitive reports
3. Restrict as needed

**Step 2: Configure Controls**
1. Apply role-based access
2. Limit export capabilities
3. Monitor report generation

---

## 4. Monitoring & Compliance

### 4.1 Configure Audit Logging

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor audit logs.

#### ClickOps Implementation

**Step 1: Enable Auditing**
1. Configure audit settings
2. Define retention period
3. Set up monitoring

**Step 2: Monitor Events**
1. Authentication events
2. Data access events
3. Configuration changes
4. Admin actions

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | UKG Pro Control | Guide Section |
|-----------|-----------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | RBAC | [2.1](#21-configure-role-based-access-control) |
| CC6.6 | SLO | [1.3](#13-configure-single-logout-slo) |
| CC7.2 | Audit logging | [4.1](#41-configure-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | UKG Pro Control | Guide Section |
|---------|-----------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| AC-6 | RBAC | [2.1](#21-configure-role-based-access-control) |
| AC-12 | SLO | [1.3](#13-configure-single-logout-slo) |
| SC-12 | SAML signing | [1.4](#14-configure-saml-response-signing) |
| AU-2 | Audit logging | [4.1](#41-configure-audit-logging) |

---

## Appendix A: References

**Official UKG Documentation:**
- Contact: UFSSO@ukg.com for SSO configuration
- [UKG Pro SSO Documentation](https://library.ukg.com/a/183581)
- [Microsoft Entra Integration](https://learn.microsoft.com/en-us/entra/identity/saas-apps/ultipro-tutorial)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, RBAC, and security controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
