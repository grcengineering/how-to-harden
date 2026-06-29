---
layout: guide
title: "Braze Hardening Guide"
vendor: "Braze"
slug: "braze"
tier: "2"
category: "Marketing"
description: "Customer engagement platform hardening for Braze including SAML SSO, permission sets, and API security"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---

## Overview

Braze is a leading customer engagement platform serving **thousands of brands** for mobile and web marketing automation. As a platform handling customer PII and engagement data, Braze security configurations directly impact data protection and marketing compliance.

### Intended Audience
- Security engineers managing marketing platforms
- IT administrators configuring Braze
- Marketing operations managing campaigns
- GRC professionals assessing marketing security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication for Braze users.

#### Rationale
**Why This Matters:**
- Centralizes Braze dashboard authentication in your corporate IdP, enforcing MFA and conditional access policies on every login
- Local Braze passwords bypass IdP controls and are prime targets for credential stuffing and phishing
- Centralized provisioning and deprovisioning removes access for departed users immediately, eliminating orphaned accounts with standing access to customer data
- The Braze dashboard exposes customer PII, message content, and campaign automation, so a single compromised login can expose subscriber lists and send rogue messages

**Attack Prevented:** Credential theft, phishing, account takeover, orphaned-account access

#### Prerequisites
- Braze admin access
- SAML 2.0 compatible IdP
- SSO feature enabled (enterprise plans)

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Braze users.

#### Rationale
**Why This Matters:**
- A second authentication factor stops attackers who have already obtained a valid password from logging in
- Marketing platform credentials are frequently exposed through password reuse, phishing, and infostealer malware
- Enforcing 2FA company-wide closes the gap left by users who would otherwise skip optional MFA
- Braze accounts control customer messaging at scale, so account takeover can lead to mass spam, phishing of subscribers, and data exfiltration

**Attack Prevented:** Credential stuffing, password reuse, phishing, account takeover

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

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Restrict dashboard access to approved IP ranges.

#### Rationale
**Why This Matters:**
- Restricting dashboard logins to known corporate or VPN egress ranges blocks login attempts from arbitrary locations
- Even with valid stolen credentials, an attacker outside the allowlist cannot reach the dashboard
- Network-layer restrictions add defense in depth on top of SSO and 2FA
- Limits exposure of customer PII and campaign tooling to a defined, auditable set of source networks

**Attack Prevented:** Remote credential abuse, account takeover from unknown locations, unauthorized dashboard access

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Braze permission sets.

#### Rationale
**Why This Matters:**
- Least-privilege permission sets ensure each user can only access the data and functions their role requires
- Over-permissioned accounts expand the blast radius when any single account is compromised
- Granular roles limit who can export customer data, send campaigns, or change platform settings
- Separating marketer, analyst, developer, and admin duties reduces both insider risk and accidental misuse

**Attack Prevented:** Privilege escalation, insider data theft, lateral movement, accidental data exposure

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

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control access to workspaces and app groups.

#### Rationale
**Why This Matters:**
- Workspace and app-group boundaries keep each team's customer data and campaigns isolated from one another
- Limiting cross-workspace access prevents one compromised account from reaching every brand or environment
- Separating production from test data reduces the chance of accidental sends or leaks of real subscriber data
- Scoped access supports tenant separation and data-handling requirements in multi-brand deployments

**Attack Prevented:** Cross-tenant data exposure, lateral movement, accidental production sends, scope creep

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect administrator accounts.

#### Rationale
**Why This Matters:**
- Admin accounts can change security settings, manage users, and access all customer data, making them high-value targets
- Keeping the admin count small reduces the attack surface and simplifies monitoring of privileged activity
- Requiring 2FA on admins protects the accounts capable of disabling other security controls
- A compromised admin could remove SSO enforcement, create rogue API keys, or exfiltrate the entire subscriber base

**Attack Prevented:** Admin account takeover, privilege abuse, security control tampering, mass data exfiltration

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure API keys and access tokens.

#### Rationale
**Why This Matters:**
- Braze REST API keys can read and write customer data and trigger messages, so a leaked key is equivalent to a compromised account
- Scoping keys to the minimum required permissions limits what an attacker can do if a key is exposed
- Separate keys per integration enable targeted rotation and revocation without breaking every integration
- Regular rotation and secure vault storage prevent long-lived secrets from lingering in code, logs, or config files

**Attack Prevented:** API key leakage, unauthorized data access, message spoofing, hardcoded-credential exposure

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

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Restrict API access to approved IP ranges.

#### Rationale
**Why This Matters:**
- Binding API keys to your application server IP ranges renders a stolen key useless from any other location
- IP restrictions add a network-layer control that survives even if a key is exposed in code or logs
- Constraining API origins makes anomalous access from unexpected addresses easy to detect and block
- Protects high-volume data and messaging endpoints from abuse by external actors

**Attack Prevented:** Stolen API key reuse, credential abuse from unknown hosts, automated API abuse

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor activity logs.

#### Rationale
**Why This Matters:**
- Activity logs provide the audit trail needed to detect unauthorized logins, permission changes, and API key creation
- Without logging, account compromise and insider misuse can go unnoticed until customer data is already exposed
- Monitoring authentication and configuration events enables timely alerting and incident response
- Retained logs are essential evidence for forensic investigation and compliance audits

**Attack Prevented:** Undetected account compromise, insider abuse, delayed breach detection, audit gaps

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

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | SI-12 |

#### Description
Configure data retention policies.

#### Rationale
**Why This Matters:**
- Limiting how long customer PII and event data are retained shrinks the volume of sensitive data exposed in any breach
- Defined retention and deletion workflows satisfy GDPR and CCPA data-subject deletion obligations
- Purging stale data reduces the regulatory and reputational impact of a compromise
- Documented retention policies prevent indefinite accumulation of sensitive subscriber records

**Attack Prevented:** Excessive data exposure in a breach, regulatory non-compliance, data-subject rights violations

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
- [Braze Trust & Security](https://www.braze.com/product/trust)
- [Braze User Guide](https://www.braze.com/docs/user_guide/introduction)
- [Security Settings](https://www.braze.com/docs/user_guide/administrative/app_settings/company_settings/security_settings)
- [Security Qualifications](https://www.braze.com/docs/developer_guide/disclosures/security_qualifications)
- [SAML SSO Setup](https://www.braze.com/docs/user_guide/administrative/access_braze/single_sign_on/)
- [Permission Sets](https://www.braze.com/docs/user_guide/administrative/manage_your_braze_users/user_permissions/)

**API Documentation:**
- [Braze REST API Reference](https://www.braze.com/docs/api/home)
- [Security & Vulnerability Disclosure](https://www.braze.com/docs/developer_guide/disclosures/security_and_vulnerability_disclosure)

**Compliance Frameworks:**
- SOC 2 Type II (Security & Availability), ISO 27001 (renewed August 2025, expires December 2027), HIPAA — via [Security Qualifications](https://www.braze.com/docs/developer_guide/disclosures/security_qualifications)

**Security Incidents:**
- **2024 — Major platform outage (April 29).** Braze US clusters experienced a near-total outage lasting approximately 11 hours caused by a malfunctioning network switch triggering a spanning tree switching loop. This was described as the first incident of this magnitude in Braze's 13-year history. Dashboard access, data processing, and message sends were all impacted. ([Braze Post-Incident Report](https://www.braze.com/resources/articles/april-29-braze-outage-causes-and-response))
- No major public data breaches identified.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, permissions, and API security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
