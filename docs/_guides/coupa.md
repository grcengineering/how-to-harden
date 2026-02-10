---
layout: guide
title: "Coupa Hardening Guide"
vendor: "Coupa"
slug: "coupa"
tier: "2"
category: "HR & Finance"
description: "Procurement and spend management platform hardening for Coupa including SAML SSO, role-based access control, and data security"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Coupa is a leading business spend management platform serving **thousands of enterprises** for procurement, invoicing, and expense management. As a platform handling financial transactions and supplier data, Coupa security configurations directly impact financial integrity and compliance.

### Intended Audience
- Security engineers managing procurement systems
- IT administrators configuring Coupa
- Finance administrators managing spend management
- GRC professionals assessing financial platform security

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Coupa security including SAML SSO, role-based access control, approval workflows, and data protection.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Approval Workflows](#3-approval-workflows)
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
Configure SAML SSO to centralize authentication for Coupa users.

#### Prerequisites
- [ ] Coupa admin access
- [ ] SAML 2.0 compatible identity provider
- [ ] IdP metadata or configuration details

#### ClickOps Implementation

**Step 1: Access SSO Configuration**
1. Navigate to: **Setup** → **Security Controls** → **SSO Configuration**
2. Enable SAML SSO

**Step 2: Configure Identity Provider**
1. Enter IdP metadata URL or upload metadata
2. Configure Entity ID
3. Configure SSO URL
4. Upload IdP certificate

**Step 3: Configure Attribute Mapping**
1. Map SAML attributes to Coupa fields
2. Configure user identifier (email or employee ID)
3. Map role attributes if needed

**Step 4: Test and Enable**
1. Test SSO authentication
2. Verify user mapping
3. Enable for all users

**Time to Complete:** ~2 hours

---

### 1.2 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all Coupa users.

#### ClickOps Implementation

**Step 1: Configure via IdP**
1. Enable MFA in identity provider
2. All SSO users subject to IdP MFA
3. Use phishing-resistant methods for approvers

**Step 2: Configure Coupa MFA (if applicable)**
1. Enable native MFA for direct login
2. Configure supported methods
3. Require for admin accounts

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

**Step 1: Configure Session Timeout**
1. Navigate to: **Setup** → **Security Controls**
2. Configure session timeout duration
3. Balance security with usability

**Step 2: Configure IP Restrictions (L2)**
1. Enable IP allowlisting
2. Restrict access to corporate networks
3. Allow VPN access

---

## 2. Access Controls

### 2.1 Configure Role-Based Access Control

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Coupa's role model.

#### ClickOps Implementation

**Step 1: Review Role Structure**
1. Navigate to: **Setup** → **Users & Groups** → **Roles**
2. Review predefined roles
3. Understand role capabilities

**Step 2: Assign Minimum Necessary Access**
1. Apply least-privilege principle
2. Separate duties (requestor vs approver)
3. Limit admin access

**Step 3: Create Custom Roles (if needed)**
1. Create roles for specific functions
2. Define granular permissions
3. Document role purposes

---

### 2.2 Configure User Groups

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Organize users into groups for efficient access management.

#### ClickOps Implementation

**Step 1: Create Groups**
1. Navigate to: **Setup** → **Users & Groups** → **Groups**
2. Create groups by department or function
3. Assign roles to groups

**Step 2: Manage Group Membership**
1. Add users to appropriate groups
2. Users inherit group permissions
3. Regular membership reviews

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
2. Document admin privileges
3. Identify unnecessary access

**Step 2: Apply Restrictions**
1. Limit admin to 2-3 users
2. Require MFA for admins
3. Separate admin from approver roles

---

## 3. Approval Workflows

### 3.1 Configure Approval Chains

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-5 |

#### Description
Configure approval workflows for spend controls.

#### Rationale
**Why This Matters:**
- Approval chains enforce segregation of duties
- Prevents unauthorized spend
- Required for SOX compliance
- Supports financial controls

#### ClickOps Implementation

**Step 1: Configure Approval Groups**
1. Navigate to: **Setup** → **Approval** → **Approval Groups**
2. Create approval groups by spend limit
3. Assign approvers to groups

**Step 2: Configure Approval Limits**
1. Set spend thresholds per approval level
2. Configure escalation rules
3. Document approval matrix

**Step 3: Enforce Separation of Duties**
1. Requestors cannot approve own requests
2. Configure multi-level approval
3. Enable audit trail

---

### 3.2 Configure Supplier Management Controls

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-5 |

#### Description
Control supplier creation and management.

#### ClickOps Implementation

**Step 1: Configure Supplier Workflows**
1. Require approval for new suppliers
2. Configure supplier verification
3. Enable supplier risk assessment

**Step 2: Restrict Supplier Modifications**
1. Limit who can modify supplier data
2. Audit supplier changes
3. Require approval for bank info changes

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

**Step 1: Review Audit Settings**
1. Verify auditing enabled
2. Configure retention period
3. Set up monitoring

**Step 2: Monitor Key Events**
1. Authentication events
2. Approval actions
3. Configuration changes
4. Supplier modifications

---

### 4.2 Configure Compliance Reports

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | AU-6 |

#### Description
Configure compliance and audit reports.

#### ClickOps Implementation

**Step 1: Configure Reports**
1. Enable SOX compliance reports
2. Configure access review reports
3. Set up approval audit reports

**Step 2: Schedule Regular Reviews**
1. Weekly approval reviews
2. Monthly access reviews
3. Quarterly compliance audits

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Coupa Control | Guide Section |
|-----------|---------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | RBAC | [2.1](#21-configure-role-based-access-control) |
| CC6.3 | Approval workflows | [3.1](#31-configure-approval-chains) |
| CC7.2 | Audit logging | [4.1](#41-configure-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | Coupa Control | Guide Section |
|---------|---------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | MFA | [1.2](#12-enforce-multi-factor-authentication) |
| AC-5 | Separation of duties | [3.1](#31-configure-approval-chains) |
| AC-6 | RBAC | [2.1](#21-configure-role-based-access-control) |
| AU-2 | Audit logging | [4.1](#41-configure-audit-logging) |

---

## Appendix A: References

**Official Coupa Documentation:**
- [Coupa Trust Center](https://compass.coupa.com/en-us/trust)
- [Coupa Compliance & Security](https://www.coupa.com/compliance-security/)
- [Coupa Product Documentation](https://compass.coupa.com/en-us/products/product-documentation)
- [MFA FAQ & Security Best Practices](https://compass.coupa.com/en-us/products/product-documentation/supplier-resources/for-suppliers/core-supplier-onboarding/announcements-and-general-info/mfa-faq-and-security-best-practices)

**API Documentation:**
- [Coupa Core API](https://compass.coupa.com/en-us/products/product-documentation/integration-technical-documentation/the-coupa-core-api)

**Compliance Frameworks:**
- SOC 1 Type II, SOC 2 Type II (Security, Availability, Confidentiality), ISO 27001:2022, ISO 27701:2019, PCI DSS, HIPAA — via [Coupa Compliance & Security](https://www.coupa.com/compliance-security/)

**Security Incidents:**
- **2017 — W-2 phishing attack exposed employee data.** A social engineering attack impersonating Coupa's CEO tricked HR into releasing employee W-2 forms containing names, SSNs, wages, and tax details. Only 2016 employee data was affected; no customer data was compromised. Coupa reported the incident to the FBI and IRS. ([BankInfoSecurity](https://www.bankinfosecurity.com/silicon-valley-firm-coupa-hit-by-w-2-fraudsters-a-9788))

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, RBAC, and approval workflows | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
