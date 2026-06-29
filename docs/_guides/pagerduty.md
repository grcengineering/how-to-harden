---
layout: guide
title: "PagerDuty Hardening Guide"
vendor: "PagerDuty"
slug: "pagerduty"
tier: "2"
category: "IT Operations"
description: "Incident management platform hardening for PagerDuty including SSO configuration, user provisioning, and access controls"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---

## Overview

PagerDuty is a leading incident management platform used by **thousands of organizations** for on-call management, incident response, and operational intelligence. As a critical tool for incident response and system alerting, PagerDuty security configurations directly impact operational resilience.

### Intended Audience
- Security engineers managing incident platforms
- IT administrators configuring PagerDuty
- DevOps/SRE teams securing on-call workflows
- GRC professionals assessing operational security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers PagerDuty security including SAML SSO, user provisioning, role-based access, and account security.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [User Management](#2-user-management)
3. [Access Controls](#3-access-controls)
4. [Monitoring & Security](#4-monitoring--security)
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
Configure SAML SSO to centralize authentication for PagerDuty users.

#### Rationale
**Why This Matters:**
- Eliminates need for separate PagerDuty credentials
- Enables on-demand user provisioning
- Simplifies access revocation

#### Prerequisites
- PagerDuty Professional, Business, or Enterprise plan
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Account Settings** → **Single Sign-On**
2. Click **Configure SSO**

**Step 2: Configure Identity Provider**
1. PagerDuty supports:
   - Microsoft ADFS
   - Okta
   - OneLogin
   - Ping Identity
   - SecureAuth
2. Create SAML application in IdP

**Step 3: Enter IdP Settings**
1. Enter IdP SSO URL
2. Upload IdP certificate
3. Configure attribute mappings

**Step 4: Test and Enable**
1. Test SSO authentication
2. Verify user provisioning
3. Enable SSO for account

**Time to Complete:** ~1 hour

{% include pack-code.html vendor="pagerduty" section="1.1" %}

---

### 1.2 Manage SSO Certificate Rotation

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Maintain SAML certificate validity.

#### Rationale
**Why This Matters:**
- PagerDuty rotates SAML certificates annually
- Expired certificates break SSO authentication

#### ClickOps Implementation

**Step 1: Monitor Certificate Expiration**
1. PagerDuty sends communications about rotation
2. Note certificate expiration dates

**Step 2: Update Certificates**
1. Download new PagerDuty certificate
2. Update IdP configuration
3. Test SSO after update

---

### 1.3 Configure Account Owner Fallback

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Understand and protect Account Owner fallback access.

#### Rationale
**Why This Matters:**
- The Account Owner's email/password login is a permanent bypass of your SSO and MFA controls and exists on every PagerDuty account whether you protect it or not
- During an IdP or SSO outage this account is the only way to restore incident-response access, so its credentials must be both recoverable and rigorously protected in a vault
- Because the Account Owner can re-enable password login for every user, compromise of this single account collapses the entire SSO security model
- Incident management is a critical operational function — an attacker who seizes the Account Owner can suppress or reroute alerts during an active attack

**Attack Prevented:** SSO/MFA bypass, account takeover, credential theft, alert suppression during incident

#### ClickOps Implementation

**Step 1: Protect Account Owner Credentials**
1. Account Owners retain email/password login (cannot be disabled)
2. Use strong password (20+ characters)
3. Store in password vault

**Step 2: Document Recovery Procedure**
1. Account Owner can log in during SSO outage
2. Can temporarily enable password login for all users

{% include pack-code.html vendor="pagerduty" section="1.3" %}

---

## 2. User Management

### 2.1 Configure User Provisioning

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Configure automatic user provisioning via SSO.

#### Rationale
**Why This Matters:**
- On-demand provisioning ensures only users your IdP has authorized can create a PagerDuty account, keeping the user directory tied to corporate identity
- Centralizing account creation in the IdP removes manual invite workflows that are easy to misconfigure or abuse to seed rogue accounts
- Because SAML attributes are applied only at initial creation and do not later sync, understanding this behavior prevents stale role assignments that silently grant more access than intended
- Tying account creation to IdP group membership shrinks the pool of accounts an attacker can phish or target

**Attack Prevented:** Unauthorized account creation, privilege drift, orphaned accounts

#### ClickOps Implementation

**Step 1: Enable On-Demand Provisioning**
1. With SSO enabled, users created on first login
2. Access granted via IdP assignment

**Step 2: Configure SAML Attributes**
1. Configure IdP to send email, name, role
2. Note: Attributes only used at initial creation
3. Changes in IdP don't sync to PagerDuty

{% include pack-code.html vendor="pagerduty" section="2.1" %}

---

### 2.2 Configure SCIM Provisioning

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Configure SCIM for automated user lifecycle management.

#### Rationale
**Why This Matters:**
- SCIM automatically deprovisions departed employees, closing the gap that on-demand SSO provisioning leaves open when access is revoked only in the IdP
- Automated lifecycle management eliminates orphaned PagerDuty accounts that retain standing access to on-call schedules and incident data
- Centralizing create, update, and deactivate operations in the IdP keeps PagerDuty roles synchronized with current job function
- Removing manual offboarding steps reduces the window during which a former insider could still receive or act on production alerts

**Attack Prevented:** Orphaned-account access, insider threat, privilege creep, delayed offboarding

#### ClickOps Implementation

**Step 1: Enable SCIM**
1. Navigate to: **Account Settings** → **SCIM**
2. Generate SCIM API token
3. Copy SCIM base URL

**Step 2: Configure IdP SCIM**
1. Add PagerDuty SCIM integration
2. Enable deprovisioning

{% include pack-code.html vendor="pagerduty" section="2.2" %}

---

## 3. Access Controls

### 3.1 Configure Role-Based Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using PagerDuty roles.

#### Rationale
**Why This Matters:**
- Assigning the least-privileged role that fits each user's job limits what a compromised account can change, exfiltrate, or destroy
- Restricting Account Owner and Admin to a small group shrinks the high-value attack surface that grants account-wide control
- Granular roles (Manager, Responder, Observer, Limited User) prevent on-call engineers from holding administrative power they never need
- Proper role scoping protects integration keys, escalation policies, and audit settings from accidental or malicious modification

**Attack Prevented:** Privilege escalation, lateral movement, configuration tampering, blast-radius expansion

#### ClickOps Implementation

**Step 1: Review Available Roles**
1. Review role options:
   - **Account Owner:** Full control (1 per account)
   - **Admin:** Account administration
   - **Manager:** Team management
   - **Responder:** Incident response
   - **Observer:** View-only (Business/Enterprise)
   - **Limited User:** Restricted access

**Step 2: Assign Appropriate Roles**
1. Limit Admin to essential personnel (2-3)
2. Use Manager for team leads
3. Use Responder for on-call engineers

{% include pack-code.html vendor="pagerduty" section="3.1" %}

---

### 3.2 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect administrator accounts.

#### Rationale
**Why This Matters:**
- Admin accounts can modify integrations, escalation policies, and security settings, so each one is a high-value target whose compromise affects the whole account
- Reducing the number of admins to the minimum directly shrinks the attack surface exposed to phishing and credential theft
- Using the Manager role for routine team administration avoids handing out account-wide power for day-to-day tasks
- Fewer privileged accounts make anomalous admin activity easier to detect and investigate in audit logs

**Attack Prevented:** Admin account takeover, privilege escalation, unauthorized configuration changes

#### ClickOps Implementation

**Step 1: Inventory Admin Users**
1. Navigate to: **People** → **Users**
2. Filter by Admin role
3. Document all administrators

**Step 2: Apply Least Privilege**
1. Reduce admins to minimum (2-3)
2. Use Manager role for team administration

{% include pack-code.html vendor="pagerduty" section="3.2" %}

---

## 4. Monitoring & Security

### 4.1 Configure Audit Logging

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Monitor administrative and security events.

#### Rationale
**Why This Matters:**
- Audit records provide the evidence trail needed to detect unauthorized changes to users, roles, integrations, and SSO settings
- Exporting events to a SIEM enables correlation with other systems and near-real-time alerting on suspicious PagerDuty activity
- Without comprehensive logging, account compromise and insider misuse can go undetected and forensic investigation becomes impossible
- Retained audit logs satisfy compliance evidence requirements for SOC 2, ISO 27001, and similar frameworks

**Attack Prevented:** Undetected intrusion, insider misuse, untraceable tampering, compliance evidence gaps

#### ClickOps Implementation

**Step 1: Access Audit Records**
1. Navigate to: **Account Settings** → **Audit Records**
2. Review logged events

**Step 2: Export Logs**
1. Export audit records for analysis
2. Integrate with SIEM

{% include pack-code.html vendor="pagerduty" section="4.1" %}

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | PagerDuty Control | Guide Section |
|-----------|-------------------|---------------|
| CC6.1 | SSO/SAML | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | RBAC | [3.1](#31-configure-role-based-access) |
| CC7.2 | Audit logging | [4.1](#41-configure-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | PagerDuty Control | Guide Section |
|---------|-------------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| AC-2 | User provisioning | [2.1](#21-configure-user-provisioning) |
| AC-6 | Least privilege | [3.1](#31-configure-role-based-access) |
| AU-2 | Audit logging | [4.1](#41-configure-audit-logging) |

---

## Appendix A: Plan Compatibility

| Feature | Free | Professional | Business | Enterprise |
|---------|------|--------------|----------|------------|
| SSO/SAML | ❌ | ✅ | ✅ | ✅ |
| SCIM | ❌ | ❌ | ✅ | ✅ |
| Teams | ❌ | ❌ | ✅ | ✅ |
| Observer Role | ❌ | ❌ | ✅ | ✅ |

---

## Appendix B: References

**Official PagerDuty Documentation:**
- [Security at PagerDuty](https://www.pagerduty.com/security/)
- [Support Center](https://support.pagerduty.com/)
- [Single Sign-On (SSO)](https://support.pagerduty.com/main/docs/sso)
- [Security Hygiene for Current Cyber Threats](https://support.pagerduty.com/main/docs/security-hygiene-for-the-current-cyber-threat-landscape)
- [Okta SSO Configuration](https://saml-doc.okta.com/SAML_Docs/How-to-Configure-SAML-2.0-for-PagerDuty.html)

**API Documentation:**
- [PagerDuty API Reference](https://developer.pagerduty.com/api-reference)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, PCI DSS, FedRAMP (compliant offering available) — via [PagerDuty Security](https://www.pagerduty.com/security/)

**Security Incidents:**
- **August 2025:** Attackers exploited a vulnerability in Drift's OAuth integration with Salesforce (via Salesloft), potentially gaining unauthorized access to PagerDuty's Salesforce account. No PagerDuty credentials were exposed and no evidence of access to PagerDuty's core platform or internal systems. — [SecurityWeek Report](https://www.securityweek.com/pagerduty-warns-customers-data-breach/)
- **April 2024:** Vendor compromise at Sisense; PagerDuty reset credentials per CISA guidance as a precaution, but found no impact on PagerDuty or its customers. — [PagerDuty Advisory](https://support.pagerduty.com/main/docs/sisense-compromise)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, user management, and access controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
