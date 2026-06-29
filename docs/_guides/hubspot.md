---
layout: guide
title: "HubSpot Hardening Guide"
vendor: "HubSpot"
slug: "hubspot"
tier: "2"
category: "Marketing"
description: "CRM security for private apps, OAuth scopes, and data export controls"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---


## Overview

HubSpot serves **247,939+ paying customers** with **38% global marketing automation market share**. The App Marketplace hosts **1,500+ integrations** accessing customer PII, sales pipeline data, and marketing campaign information. OAuth grants from marketplace apps create broad CRM access that persists even after app uninstallation without explicit revocation.

### Intended Audience
- Security engineers hardening CRM systems
- Marketing operations administrators
- GRC professionals assessing CRM compliance
- Third-party risk managers evaluating marketing integrations

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers HubSpot security configurations including authentication, marketplace app governance, API security, and data protection controls.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Marketplace App Security](#2-marketplace-app-security)
3. [API & Integration Security](#3-api--integration-security)
4. [Data Security](#4-data-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML SSO with MFA for all HubSpot access.

#### Rationale
**Why This Matters:**
- Centralizes HubSpot authentication in your corporate IdP, enforcing MFA and conditional access on every login
- Local password logins bypass IdP controls and are prime targets for credential stuffing and phishing
- SAML SSO lets you deprovision departed employees in one place, eliminating standing access to CRM data
- Portals hold customer PII, sales pipelines, and marketing lists, so a single compromised login can expose all of it

**Attack Prevented:** Credential theft, phishing, MFA bypass, orphaned-account access

#### ClickOps Implementation (Enterprise)

**Step 1: Configure SAML SSO**
1. Navigate to: **Settings → Account Management → Security → Single Sign-On**
2. Click **Set up single sign-on**
3. Configure:
   - **Identity provider:** Your IdP
   - **Sign-on URL:** IdP endpoint
   - **Certificate:** Upload IdP certificate

**Step 2: Enforce SSO**
1. Enable: **Require SSO**
2. Configure: **Session timeout:** 8 hours

**Step 3: Configure Two-Factor Authentication**
1. Navigate to: **Settings → Account Management → Security → Two-factor authentication**
2. Enable: **Require 2FA for all users**

---

### 1.2 Implement User Permission Sets

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure permission sets limiting access to CRM data and features.

#### Rationale
**Why This Matters:**
- Permission sets enforce least privilege so each user only reaches the CRM data and features their role requires
- Limiting Super Admin to 2-3 accounts shrinks the blast radius if any privileged login is compromised
- Scoping contacts and deals to assigned records prevents lateral browsing of the entire customer database
- Reduces insider-misuse risk and limits what a hijacked account can view, export, or alter

**Attack Prevented:** Privilege escalation, insider data theft, lateral access, over-broad admin compromise

#### ClickOps Implementation

**Step 1: Create Role-Based Permission Sets**
1. Navigate to: **Settings → Users & Teams → Permission Sets**
2. Create sets:

**Marketing User:**
- Email: Full access
- Forms: Full access
- Contacts: View assigned only
- Reports: View only

**Sales User:**
- Deals: Full access (assigned)
- Contacts: View/Edit assigned
- Emails: Send only
- Reports: View assigned

**Super Admin:**
- Full access (limit to 2-3 users)
- Required for security settings

**Step 2: Assign Permission Sets**
1. Navigate to: **Users → Select user → Permissions**
2. Assign appropriate permission set
3. Configure team-based restrictions

---

## 2. Marketplace App Security

### 2.1 Implement App Approval Workflow

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7

#### Description
Require approval for marketplace app installations.

#### Rationale
**Why This Matters:**
- 1,500+ marketplace apps with varying security
- Apps access customer PII and sales data
- OAuth tokens persist after app uninstall

**Attack Scenario:** Compromised marketplace app extracts customer contact lists for targeted phishing; OAuth tokens enable persistent API access.

#### ClickOps Implementation

**Step 1: Configure App Installation Policy**
1. Navigate to: **Settings → Integrations → Connected Apps**
2. Configure: **Who can install apps:** Super Admins only

**Step 2: Review Existing Apps**
1. Navigate to: **Settings → Integrations → Connected Apps**
2. For each app, review:
   - Permissions/scopes requested
   - Installation date
   - Active users
3. Remove unused apps

**Step 3: Create App Evaluation Checklist**
- Review OAuth scopes requested
- Check vendor security certifications
- Evaluate data access requirements
- Document business justification
- Verify app is from verified publisher

---

### 2.2 Audit OAuth Grants

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5(13)

#### Description
Regularly audit OAuth grants to marketplace apps.

#### Rationale
**Why This Matters:**
- OAuth and marketplace app tokens keep working after the app is uninstalled unless access is explicitly revoked
- Periodic review surfaces stale, unused, or over-scoped grants that quietly accumulate broad CRM access
- A forgotten grant is an invisible backdoor an attacker can ride to exfiltrate contacts and pipeline data
- User-level app authorizations bypass admin oversight and need their own review cadence

**Attack Prevented:** Persistent token access, OAuth abuse, supply-chain data exfiltration, orphaned grants

#### ClickOps Implementation

**Step 1: Review Connected Apps**
1. Navigate to: **Settings → Integrations → Connected Apps**
2. Document all connected apps and their scopes

**Step 2: Revoke Unnecessary Grants**
1. For unused apps: **Uninstall** and **Revoke access**
2. Note: Uninstalling alone doesn't revoke OAuth tokens

**Step 3: User-Level OAuth Review**
1. Have users review their authorized apps:
   - **Profile → Integrations → Connected Apps**
2. Revoke personal app authorizations

---

## 3. API & Integration Security

### 3.1 Secure Private App Tokens

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Manage private app access tokens with appropriate restrictions.

#### Rationale
**Why This Matters:**
- Private app tokens are long-lived bearer credentials that grant direct API access to CRM data with no MFA prompt
- Scoping each app to the minimum required APIs limits what a leaked token can reach
- Storing tokens in a secrets manager and rotating them keeps them out of source code and shortens exposure windows
- A token committed to a repository or leaked in logs gives an attacker silent, ongoing access to customer records

**Attack Prevented:** Token leakage, hardcoded-secret exposure, over-scoped API access, credential reuse

#### ClickOps Implementation

**Step 1: Create Scoped Private Apps**
1. Navigate to: **Settings → Integrations → Private Apps**
2. Create app with minimum scopes:
   - Select only required APIs
   - Document purpose
   - Set meaningful name

**Step 2: Token Security**
- Store tokens in secrets manager
- Never commit tokens to code
- Rotate tokens quarterly

**Step 3: Audit Existing Tokens**

{% include pack-code.html vendor="hubspot" section="3.1" %}

---

### 3.2 Configure API Rate Limiting Awareness

**Profile Level:** L1 (Crawl)

#### Description
Design integrations with HubSpot's rate limits in mind.

#### Rationale
**Why This Matters:**
- Designing within HubSpot's published limits prevents integrations from being throttled or failing mid-sync
- Monitoring request volume surfaces runaway loops, misconfigured jobs, or abuse before they disrupt operations
- A sudden spike toward the burst ceiling can signal a compromised token being used for bulk data extraction
- Graceful backoff keeps critical sync pipelines reliable instead of silently dropping records

**Attack Prevented:** Denial of service, integration outages, bulk-scraping abuse, undetected exfiltration spikes

#### Rate Limits

| App Type | Rate Limit |
|----------|------------|
| Private Apps | 100 requests / 10 seconds |
| OAuth Apps | 100 requests / 10 seconds per portal |
| Burst | 150 requests / 10 seconds |

#### Monitoring

{% include pack-code.html vendor="hubspot" section="3.2" %}

---

## 4. Data Security

### 4.1 Configure GDPR & Privacy Settings

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SI-12

#### Description
Enable GDPR compliance features for data privacy.

#### Rationale
**Why This Matters:**
- Requiring a legal basis and tracking consent history enforces lawful processing of contact data at the source
- Data retention policies automatically purge records past their lifecycle, shrinking the volume exposed in any breach
- Consent records provide the audit trail regulators and customers expect for subject-access and deletion requests
- Reduces regulatory liability and limits how much stale PII an attacker could harvest

**Attack Prevented:** Regulatory non-compliance, excessive PII retention, consent violations, breach blast-radius expansion

#### ClickOps Implementation

**Step 1: Enable GDPR Tools**
1. Navigate to: **Settings → Privacy & Consent → Data Privacy**
2. Enable:
   - **Require legal basis for contacts:** Yes
   - **Track consent history:** Yes

**Step 2: Configure Data Retention**
1. Navigate to: **Settings → Privacy & Consent → Data Retention**
2. Configure retention policies:
   - Contact retention period
   - Activity log retention
   - Deletion workflows

---

### 4.2 Export and Data Access Controls

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-3

#### Description
Control bulk data export capabilities.

#### Rationale
**Why This Matters:**
- Bulk export is the fastest path to exfiltrate an entire contact database in a single action
- Disabling export for non-admin users removes that capability from the accounts most likely to be phished
- Monitoring and alerting on export events gives early warning of mass data theft in progress
- Combined with permission sets, this contains both insider misuse and hijacked-account scraping

**Attack Prevented:** Bulk data exfiltration, insider data theft, account-takeover scraping, undetected mass export

#### ClickOps Implementation

**Step 1: Restrict Export Permissions**
1. Navigate to: **Permission Sets**
2. For non-admin users:
   - Disable: **Export contacts**
   - Disable: **Export reports**

**Step 2: Monitor Exports**
1. Review activity logs for export events
2. Alert on bulk exports

---

## 5. Monitoring & Detection

### 5.1 Enable Audit Logging

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Monitor HubSpot activity through audit logs.

#### Rationale
**Why This Matters:**
- Security activity logs record logins, permission changes, and user modifications needed to detect and investigate abuse
- Exporting events to a SIEM enables correlation, alerting, and retention beyond HubSpot's native window
- Without centralized logs, account compromise and data theft can proceed undetected for long periods
- Audit trails are required evidence for incident response and compliance attestations

**Attack Prevented:** Undetected account compromise, delayed breach detection, audit-trail gaps, insider abuse

#### ClickOps Implementation (Enterprise)

**Step 1: Access Audit Logs**
1. Navigate to: **Settings → Account Management → Security → Security Activity**
2. Review:
   - Login activity
   - Security setting changes
   - User modifications

**Step 2: Export to SIEM**
1. Use HubSpot API to export audit events
2. Configure scheduled export

#### Detection Queries

{% include pack-code.html vendor="hubspot" section="5.1" %}

---

## 6. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | HubSpot Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO enforcement | 1.1 |
| CC6.2 | Permission sets | 1.2 |
| CC6.7 | Data privacy | 4.1 |

---

## Appendix A: Edition Compatibility

| Control | Free | Starter | Professional | Enterprise |
|---------|------|---------|--------------|------------|
| MFA | ✅ | ✅ | ✅ | ✅ |
| SSO (SAML) | ❌ | ❌ | ❌ | ✅ |
| Permission Sets | Basic | Basic | ✅ | ✅ |
| Audit Logs | ❌ | ❌ | ✅ | ✅ |
| Data Retention | ❌ | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official HubSpot Documentation:**
- [Trust Center](https://trust.hubspot.com/)
- [HubSpot Security Program](https://legal.hubspot.com/security)
- [Knowledge Base](https://knowledge.hubspot.com/)
- [Set Up Single Sign-On (SSO)](https://knowledge.hubspot.com/account-security/set-up-single-sign-on-sso)
- [Account Security and Passwords](https://knowledge.hubspot.com/account-security/account-security-and-passwords)
- [Manage Your Account Security (Security Health)](https://knowledge.hubspot.com/account-security/manage-your-account-security-using-hubspost-security-health)

**API & Developer Tools:**
- [HubSpot Developer Documentation](https://developers.hubspot.com/docs)
- [HubSpot API Reference](https://developers.hubspot.com/docs/api/overview)

**Compliance Frameworks:**
- SOC 2 Type II, SOC 3 -- via [Trust Center](https://trust.hubspot.com/)
- HubSpot infrastructure hosted on AWS (which maintains ISO 27001, SOC 2 Type II)

**Security Incidents:**
- **Employee Account Compromise (Mar 2022):** A compromised employee account was used to export contact data from a small number of HubSpot accounts. Cryptocurrency companies including BlockFi, Swan, and NYDIG were targeted; customer names, emails, and phone numbers were exfiltrated.
- **Customer Account Targeting (Jun 2024):** Bad actors targeted a limited number of HubSpot customers, gaining unauthorized access to fewer than 30 customer portals. Incident was contained within five days.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial HubSpot hardening guide | Claude Code (Opus 4.5) |
