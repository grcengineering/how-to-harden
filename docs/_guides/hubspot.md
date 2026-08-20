---
layout: guide
title: "HubSpot Hardening Guide"
vendor: "HubSpot"
slug: "hubspot"
tier: "2"
category: "Marketing"
description: "CRM security for private apps, OAuth scopes, and data export controls"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
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

### 1.1 Enforce SSO with MFA (Professional & Enterprise)

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML SSO with MFA for all HubSpot access. SSO is available on **Professional and Enterprise** editions.

#### Rationale
**Why This Matters:**
- Centralizes HubSpot authentication in your corporate IdP, enforcing MFA and conditional access on every login
- Local password logins bypass IdP controls and are prime targets for credential stuffing and phishing
- SAML SSO lets you deprovision departed employees in one place, eliminating standing access to CRM data
- Portals hold customer PII, sales pipelines, and marketing lists, so a single compromised login can expose all of it

**Attack Prevented:** Credential theft, phishing, MFA bypass, orphaned-account access

> **Changed default — two-factor authentication is already mandatory on paid editions.** HubSpot requires two-factor authentication on **password-based logins for Starter, Professional, and Enterprise accounts**; the account-level 2FA setting is therefore mostly relevant to accounts using only free tools. Two properties matter operationally: once 2FA is switched on for an account it **cannot be turned back off**, and users get a **24-hour grace period** to enrol before they are locked out. Supported methods are **passkeys, an authenticator app, and SMS**. Treat Step 3 below as a verification step on paid editions, not an enablement step. ([Set up two-factor authentication for your HubSpot login](https://knowledge.hubspot.com/account-security/set-up-two-factor-authentication-for-your-hubspot-login))

#### Prerequisites
- Super Admin permissions
- Professional or Enterprise edition for SAML SSO
- SAML 2.0 compatible IdP

#### ClickOps Implementation (Professional & Enterprise)

**Step 1: Configure SAML SSO**
1. Navigate to: **Settings → Security → Login** tab
2. In the **Single sign-on (SSO)** section, click **Set up single sign-on**
3. Configure:
   - **Identity provider:** Your IdP
   - **Sign-on URL:** IdP endpoint
   - **Certificate:** Upload IdP certificate
4. Complete the domain and IdP verification steps HubSpot presents before activating

**Step 2: Enforce SSO**
1. Enable **Require SSO** so users cannot fall back to a HubSpot password
2. Pair this with control [1.3](#13-restrict-allowed-login-methods) — requiring SSO without restricting login methods leaves other sign-in paths available

**Step 3: Verify Two-Factor Authentication**
1. Navigate to: **Settings → Security → Login** tab
2. Confirm two-factor authentication is enabled for the account (on Starter, Professional, and Enterprise it is already required for password logins — see the callout above)
3. Confirm enrolment coverage using Security Health ([5.2](#52-review-security-health))

> **Note (beta):** HubSpot has a beta permitting **multiple SSO configurations** in a single account. No control in this guide depends on it; if your account has the beta, verify that every configuration is equally enforced before assuming a single IdP covers all users. ([Set up single sign-on (SSO)](https://knowledge.hubspot.com/account-security/set-up-single-sign-on-sso))

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

### 1.3 Restrict Allowed Login Methods

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2, AC-3

#### Description
Restrict which authentication methods users may use to reach your HubSpot account, so that enabling SSO actually removes the alternative sign-in paths rather than merely adding one.

#### Rationale
**Why This Matters:**
- Requiring SSO does not, by itself, remove the other doors — email-and-password and social sign-in remain usable unless they are explicitly disallowed, which is the single most common way an "SSO-enforced" SaaS tenant stays bypassable
- Turning off email-and-password login is what forces every session through the IdP's MFA, conditional-access, and device checks
- Social login providers (Apple, Google, Microsoft) are separate identity sources with their own account-recovery paths, outside your IdP's control
- The setting is Super Admin-only, so it also concentrates control of the authentication perimeter in the smallest group of accounts

**Attack Prevented:** SSO bypass via local password, credential stuffing against password logins, unmanaged social-identity access, IdP conditional-access evasion

#### Prerequisites
- Super Admin permissions (only Super Admins can change allowed login methods)

#### ClickOps Implementation

**Step 1: Review Current Login Methods**
1. Navigate to: **Settings → Security → Login** tab
2. Find **Allowed login methods**
3. Review the available checkboxes: **Sign in with Apple**, **Sign in with Google**, **Sign in with Microsoft**, **Email and password**, and **Passkeys**

**Step 2: Disable Unwanted Methods**
1. Clear the checkbox for every method you do not intend to support
2. With SSO enforced, clearing **Email and password** is what closes the local-credential bypass
3. Save the configuration

**Step 3: Handle Exemptions Deliberately**
1. Use the exempt-users list only for genuine break-glass accounts (for example, an administrator who must retain access if the IdP is unavailable)
2. Document each exemption, its owner, and its review date — exempt accounts are, by design, the accounts your login-method policy does not protect
3. Allow roughly **15 minutes** for a change to take effect before testing

#### Validation & Testing
- Sign out and attempt to sign in using a disallowed method — it should be rejected
- Confirm the exempt-users list contains only accounts you can name and justify
- Re-check after ~15 minutes if a just-saved change appears not to have applied

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 6.4 |
| NIST 800-53 | IA-2, AC-3 |
| SOC 2 | CC6.1 |

**Source:** [Restrict which login methods users can use to access your account](https://knowledge.hubspot.com/account-security/restrict-which-login-methods-users-can-use-to-access-your-account)

---

### 1.4 Provision Users with SCIM

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-2, AC-2(1)

#### Description
Automate HubSpot user lifecycle from your identity provider using SCIM provisioning, so that joiners, movers, and leavers are reflected in the CRM without manual admin action.

#### Rationale
**Why This Matters:**
- Manual deprovisioning is the step that gets skipped — SCIM removes HubSpot access as a consequence of the IdP offboarding rather than as a separate task someone has to remember
- Automated provisioning shrinks the window in which a departed employee retains standing access to customer PII, pipeline data, and marketing lists
- Driving role assignment from IdP groups keeps permission grants reviewable in one system instead of drifting per-portal
- Domain verification, required before SCIM can be enabled, also establishes that the account genuinely controls the email domains it provisions

**Attack Prevented:** Orphaned-account access, delayed deprovisioning, unreviewed permission drift, offboarding gaps

#### Prerequisites
- SSO must be configured first — SCIM builds on the SSO integration
- **DNS TXT record** domain verification for the domains being provisioned
- Professional or Enterprise edition
- Okta as the identity provider (HubSpot documents the SCIM integration for Okta)

#### ClickOps Implementation

**Step 1: Satisfy the Prerequisites**
1. Configure SSO ([1.1](#11-enforce-sso-with-mfa-professional--enterprise))
2. Verify each email domain by publishing the **DNS TXT record** HubSpot provides
3. Confirm the account is on Professional or Enterprise

**Step 2: Enable SCIM in Okta**
1. Configure the HubSpot application in Okta for provisioning
2. Map the attributes HubSpot requires for user creation
3. Enable **Permission Set Management** if you want Okta group membership to drive HubSpot permission sets

**Step 3: Understand the Boundaries**
1. **Okta cannot assign users to HubSpot teams** — team membership remains a manual assignment inside HubSpot, so keep a review for it
2. Decide explicitly how deactivation in Okta should surface in HubSpot and confirm the behaviour on a test user before rollout

#### Validation & Testing
- Create a test user in Okta and confirm it appears in HubSpot with the expected permission set
- Deactivate the test user in Okta and confirm HubSpot access is removed
- Confirm team assignments separately — they are outside SCIM's scope

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.1, 5.3 |
| NIST 800-53 | AC-2, AC-2(1) |
| SOC 2 | CC6.2, CC6.3 |

**Source:** [Provision HubSpot users with SCIM through Okta](https://knowledge.hubspot.com/user-management/provision-hubspot-users-with-scim-through-okta)

---

## 2. Marketplace App Security

### 2.1 Implement App Approval Workflow

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7

#### Description
Control who can install marketplace apps by managing the App Marketplace user permissions, and require a documented review before any new app is connected.

#### Rationale
**Why This Matters:**
- The marketplace hosts 1,500+ apps of widely varying security maturity, and each install is a standing grant of CRM access rather than a one-time action
- Marketplace apps read customer PII, sales pipeline, and marketing data, so the install decision is a data-sharing decision and belongs with a reviewer, not with every individual user
- OAuth tokens issued to an app keep working after the app is uninstalled unless access is explicitly revoked, which makes an unreviewed install hard to fully undo later
- Restricting installation to a small, named group makes the connected-app inventory something you can actually keep accurate

**Attack Prevented:** Malicious or compromised marketplace app installation, supply-chain data exfiltration, persistent OAuth access, shadow-integration sprawl

> **Correction (2026-08):** Earlier versions of this guide instructed admins to set a **"Who can install apps"** toggle under Connected Apps. **No such toggle exists.** Install rights are governed by the per-user **App Marketplace access** permission, with **App Marketplace Uninstall access** as a separate permission. Configure this on the permission set, not on the integrations page. ([HubSpot user permissions guide](https://knowledge.hubspot.com/user-management/hubspot-user-permissions-guide))

#### ClickOps Implementation

**Step 1: Restrict App Marketplace Permissions**
1. Navigate to: **Settings → Users & Teams**
2. Edit the relevant permission set or user, and open the **Account** permissions
3. Grant **App Marketplace access** only to the users authorised to connect integrations
4. Grant **App Marketplace Uninstall access** separately and deliberately — the ability to remove an app is distinct from the ability to add one, and removing an app is itself a change to a working integration
5. Remove both permissions from general marketing and sales users

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
Control bulk data export using HubSpot's three export permissions, which support an approval workflow rather than a simple on/off switch.

#### Rationale
**Why This Matters:**
- Bulk export is the fastest path to exfiltrate an entire contact database in a single action, and it leaves the platform looking like ordinary use
- HubSpot separates the ability to export from the ability to export **without** approval, so most users can keep doing their jobs while every large pull still passes a human
- An approval workflow is stronger than a binary disable: it preserves the capability, creates a decision record, and puts a second person between a hijacked account and the customer database
- Combined with permission sets, this contains both insider misuse and account-takeover scraping

**Attack Prevented:** Bulk data exfiltration, insider data theft, account-takeover scraping, unreviewed mass export

> **Correction (2026-08):** The export controls are not a single **Export contacts** / **Export reports** pair. HubSpot provides three distinct permissions — **Export**, **Export without approval**, and **Approve exports** — which together implement an export-approval workflow. ([HubSpot user permissions guide](https://knowledge.hubspot.com/user-management/hubspot-user-permissions-guide))

#### ClickOps Implementation

**Step 1: Understand the Three Permissions**

| Permission | What it grants |
|------------|----------------|
| **Export** | The user may request an export; requests are subject to approval |
| **Export without approval** | The user may export directly, bypassing the approval step |
| **Approve exports** | The user may approve other users' export requests |

**Step 2: Assign the Permissions Deliberately**
1. Navigate to: **Settings → Users & Teams**
2. Open the permission set (or individual user) you want to change
3. Grant **Export** to users with a genuine business need to pull data
4. Grant **Export without approval** to as few accounts as possible — this is the permission that defeats the workflow, and it should be treated with the same scrutiny as Super Admin
5. Grant **Approve exports** to a named reviewer group, and keep it separate from the users who request exports so that no one can approve their own request

**Step 3: Monitor Exports**
1. Review security activity logs for export events ([5.1](#51-enable-audit-logging))
2. Alert on unusually large or off-hours exports, and on any change to the export permissions themselves

#### Validation & Testing
- Have a test user with **Export** but not **Export without approval** attempt an export and confirm it enters the approval queue
- Enumerate every account holding **Export without approval** and confirm each is justified
- Confirm no single account holds both **Export** and **Approve exports** unless that self-approval is an accepted, documented risk

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

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Settings → Security → Login** tab and review the account's login and security activity
2. Review:
   - Login activity
   - Security setting changes
   - User modifications

**Step 2: Export to SIEM**
1. Use HubSpot API to export audit events
2. Configure scheduled export

---

### 5.2 Review Security Health

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CA-7, AC-2(3)

#### Description
Use HubSpot's Security Health page as a standing review of account security posture — two-factor enrolment, dormant accounts, Super Admin count, partner access, and holders of critical permissions.

#### Rationale
**Why This Matters:**
- Security Health turns the questions an auditor asks — who is not enrolled in 2FA, who has not logged in for 90 days, how many Super Admins are there — into a page an admin can read in a minute, which is what makes the review actually happen on a cadence
- Dormant accounts are the ones nobody notices being used; surfacing 90-day-inactive users converts a silent risk into a work item
- Super Admin count and critical-permission holders drift upward over time as one-off grants are made and never revisited, and drift is only visible if something counts it
- Partner permissions grant access to an outside organisation, and that access outlives the engagement unless somebody reviews it

**Attack Prevented:** Dormant-account takeover, privilege creep, unrevoked partner access, unenrolled-MFA compromise

#### Prerequisites
- The **Security Center access** permission (Security Health is gated on it)

#### ClickOps Implementation

**Step 1: Open Security Health**
1. Navigate to: **Settings → Security → Permissions** tab
2. Click **Manage** to open Security Health

**Step 2: Work Each Section**
1. **Two-factor authentication** — follow up with every user who is not enrolled
2. **Inactive users** — review users who have not logged in for **90 days** and deactivate those who no longer need access
3. **Super Admins** — confirm each is still required; this is the count that should stay smallest
4. **Partner permissions** — confirm every partner with access is on a current engagement
5. **Critical permissions** — review who holds the permissions that can change security settings, export data, or manage users

**Step 3: Set a Cadence**
1. Schedule this review (monthly or quarterly) and record who performed it
2. Re-check after any offboarding wave or partner engagement ending

#### Validation & Testing
- Confirm each Security Health section either reports clean or has an owned, dated remediation item
- Confirm the reviewer holds **Security Center access** and that the permission itself is not broadly granted

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.1, 5.3, 6.5 |
| NIST 800-53 | AC-2(3), CA-7 |
| SOC 2 | CC6.1, CC6.2, CC6.3 |

**Source:** [Manage your account security using HubSpot's Security Health](https://knowledge.hubspot.com/account-security/manage-your-account-security-using-hubspost-security-health)

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
| MFA | ✅ | ✅ (required for password logins) | ✅ (required for password logins) | ✅ (required for password logins) |
| SSO (SAML) | ❌ | ❌ | ✅ | ✅ |
| SCIM provisioning (Okta) | ❌ | ❌ | ✅ | ✅ |
| Restrict allowed login methods | ✅ | ✅ | ✅ | ✅ |
| Permission Sets | Basic | Basic | ✅ | ✅ |
| Audit Logs | ❌ | ❌ | ✅ | ✅ |
| Data Retention | ❌ | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official HubSpot Documentation:**
- [Knowledge Base](https://knowledge.hubspot.com/)
- [Set Up Single Sign-On (SSO)](https://knowledge.hubspot.com/account-security/set-up-single-sign-on-sso)
- [Set Up Two-Factor Authentication for Your HubSpot Login](https://knowledge.hubspot.com/account-security/set-up-two-factor-authentication-for-your-hubspot-login)
- [Restrict Which Login Methods Users Can Use](https://knowledge.hubspot.com/account-security/restrict-which-login-methods-users-can-use-to-access-your-account)
- [Account Security and Passwords](https://knowledge.hubspot.com/account-security/account-security-and-passwords)
- [HubSpot User Permissions Guide](https://knowledge.hubspot.com/user-management/hubspot-user-permissions-guide)
- [Provision HubSpot Users with SCIM through Okta](https://knowledge.hubspot.com/user-management/provision-hubspot-users-with-scim-through-okta)
- [Manage Your Account Security (Security Health)](https://knowledge.hubspot.com/account-security/manage-your-account-security-using-hubspost-security-health)

**API & Developer Tools:**
- [HubSpot Developer Documentation](https://developers.hubspot.com/docs)
- [HubSpot API Reference](https://developers.hubspot.com/docs/api/overview)

**Compliance Frameworks:**
- HubSpot publishes its certification and audit-report status (SOC 2 Type II, SOC 3 and others) through its Trust Center and legal pages. Those pages are compliance attestations, not hardening documentation, and are deliberately not cited as sources in this guide — request the current reports directly from HubSpot and treat the certification scope stated in them as authoritative rather than any summary reproduced here.
- HubSpot infrastructure is hosted on AWS, whose own certifications are separate from HubSpot's and do not transfer to your configuration of the product.

**Security Incidents:**
- **Employee Account Compromise (Mar 2022):** A compromised employee account was used to export contact data from a small number of HubSpot accounts. Cryptocurrency companies including BlockFi, Swan, and NYDIG were targeted; customer names, emails, and phone numbers were exfiltrated.
- **Customer Account Targeting (Jun 2024):** Bad actors targeted a limited number of HubSpot customers, gaining unauthorized access to fewer than 30 customer portals. Incident was contained within five days.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | ai-drafted | Currency pass against knowledge.hubspot.com. Corrections: 2FA is already mandatory for password logins on Starter/Professional/Enterprise (changed-default callout in 1.1, cannot be disabled once on, 24-hour grace, passkeys/authenticator/SMS); SSO is Professional **and** Enterprise, not Enterprise-only (1.1 heading + edition table); the "Who can install apps" toggle in 2.1 does not exist — install rights are the per-user App Marketplace access / App Marketplace Uninstall access permissions; 4.2 rewritten around the real Export / Export without approval / Approve exports permissions and the export-approval workflow. New controls: 1.3 restrict allowed login methods, 1.4 SCIM provisioning through Okta, 5.2 Security Health standing review. Also: 2.1 Rationale converted from **Attack Scenario** to the parser-required **Attack Prevented** and its bullets expanded; navigation paths corrected to Settings → Security → Login / Permissions tabs; three empty section bodies removed; Trust Center and legal/security marketing links dropped from Appendix B per the hardening-source standard. Tier 2 survey found no CIS Benchmark, DISA STIG, or CISA SCuBA baseline for HubSpot; Tier 3/4 research not surveyed this pass. Section 3.2 rate-limit table left unchanged — HubSpot's developer docs were login-walled, so those figures were neither confirmed nor refuted | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | ai-drafted | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | ai-drafted | Initial HubSpot hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
