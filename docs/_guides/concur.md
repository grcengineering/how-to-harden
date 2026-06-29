---
layout: guide
title: "SAP Concur Hardening Guide"
vendor: "SAP"
slug: "concur"
tier: "2"
category: "HR/Finance"
description: "Travel and expense management platform hardening for SAP Concur including SAML SSO, expense policies, and audit controls"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---

## Overview

SAP Concur is a leading travel, expense, and invoice management platform serving **millions of users** worldwide. As a platform handling financial transactions and travel data, Concur security configurations directly impact expense integrity and compliance.

### Intended Audience
- Security engineers managing expense systems
- IT administrators configuring Concur
- Finance administrators managing travel and expense
- GRC professionals assessing financial platform security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers SAP Concur security including SAML SSO, expense policies, approval workflows, and audit controls.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Expense Policies](#3-expense-policies)
4. [Monitoring & Compliance](#4-monitoring--compliance)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure SAML Single Sign-On

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication for Concur users.

#### Rationale
**Why This Matters:**
- Centralizes Concur authentication in your corporate IdP, enforcing MFA, conditional access, and consistent password policy on every login
- Native Concur passwords bypass IdP controls and are prime targets for credential stuffing and phishing campaigns that impersonate the expense portal
- Centralized SSO enables immediate deprovisioning when employees leave, eliminating orphaned accounts that retain access to financial data and reimbursement workflows
- Concur holds employee travel itineraries, corporate card data, and reimbursement banking details — a single compromised login can expose all of it

**Attack Prevented:** Credential theft, phishing, password reuse, orphaned-account access

#### Prerequisites
- SAP Concur admin access
- SAP Cloud Identity Services or external IdP
- SAML 2.0 configuration details

#### ClickOps Implementation

**Step 1: Access SSO Configuration**
1. Navigate to: **Administration** → **Company** → **Authentication Admin**
2. Select **SSO** configuration

**Step 2: Configure Identity Provider**
1. Upload IdP metadata
2. Configure Entity ID
3. Configure SSO URL
4. Upload IdP certificate

**Step 3: Configure Attribute Mapping**
1. Map SAML attributes to Concur fields
2. Configure user identifier
3. Configure company assignment

**Step 4: Test and Enable**
1. Test SSO authentication
2. Verify user provisioning
3. Enable for all users

**Time to Complete:** ~2 hours

---

### 1.2 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all Concur users.

#### Rationale
**Why This Matters:**
- Adds a second authentication factor so a stolen or guessed password alone cannot grant access to expense and travel data
- Expense approvers can authorize payments and reimbursements — phishing-resistant MFA on these accounts blocks attackers who target approval authority
- Mobile app PIN/biometric and remote wipe protect cached expense data if a device is lost or stolen
- Concur is frequently impersonated in credential-phishing lures; MFA defeats the reused-credential step of those campaigns

**Attack Prevented:** Credential stuffing, phishing, account takeover, payment fraud via compromised approver

#### ClickOps Implementation

**Step 1: Configure via IdP**
1. Enable MFA in identity provider
2. All SSO users subject to IdP MFA
3. Use phishing-resistant methods for approvers

**Step 2: Mobile Device Security**
1. Configure SAP Concur mobile app security
2. Require device PIN/biometric
3. Enable remote wipe capability

---

### 1.3 Configure Session Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Configure session timeout settings.

#### Rationale
**Why This Matters:**
- Idle session timeouts limit the window an attacker has to hijack an authenticated session on an unattended or shared device
- Finance and approver workstations often sit unlocked in shared offices — short timeouts reduce exposure of expense and banking data
- Bounded session lifetimes force periodic re-authentication, shrinking the value of stolen session tokens
- Concur sessions can submit and approve reimbursements, so an abandoned live session is a direct path to fraudulent payments

**Attack Prevented:** Session hijacking, unauthorized access via unattended sessions, session token replay

#### ClickOps Implementation

**Step 1: Configure Timeout**
1. Navigate to: **Administration** → **Company** → **Company Admin**
2. Configure session timeout
3. Balance security with usability

---

## 2. Access Controls

### 2.1 Configure Role-Based Access Control

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Concur's role model.

#### Rationale
**Why This Matters:**
- Assigns only the permissions each user needs, so a compromised employee account cannot reach approver or administrator functions
- Separating Employee, Expense Approver, Invoice Approver, and Administrator roles enforces separation of duties across the expense lifecycle
- Least privilege contains the blast radius of any single account compromise, limiting access to financial data and payment workflows
- Over-broad roles let ordinary users alter policies or approve their own spend, undermining expense controls

**Attack Prevented:** Privilege escalation, lateral movement, insider abuse, expense fraud

#### ClickOps Implementation

**Step 1: Review Roles**
1. Navigate to: **Administration** → **Company** → **Company Admin**
2. Review roles:
   - Employee
   - Expense Approver
   - Invoice Approver
   - Administrator
3. Understand role capabilities

**Step 2: Assign Minimum Necessary Access**
1. Apply least-privilege principle
2. Separate employee and approver roles
3. Limit admin access

---

### 2.2 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect administrator accounts.

#### Rationale
**Why This Matters:**
- Administrator accounts can change authentication settings, policies, and approval workflows — restricting their number shrinks the highest-value attack surface
- Requiring MFA and monitoring on admin accounts makes compromise harder and detectable
- Fewer admins means fewer credentials that, if stolen, could disable security controls or reroute reimbursements
- Unmonitored admin access enables silent tampering with expense policy and audit configuration

**Attack Prevented:** Admin account takeover, privilege abuse, security control tampering, undetected configuration changes

#### ClickOps Implementation

**Step 1: Inventory Admin Users**
1. Review admin accounts
2. Document admin privileges
3. Identify unnecessary access

**Step 2: Apply Restrictions**
1. Limit admin to 2-3 users
2. Require MFA for admins
3. Monitor admin activity

---

### 2.3 Configure Delegate Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control delegate access for expense management.

#### Rationale
**Why This Matters:**
- Delegates act on another user's behalf, so uncontrolled delegate grants can quietly expand who can submit or approve expenses
- Limiting and approving delegate setup preserves accountability and separation of duties in the approval chain
- Auditing delegate actions ensures every expense action ties back to an authorized, identifiable person
- Unrestricted delegation lets a single account aggregate approval authority and obscure fraudulent activity

**Attack Prevented:** Authorization sprawl, separation-of-duties bypass, accountability evasion, delegated expense fraud

#### ClickOps Implementation

**Step 1: Configure Delegate Policies**
1. Define who can have delegates
2. Limit delegate permissions
3. Require approval for delegate setup

**Step 2: Monitor Delegate Usage**
1. Audit delegate actions
2. Review delegate assignments
3. Regular access reviews

---

## 3. Expense Policies

### 3.1 Configure Expense Policy Rules

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-5 |

#### Description
Configure expense policies for compliance.

#### Rationale
**Why This Matters:**
- Encoded spending limits, receipt requirements, and per diem rates automatically flag out-of-policy spend before reimbursement
- Automated policy enforcement reduces reliance on manual review, catching violations that busy approvers might miss
- Consistent policy rules support audit readiness and regulatory compliance for travel and expense spend
- Without enforced policies, inflated, duplicate, or non-compliant expenses pass through undetected

**Attack Prevented:** Expense fraud, policy circumvention, inflated and duplicate claims, compliance gaps

#### ClickOps Implementation

**Step 1: Define Expense Types**
1. Configure expense categories
2. Set spending limits
3. Define receipt requirements

**Step 2: Configure Policy Rules**
1. Set per diem rates
2. Configure mileage rates
3. Define approval thresholds

**Step 3: Enable Policy Enforcement**
1. Configure policy violations
2. Set up notifications
3. Enable automated checks

---

### 3.2 Configure Approval Workflows

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-5 |

#### Description
Configure expense approval workflows.

#### Rationale
**Why This Matters:**
- Multi-level approval chains ensure no expense is reimbursed without independent review proportional to its amount
- Preventing submitters from approving their own expenses enforces separation of duties, a core anti-fraud control
- Escalation rules and approval limits route high-value spend to appropriate authority, preventing unauthorized large payments
- An audit trail of approvals creates accountability and supports investigation of suspicious reimbursements

**Attack Prevented:** Self-approval fraud, separation-of-duties bypass, unauthorized payments, collusion concealment

#### ClickOps Implementation

**Step 1: Configure Approval Chains**
1. Define approval hierarchy
2. Configure approval limits
3. Set escalation rules

**Step 2: Enforce Separation of Duties**
1. Submitters cannot approve own expenses
2. Configure multi-level approval
3. Enable audit trail

---

### 3.3 Configure Receipt Requirements

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Require receipts for expense documentation.

#### Rationale
**Why This Matters:**
- Mandatory receipts provide verifiable evidence that claimed expenses are real, deterring fabricated or inflated claims
- Receipt imaging and OCR validation catch mismatches between submitted amounts and supporting documentation
- Documented receipts create the audit trail needed for tax, regulatory, and internal compliance reviews
- Without receipt requirements, expenses can be claimed with no proof, enabling reimbursement fraud

**Attack Prevented:** Fabricated expense claims, inflated reimbursements, fraud through missing documentation, audit failures

#### ClickOps Implementation

**Step 1: Configure Receipt Policies**
1. Set receipt threshold
2. Define required receipt types
3. Configure itemization requirements

**Step 2: Enable Receipt Verification**
1. Enable receipt imaging
2. Configure OCR validation
3. Flag missing receipts

---

## 4. Monitoring & Compliance

### 4.1 Configure Audit Logging

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor audit logs.

#### Rationale
**Why This Matters:**
- Audit logs of submissions, approvals, policy violations, and admin changes provide the evidence needed to detect and investigate abuse
- Monitoring approval actions and admin changes surfaces unauthorized or anomalous behavior before it becomes systemic fraud
- Retained logs support forensic reconstruction after an incident and satisfy compliance evidence requirements
- Without auditing, fraudulent expenses and configuration tampering go unnoticed and unprovable

**Attack Prevented:** Undetected fraud, configuration tampering, repudiation, forensic and compliance gaps

#### ClickOps Implementation

**Step 1: Enable Auditing**
1. Configure audit trail
2. Set retention period
3. Enable monitoring

**Step 2: Monitor Events**
1. Expense submissions
2. Approval actions
3. Policy violations
4. Admin changes

---

### 4.2 Configure Expense Reports

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | AU-6 |

#### Description
Configure compliance reports.

#### Rationale
**Why This Matters:**
- Scheduled policy-violation and spend-analytics reports turn raw audit data into reviewable signals of misuse
- A regular review cadence (weekly, monthly, quarterly) ensures anomalies are caught promptly rather than discovered late
- Compliance reports give management and auditors evidence that expense controls are operating effectively
- Without reporting, policy violations and unusual spend patterns remain buried in logs and escape oversight

**Attack Prevented:** Undetected policy violations, slow fraud detection, oversight gaps, compliance reporting failures

#### ClickOps Implementation

**Step 1: Configure Reports**
1. Enable policy violation reports
2. Configure spend analytics
3. Set up audit reports

**Step 2: Schedule Reviews**
1. Weekly policy violation review
2. Monthly spend analysis
3. Quarterly audits

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Concur Control | Guide Section |
|-----------|----------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | RBAC | [2.1](#21-configure-role-based-access-control) |
| CC6.3 | Approval workflows | [3.2](#32-configure-approval-workflows) |
| CC7.2 | Audit logging | [4.1](#41-configure-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | Concur Control | Guide Section |
|---------|----------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | MFA | [1.2](#12-enforce-multi-factor-authentication) |
| AC-5 | Separation of duties | [3.2](#32-configure-approval-workflows) |
| AC-6 | RBAC | [2.1](#21-configure-role-based-access-control) |
| AU-2 | Audit logging | [4.1](#41-configure-audit-logging) |

---

## Appendix A: References

**Official SAP Concur Documentation:**
- [SAP Trust Center](https://www.sap.com/about/trust-center/certification-compliance.html)
- [SAP Concur Help Center](https://help.sap.com/docs/SAP_CONCUR)
- [SAP Concur Data Security](https://www.concur.com/en-us/data-security)
- [SAP Concur Security Best Practices](https://help.sap.com/docs/SAP_CONCUR_SECURITY/b92b8c7fc75a4c8faf62a6584077b022/9c81735f180a4fe380d05549f6d32d12.html)

**API Documentation:**
- [SAP Concur Developer Center](https://developer.concur.com)
- [Concur API Reference](https://developer.concur.com/api-reference/)

**Compliance Frameworks:**
- SOC 2 Type II (semi-annual audits since 2017; Security, Availability, Confidentiality, Privacy), SOC 1, ISO 27001 (certified since 2004 as BS 7799) — via [SAP Trust Center Compliance Finder](https://www.sap.com/about/trust-center/certification-compliance/compliance-finder.html)

**Security Incidents:**
- **2020 — SAP cloud product security standards gap.** SAP disclosed that some cloud products, including SAP Concur, did not meet certain contractually agreed IT security standards. Approximately 40,000 customers were potentially impacted. No customer data was believed compromised, and remediation patches were applied in Q2 2020.
- No major public data breaches specific to SAP Concur have been identified. The platform is a common target for credential phishing impersonation campaigns.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, RBAC, and expense policies | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
