---
layout: guide
title: "Gusto Hardening Guide"
vendor: "Gusto"
slug: "gusto"
tier: "5"
category: "HR/Finance"
description: "Payroll security for admin controls, partner integrations, and bank account protection"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---


## Overview

Gusto is a payroll and benefits platform for small-medium businesses. REST API and partner integrations access employee SSN, bank accounts, compensation, and tax information. Compromised access enables payroll fraud and exposes highly sensitive PII.

### Intended Audience
- Security engineers managing payroll systems
- Gusto administrators
- GRC professionals assessing payroll compliance
- Third-party risk managers evaluating HR integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers Gusto security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API Security](#2-api-security)
3. [Data Security](#3-data-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require 2-step verification (MFA) for all Gusto administrators, and enable login notifications, trusted-device controls, and active-session review.

#### Rationale
**Why This Matters:**
- Gusto admin accounts control employee SSNs, bank account details, compensation data, and tax filings, so a password-only login is the weakest link in the platform
- Payroll systems are prime targets for phishing and credential stuffing because access converts directly into redirected payments
- 2-step verification stops attackers who have already harvested or guessed a valid password
- Login notifications and session review surface unauthorized access attempts before fraud is committed

**Attack Prevented:** Credential theft, phishing, credential stuffing, account takeover

#### ClickOps Implementation

**Step 1: Enable 2-Step Verification**
1. Navigate to: **Settings → Security**
2. Enable: **Require 2-step verification**
3. Configure for all admins

**Step 2: Configure Login Security**
1. Enable login notifications
2. Configure trusted devices
3. Review active sessions

---

### 1.2 Admin Access Controls

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Define least-privilege Gusto admin roles (Primary Admin, Full Admin, Limited Admin, No Access) and minimize the number of full administrators.

#### Rationale
**Why This Matters:**
- Every full admin can view and modify payroll, bank accounts, and employee PII, so each extra full-admin account multiplies the blast radius of a single compromise
- Limited admin roles scope each person to only the tasks they need, enforcing least privilege
- Fewer full admins means fewer high-value credentials for attackers to target and fewer accounts to monitor
- Role separation creates accountability and makes anomalous privilege use easier to spot

**Attack Prevented:** Privilege escalation, insider abuse, lateral movement, excessive-permission exploitation

#### ClickOps Implementation

**Step 1: Define Admin Roles**

| Role | Permissions |
|------|-------------|
| Primary Admin | Full access |
| Full Admin | Most admin functions |
| Limited Admin | Specific access |
| No Access | Employee only |

**Step 2: Configure Admin Permissions**
1. Navigate to: **Team → Admins**
2. Limit full admin count
3. Use limited admin for specific tasks

---

## 2. API Security

### 2.1 Partner Integration Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Manage Gusto partner integrations securely.

#### Rationale
**Attack Scenario:** Compromised API partner access enables bank account modification; payroll fraud redirects employee payments.

**Why This Matters:**
- Connected partner apps hold delegated access to payroll and banking data, so a compromised or over-permissioned integration is an indirect path to fraud
- Unused or forgotten connections retain standing access long after they are needed, expanding the attack surface
- Reviewing and scoping integration permissions enforces least privilege on third-party access
- Quarterly auditing catches credential leakage or abuse from a partner before it is used to alter payments

**Attack Prevented:** Supply chain compromise, OAuth token abuse, unauthorized data access, bank account modification

#### ClickOps Implementation

**Step 1: Review Connected Apps**
1. Navigate to: **Settings → Connected Apps**
2. Review all partner integrations
3. Remove unused connections

**Step 2: Integration Best Practices**
1. Limit integration permissions
2. Audit data access
3. Review quarterly

---

## 3. Data Security

### 3.1 Protect Payroll Data

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Restrict who can view and modify payroll, SSN, and bank account data, and require approval and verification workflows for payroll and bank account changes.

#### Rationale
**Why This Matters:**
- Payroll records hold the most sensitive employee PII (SSNs, salaries, and bank routing details), which carries legal and financial liability if exposed
- Limiting data visibility enforces need-to-know and shrinks the set of accounts that can leak or alter sensitive fields
- Approval workflows for bank account and payroll changes prevent a single compromised account from silently redirecting payments
- Payment notifications give employees and admins a chance to catch fraudulent changes before funds move

**Attack Prevented:** Payroll diversion fraud, bank account hijacking, PII exposure, unauthorized data modification

#### ClickOps Implementation

**Step 1: Limit Data Access**
1. Restrict who can view payroll
2. Limit SSN visibility
3. Protect bank account data

**Step 2: Approval Workflows**
1. Require approval for payroll changes
2. Enable bank account change verification
3. Configure payment notifications

---

### 3.2 Document Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Limit access to tax documents such as W-2 and 1099 forms, and control who can view and download them.

#### Rationale
**Why This Matters:**
- Tax documents bundle name, SSN, address, and earnings — exactly the data needed for identity theft and fraudulent tax filing
- Broad download permissions let a single admin exfiltrate the entire workforce's PII in one export
- Restricting document access enforces least privilege and reduces accidental or malicious disclosure
- Controlling downloads limits how far sensitive records can travel outside Gusto's protected environment

**Attack Prevented:** Identity theft, tax-refund fraud, bulk PII exfiltration, unauthorized document disclosure

#### ClickOps Implementation

**Step 1: Document Access**
1. Limit who can view tax documents
2. Restrict W-2/1099 access
3. Configure download permissions

---

## 4. Monitoring & Detection

### 4.1 Activity Monitoring

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Monitor administrative logins, payroll changes, and bank account updates, and alert on sensitive activity.

#### Rationale
**Why This Matters:**
- Without activity logging, account takeover and payroll fraud can proceed undetected until employees report missing pay
- Monitoring admin logins surfaces unusual access patterns such as new locations or off-hours sign-ins
- Alerting on bank account updates targets the single highest-risk action an attacker can take on a payroll system
- An audit trail of payroll changes supports investigation, attribution, and compliance reporting after an incident

**Attack Prevented:** Undetected account takeover, payroll fraud, unauthorized bank account changes, insider abuse

#### ClickOps Implementation

**Step 1: Review Activity**
1. Monitor admin logins
2. Track payroll changes
3. Alert on bank account updates

#### Detection Focus

---

## Appendix A: Edition Compatibility

| Control | Simple | Plus | Premium |
|---------|--------|------|---------|
| 2-Step Verification | ✅ | ✅ | ✅ |
| Admin Roles | ✅ | ✅ | ✅ |
| API Access | Limited | ✅ | ✅ |
| Priority Support | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Gusto Documentation:**
- [Trust Center](https://trust.gusto.com/resources)
- [Gusto Security](https://gusto.com/security)
- [Help Center](https://support.gusto.com/)
- [Prevent Fraud on Your Gusto Account](https://support.gusto.com/article/106621992100000/Prevent-fraud-on-your-Gusto-account)

**API & Developer Tools:**
- [Gusto API Documentation](https://docs.gusto.com/)
- [Security Review for App Integrations](https://docs.gusto.com/app-integrations/docs/security-review)

**Compliance Frameworks:**
- SOC 1, SOC 2, HIPAA -- via [Trust Center](https://trust.gusto.com/resources) (NDA required for report access)
- [Request Access to SOC Reports and Bridge Letters](https://support.gusto.com/article/105983845100000/Request-access-to-SOC-reports-and-bridge-letters)

**Security Incidents:**
- No major public security incidents identified as of February 2026.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Gusto hardening guide | Claude Code (Opus 4.5) |
