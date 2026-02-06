---
layout: guide
title: "Paylocity Hardening Guide"
vendor: "Paylocity"
slug: "paylocity"
tier: "2"
category: "HR & Finance"
description: "HCM platform hardening for Paylocity including SAML SSO configuration, MFA enforcement, and role-based access controls"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Paylocity is a leading cloud-based human capital management (HCM) and payroll platform serving **thousands of organizations**. As a repository for sensitive employee PII, financial data, and payroll information, Paylocity security configurations directly impact data protection and regulatory compliance.

### Intended Audience
- Security engineers managing HR systems
- HR administrators configuring Paylocity
- IT administrators managing SSO integration
- GRC professionals assessing HR platform security

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Paylocity security including SAML SSO, MFA, role-based access control, and session security.

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
Configure SAML SSO to centralize authentication for Paylocity users.

#### Prerequisites
- [ ] Paylocity account with SSO feature enabled
- [ ] Contact Paylocity Support (service@paylocity.com) to enable SAML 2.0
- [ ] SAML 2.0 compatible identity provider

#### ClickOps Implementation

**Step 1: Request SSO Enablement**
1. Contact Paylocity Support at service@paylocity.com
2. Request SAML 2.0 enablement for your account
3. Obtain SSO configuration access

**Step 2: Configure Identity Provider**
1. Create SAML application in IdP
2. Configure attribute mappings per Paylocity requirements
3. Download IdP metadata

**Step 3: Configure Paylocity SSO**
1. Navigate to: **HR & Payroll** → **User Access** → **SSO Configuration**
2. Select **Add SSO Integration**
3. Select your SSO provider from dropdown
4. Upload or drag-and-drop metadata file
5. Paylocity parses Issuer, Post Redirect, Binding URLs, and Certificates
6. Select **Save**

**Step 4: Test Configuration**
1. Test SSO authentication
2. Verify attribute mapping
3. Enable for production

**Time to Complete:** ~2 hours

---

### 1.2 Enable Multi-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all Paylocity users.

#### Rationale
**Why This Matters:**
- MFA adds critical layer beyond passwords
- Guards against credential theft
- Required for accessing sensitive employee PII
- Supports biometric and one-time codes

#### ClickOps Implementation

**Step 1: Configure via SSO IdP**
1. Enable MFA in identity provider
2. All SSO users subject to IdP MFA policies
3. Use phishing-resistant methods for admins

**Step 2: Configure Native MFA (if applicable)**
1. Enable MFA for direct login users
2. Configure supported methods:
   - One-time codes
   - Authenticator apps
   - Biometric verification
3. Require MFA for all admin accounts

---

### 1.3 Configure Session Security

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Configure session timeout and security controls.

#### ClickOps Implementation

**Step 1: Configure Session Controls**
1. Session control extends from Conditional Access
2. Configure session timeout
3. Protects against data exfiltration

**Step 2: Enable Conditional Access (via IdP)**
1. Configure conditional access policies
2. Require compliant devices
3. Block risky sign-ins

---

## 2. Access Controls

### 2.1 Configure Role-Based Access Control

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Paylocity's RBAC model.

#### Rationale
**Why This Matters:**
- RBAC enforces organizational policies
- Employees only perform permitted actions
- Critical for protecting employee PII
- Supports multiple role types

#### ClickOps Implementation

**Step 1: Review Security Roles**
1. Navigate to: **User Access** → **Security Roles**
2. Review predefined roles:
   - HR Admin
   - Payroll Specialist
   - Manager
   - Employee
3. Understand role capabilities

**Step 2: Assign Minimum Necessary Access**
1. Apply least-privilege principle
2. Assign roles based on job function
3. Avoid over-assigning admin roles

**Step 3: Create Custom Roles (if needed)**
1. Create custom roles for specific needs
2. Define granular permissions
3. Document role purposes

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
1. Review all users with admin roles
2. Document admin access
3. Identify unnecessary privileges

**Step 2: Apply Least Privilege**
1. Limit HR Admin to 2-3 users
2. Limit Payroll Specialist access
3. Remove unnecessary admin access

**Step 3: Protect Admin Accounts**
1. Require MFA for all admins
2. Use phishing-resistant MFA
3. Monitor admin activity

---

### 2.3 Configure Manager Self-Service

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Configure appropriate manager access for self-service functions.

#### ClickOps Implementation

**Step 1: Define Manager Permissions**
1. Configure manager view access
2. Limit to direct reports only
3. Restrict sensitive data access

**Step 2: Configure Approval Workflows**
1. Enable manager approval workflows
2. Configure time-off approvals
3. Set up expense approvals

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

**Step 1: Classify Data Sensitivity**
1. Identify PII fields (SSN, salary, benefits)
2. Classify by sensitivity level
3. Document data classification

**Step 2: Apply Access Restrictions**
1. Restrict SSN access to authorized roles
2. Limit salary visibility
3. Control benefits data access

---

### 3.2 Configure Report Access

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control access to HR reports and analytics.

#### ClickOps Implementation

**Step 1: Review Report Permissions**
1. Audit report access by role
2. Identify sensitive reports
3. Restrict as needed

**Step 2: Configure Report Security**
1. Apply role-based report access
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
Enable and monitor audit logs for security events.

#### ClickOps Implementation

**Step 1: Review Audit Capabilities**
1. Understand logged events
2. Configure audit retention
3. Set up monitoring

**Step 2: Monitor Key Events**
1. User authentication events
2. Data access events
3. Configuration changes
4. Permission changes

---

### 4.2 Configure Compliance Controls

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CA-7 |

#### Description
Configure controls for regulatory compliance.

#### ClickOps Implementation

**Step 1: Enable Compliance Features**
1. Configure for SOX compliance (if applicable)
2. Enable audit trails for payroll changes
3. Document approval workflows

**Step 2: Regular Reviews**
1. Conduct quarterly access reviews
2. Review terminated employee access
3. Document compliance status

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Paylocity Control | Guide Section |
|-----------|-------------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | RBAC | [2.1](#21-configure-role-based-access-control) |
| CC6.6 | Session security | [1.3](#13-configure-session-security) |
| CC7.2 | Audit logging | [4.1](#41-configure-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | Paylocity Control | Guide Section |
|---------|-------------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | MFA | [1.2](#12-enable-multi-factor-authentication) |
| AC-6 | RBAC | [2.1](#21-configure-role-based-access-control) |
| AC-3 | Data access | [3.1](#31-configure-data-access-controls) |
| AU-2 | Audit logging | [4.1](#41-configure-audit-logging) |

---

## Appendix A: References

**Official Paylocity Documentation:**
- [Identity and Access Management Guide](https://www.paylocity.com/resources/learn/articles/identity-access-management/)
- [SSO Integration](https://www.paylocity.com/resources/glossary/sso/)
- Contact: service@paylocity.com for SSO enablement

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, RBAC, and data protection | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
