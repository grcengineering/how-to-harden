---
layout: guide
title: "Smartsheet Hardening Guide"
vendor: "Smartsheet"
slug: "smartsheet"
tier: "5"
category: "Productivity"
description: "Work management security for sharing defaults, connector controls, and activity logging"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-08-08"
---


## Overview

Smartsheet is a collaborative work management platform for projects, workflows, and data collection. REST API, OAuth apps, and connectors access project data and business processes. Compromised access exposes project timelines, resource allocation, and potentially sensitive form submissions.

### Intended Audience
- Security engineers managing work management platforms
- Smartsheet administrators
- GRC professionals assessing project management security
- Third-party risk managers evaluating workflow integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers Smartsheet security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Sharing & Permissions](#2-sharing--permissions)
3. [Integration Security](#3-integration-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML single sign-on with multi-factor authentication for all Smartsheet access so every login is brokered through your corporate identity provider.

#### Rationale
**Why This Matters:**
- Routing every Smartsheet login through your IdP enforces MFA, conditional access, and central session policy on each authentication attempt
- Native email-and-password logins bypass IdP controls and are prime targets for credential stuffing and phishing
- SSO with automated provisioning deprovisions departed users centrally, eliminating orphaned accounts that retain access to project data
- Smartsheet workspaces hold project plans, resource and budget data, and form submissions, so a single compromised login can expose all of it

**Attack Prevented:** Credential theft, phishing, MFA bypass, password reuse, orphaned-account access

#### ClickOps Implementation

**Step 1: Configure SAML SSO (Enterprise)**
1. Navigate to: **Smartsheet → Account settings → Admin Center**, then the SAML configuration under **Security & Controls**
2. Configure SAML IdP
3. Enable the requirement that users authenticate via SAML

> **Path not re-verified (2026-08-08):** the SAML configuration path above was not confirmed against a current Smartsheet article in this pass. Smartsheet has reorganized Admin Center navigation — verify the live path in your own Admin Center before following it literally.

**Step 2: Enable MFA**
1. Configure MFA through IdP
2. Or enable Smartsheet MFA
3. Require for all users

**Step 3: Require Work Accounts with SSO for External Collaborators (Enterprise)**
1. Navigate to: **Admin Center** → **Settings** → **Secure External Access**
2. Enable **Require work accounts with single sign-on (SSO)**
3. This forces external collaborators to authenticate with a corporate identity — Microsoft Entra ID, Google work accounts, or SAML 2.0 — before they can open content shared with them
4. The policy applies to users outside your validated domains and users not on the exempt list; Smartsheet does not publish a default state, so read the current toggle in your own tenant ([Require work accounts with SSO](https://help.smartsheet.com/articles/2483524-admin-center-configure-require-work-accounts-sso))

---

### 1.2 User Types and Roles

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Define Smartsheet user types and group-based roles so each account holds only the administrative and licensing privileges its job actually requires.

#### Rationale
**Why This Matters:**
- Least-privilege role assignment limits what a compromised or misused account can reach and change
- Reserving System Admin for a small, deliberate set of accounts shrinks the blast radius of an admin takeover
- Group-based permissions make access reviews and offboarding consistent and auditable instead of ad hoc
- Over-provisioned admin or licensed accounts let an attacker alter sharing, integrations, and security settings across the whole organization

**Attack Prevented:** Privilege escalation, lateral movement, insider misuse, excessive standing access

#### ClickOps Implementation

**Step 1: Define User Types**

| Type | Permissions |
|------|-------------|
| System Admin | Full admin access |
| Group Admin | Manage specific groups |
| Licensed User | Create and share |
| Resource Viewer | View resources only |

**Step 2: Configure Groups**
1. Navigate to: **Admin Center → User Management → Groups**
2. Create department groups
3. Assign permissions by group

---

### 1.3 Require MFA for External Collaborators

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1), IA-8

#### Description
Turn on the Admin Center **Require MFA** policy so external collaborators must complete multi-factor authentication before opening content shared with them, and maintain the exempt list deliberately rather than by accident.

#### Rationale
**Why This Matters:**
- Internal MFA enforced through your IdP does nothing for the external collaborators your teams share sheets with — they authenticate on their own terms unless you require otherwise
- Shared sheets, dashboards, and workspaces routinely carry budgets, schedules, and personal data, so an external collaborator's compromised account is a direct path into your project data
- Every entry on the exempt list is a documented decision to accept single-factor access for that domain or address; an unmaintained exempt list quietly becomes the policy

**Attack Prevented:** External-account takeover, credential stuffing against collaborators, unauthorized access to shared content, silent policy erosion via stale exemptions

#### Prerequisites
- Smartsheet Enterprise plan
- System Admin permissions

#### ClickOps Implementation

**Step 1: Enable Require MFA**
1. Navigate to: **Admin Center** → **Settings** → **Secure External Access**
2. Enable the **Require MFA** policy for external collaborators
3. Smartsheet supports MFA via SAML, Microsoft or Google work accounts, and authenticator-app backup. Smartsheet does not publish the default state of this policy — read the current value in your tenant ([Configure Require MFA](https://help.smartsheet.com/articles/2483523-admin-center-configure-require-mfa))

**Step 2: Curate the Exempt List**
1. Navigate to: **Admin Center** → **Menu** → **Settings** → **Secure External Access** → **Advanced Settings**
2. Review the domain and email exempt lists, which bypass both the **Require work accounts with SSO** and **Require MFA** policies
3. Note that all verified domains on the plan are **automatically exempted** from both policies, since those represent internal users — confirm the verified-domain list actually matches your organization
4. Use the Created By/On and Modified By/On columns and the notes field to keep each exemption attributable ([Exempt list for external collaborators](https://help.smartsheet.com/articles/2483521-admin-center-create-exempt-list-external-collaborators))
5. Allow up to three minutes for exempt-list changes to take effect

---

### 1.4 Configure User Session Expiration

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-11, AC-12

#### Description
Shorten the plan-wide Smartsheet session expiration from its defaults so idle web and desktop sessions re-authenticate instead of staying valid for the better part of a working day or longer.

#### Rationale
**Why This Matters:**
- Smartsheet's documented defaults — **19 hours** for web and **72 hours** for desktop — mean an authenticated session realistically survives overnight and across a weekend
- A live session is a credential that sits behind your SSO and MFA controls; an attacker with a stolen session cookie or an unattended laptop never has to defeat either
- Bounding session lifetime is one of the few controls that limits damage from infostealer malware, which harvests session tokens rather than passwords

**Attack Prevented:** Session hijacking, stolen session-token reuse, unattended-device access

#### Prerequisites
- Smartsheet Enterprise plan
- System Admin permissions

#### ClickOps Implementation

**Step 1: Set the Expiration**
1. Open **Admin Center** and configure **User session expiration**
2. The setting accepts a value from **15 minutes to 30 hours** and applies **plan-wide** — it cannot be scoped to a subset of users
3. Choose the shortest interval your teams tolerate; anything near the 19-hour default is effectively an all-day session ([Configure user session expiration](https://help.smartsheet.com/articles/2483618-admin-center-configure-user-session-expiration))

**Step 2: Understand the Web/Desktop Interaction**
1. Defaults are **19 hours (web)** and **72 hours (desktop)**
2. A web timeout set below 19 hours **overrides** the desktop timeout — so lowering the web value is what actually shortens desktop sessions too
3. Verify by leaving a desktop session idle past the configured interval and confirming re-authentication

---

### 1.5 Automate the User Lifecycle from Your IdP

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-2, AC-2(1)

#### Description
Use **IdP-Managed Access** and **User Auto-Provisioning** so Smartsheet group membership and account creation are driven by your identity provider and validated domains, rather than by manual invitations an admin has to remember to revoke.

#### Rationale
**Why This Matters:**
- Role changes that only happen in the IdP leave Smartsheet permissions frozen at whatever the person used to need — IdP-managed access keeps group membership in sync automatically
- Manual invitation flows produce accounts nobody owns; auto-provisioning ties account existence to a validated corporate domain instead
- Both features concentrate the lifecycle decision in one system, which is what makes offboarding verifiable rather than hopeful

**Attack Prevented:** Permission drift after role changes, orphaned accounts, unmanaged account sprawl, incomplete offboarding

#### Prerequisites
- Smartsheet Enterprise plan
- System Admin permissions
- Domain-level SAML SSO configured (for IdP-Managed Access)
- Validated and activated domains, including the required public DNS records (for User Auto-Provisioning)

#### ClickOps Implementation

**Step 1: Enable IdP-Managed Access**
1. Navigate to: **Admin Center** → **Settings** → **IdP Managed Access** (also reachable from the **Security** card on the Admin Center home)
2. Enable the toggle — it is deactivated by default and must be turned on deliberately
3. On activation Smartsheet generates the IdP-managed access sheet and shares it to all current System Admins; treat that sheet as a sensitive access-control artifact
4. Sync user roles between your IdP (Okta, Entra ID, or another provider) and Smartsheet groups ([Configure IdP-managed access](https://help.smartsheet.com/articles/2483300-admin-center-configure-idp-managed-access))

**Step 2: Enable User Auto-Provisioning**
1. Navigate to: **Admin Center** → **Menu** → **Settings** → **User Auto-Provisioning**
2. Validate and activate your domains on the Domain Management page first — completing UAP requires adding DKIM, CNAME, and DMARC records to your public DNS
3. Understand the behavior before enabling: auto-provisioned users receive **no email invitation or notification**, and may be prompted for a password at first login even when email-and-password sign-in is disabled
4. Note that email-based TOTP authentication is **incompatible** with UAP — plan your MFA method accordingly ([User auto-provisioning](https://help.smartsheet.com/articles/2072731-user-auto-provisioning-enterprise-only))

---

## 2. Sharing & Permissions

### 2.1 Configure Sharing Defaults

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-21

#### Description
Control sheet and workspace sharing.

#### Rationale
**Attack Scenario:** Public links to project sheets expose sensitive timelines; form submissions accessible to unauthorized users.

**Why This Matters:**
- Restrictive default sharing prevents sheets and workspaces from being exposed beyond their intended audience by accident
- Published items and public links bypass account-level access controls and are reachable by anyone who holds the URL
- Workspace-scoped sharing defaults contain external collaboration to the teams that need it instead of the entire organization
- Project sheets and form responses often hold schedules, budgets, and personal data that should never be world-readable

**Attack Prevented:** Data exposure via public links, unauthorized external sharing, accidental data leakage, oversharing

#### ClickOps Implementation

**Step 1: Configure Publishing Controls (Business or Enterprise)**
1. Open **Admin Center** and configure **Publishing controls**
2. Publishing is governed **per item type** — set each independently for sheets, reports, dashboards, and calendars (including iCal and the Calendar App)
3. For each enabled item type, set visibility to **anyone with the link** or **only people in your organization**. "Anyone" means anonymous internet access with no account required
4. Disable publishing entirely for item types your teams have no business publishing ([Configure publishing controls](https://help.smartsheet.com/articles/2483487-admin-center-configure-publishing-controls))

**Step 2: Enable the Safe Sharing List (Enterprise)**
1. Navigate to: **Account settings** → **Security**
2. Enable and populate the **safe sharing list** with the domains and email addresses your teams are permitted to share with
3. **This control is disabled by default** — until you enable it, sharing is unrestricted by domain
4. Validated company domains are added to the list automatically; everything else is an explicit decision ([Configure safe sharing](https://help.smartsheet.com/articles/855284-configure-safe-sharing))

**Step 3: Workspace Controls**
1. Create workspaces per team
2. Set workspace sharing defaults
3. Restrict external sharing

---

### 2.2 Form Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-21

#### Description
Set the plan-wide form security floor in Admin Center so every Smartsheet form — existing and future — requires at least the level of authentication your policy demands, regardless of what an individual form builder would have chosen.

#### Rationale
**Why This Matters:**
- Forms often collect sensitive intake data such as requests, approvals, contact details, and internal reporting that must not be visible to unauthorized users
- A plan-wide floor is what makes form security a policy rather than a per-form habit — individual builders cannot weaken it below the floor from the form builder
- Anonymous "anyone with the link" forms are an easy path for harvesting business or personal data at scale, and are the default shape of most forms unless the floor forbids it
- Setting the floor once covers forms you have not built yet, which is where per-form review always fails

**Attack Prevented:** Unauthorized data access, anonymous data harvesting, information disclosure, oversharing of submissions

#### Prerequisites
- Smartsheet Business or Enterprise plan
- System Admin permissions

#### ClickOps Implementation

**Step 1: Set the Plan-Wide Form Security Floor**
1. Open **Admin Center** and configure the form security setting
2. Choose one of the three documented options:

   | Option | Who can submit |
   |--------|----------------|
   | **Anyone with the link** | Anyone on the internet, no authentication |
   | **Only people with a Smartsheet login** | Any authenticated Smartsheet user |
   | **Only people in your account** | Users permitted by the **Safe Sharing List** (see 2.1) |

3. The setting is a **floor**: it applies plan-wide and cannot be relaxed from within the form builder ([Apply security settings to forms](https://help.smartsheet.com/articles/2483290-apply-security-settings-forms))
4. Pair the third option with a populated safe sharing list — otherwise it constrains less than it appears to

**Step 2: Review Existing Forms**
1. Inventory forms that collect personal or regulated data and confirm none rely on anonymous submission where the floor now forbids it
2. Confirm submission notifications go to the team that owns the process

> **Not documented:** Smartsheet does not document a CAPTCHA setting or an attachment-type restriction for forms. Do not plan controls around either — treat automated-submission abuse as a monitoring problem, not a configuration one.

---

### 2.3 Enforce the Data Egress Policy

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-4, SC-7(10)

#### Description
Enable the Smartsheet **data egress policy** to block the bulk export paths — Save as new, Save as template, Send as attachment, Publish, Print, and Export — across sheets, reports, dashboards, mobile, and the Public APIs.

#### Rationale
**Why This Matters:**
- Sharing controls govern who can open data in place; egress controls govern whether that person can take a copy out, which is the step that actually produces a breach
- A departing employee or a compromised account with legitimate read access can export an entire workspace in minutes unless export itself is blocked
- Covering mobile and the Public APIs matters more than the UI paths — API export is the quiet, scriptable, high-volume route

**Attack Prevented:** Bulk data exfiltration, insider data theft on departure, unauthorized copies outside the platform, API-driven mass export

#### Prerequisites
- Smartsheet Enterprise plan, **or** Advanced Work Management
- Governance Controls access requires **Smartsheet Advanced Platinum**, or **Advanced Work Management plus Safeguard**
- System Admin permissions

#### ClickOps Implementation

**Step 1: Enable the Policy**
1. Open **Admin Center** → **Governance Controls** and configure the **Data egress policy**
2. The policy blocks **Save as new**, **Save as template**, **Send as attachment**, **Publish**, **Print**, and **Export** across sheets, reports, and dashboards, and applies on mobile and through the **Public APIs** ([Data egress policy](https://help.smartsheet.com/articles/2482620-data-egress-policy))

**Step 2: Understand What It Does Not Cover**
1. The data egress policy **does not restrict sharing** — a user blocked from exporting can still share an item with someone else
2. Pair it with the safe sharing list (2.1) and publishing controls (2.1), or you have closed the export door while leaving the sharing door open
3. Validate by attempting an export as a non-admin user and confirming it is blocked in both the UI and via the API

---

### 2.4 Configure the Data Retention Policy

**Profile Level:** L2 (Walk)
**NIST 800-53:** SI-12, AU-11

#### Description
Configure the Smartsheet **data retention policy** so sheets and attachments are identified and disposed of on a defined schedule rather than accumulating indefinitely across workspaces.

#### Rationale
**Why This Matters:**
- Data you no longer hold cannot be exfiltrated — bounded retention is the only control that shrinks the target itself
- Smartsheet workspaces accumulate years of project sheets, attachments, and form responses that nobody has a reason to keep but nobody has a process to remove
- A defined, automated retention policy is what turns "we delete old data" into a claim you can evidence during an audit or a data-subject request

**Attack Prevented:** Excessive data exposure on breach, indefinite retention of personal data, regulatory non-compliance, insider access to stale project data

#### Prerequisites
- Advanced Work Management
- Governance Controls access requires **Smartsheet Advanced Platinum**, or **Advanced Work Management plus Safeguard**
- System Admin permissions

#### ClickOps Implementation

**Step 1: Configure the Policy**
1. Navigate to: **Admin Center** → **Menu icon** → **Governance Controls** → **Data Retention Policy** → **Configure**
2. Define which sheets the policy targets using **Created** and **Last modified** date conditions
3. Set how often the policy runs, how far in advance owners are notified, and which groups are included ([Configure data retention](https://help.smartsheet.com/articles/2482386-configure-data-retention))

**Step 2: Operate It**
1. The policy applies to **sheets and attachments**, can be applied retroactively, and runs automatically once activated — identifying non-compliant data and notifying owners
2. Smartsheet does not publish default values; every condition is a deliberate configuration decision
3. Run it in a low-impact configuration first and review the notification volume before widening scope

---

### 2.5 Manage AI Capabilities

**Profile Level:** L2 (Walk)
**NIST 800-53:** CM-7, AC-3

#### Description
Use **AI Management** in Admin Center to turn off the Smartsheet AI capabilities your organization has not approved, so sheet contents are not fed into AI features ahead of your data-handling review.

#### Rationale
**Why This Matters:**
- AI features operate on the contents of sheets that may hold budgets, personal data, and regulated project information your AI-use policy has not yet cleared for model processing
- Changes take effect immediately and plan-wide, so this is a real switch with real blast radius in both directions — enabling it is not a pilot
- Disabling capabilities you do not use is the cheapest surface reduction available, and it costs nothing to reverse once the review is done

**Attack Prevented:** Unapproved data flow into AI processing, unreviewed feature exposure, policy bypass via new AI capabilities

#### Prerequisites
- Smartsheet Pro, Business, or Enterprise plan
- System Admin permissions

#### ClickOps Implementation

**Step 1: Open AI Management**
1. Navigate to: **Account settings** → **Security** → **AI Management**
2. Review the available toggles: **AI charts**, **Smart Assist**, **AI dashboard builder**, and **Smart Columns** ([Manage AI capabilities](https://help.smartsheet.com/articles/2483723-manage-ai-capabilities-admin-center))

**Step 2: Set and Re-review**
1. Disable the capabilities your AI-use policy has not approved
2. Changes are **immediate and plan-wide** — communicate before flipping toggles that teams are actively using
3. Re-review after Smartsheet releases, since new AI capabilities appear in this panel over time

---

## 3. Integration Security

### 3.1 Connector Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7

#### Description
Review connected apps and connectors in the Admin Center, remove unused ones, and audit personal API access tokens, revoking any that are no longer needed.

#### Rationale
**Why This Matters:**
- Every connector and API token is a standing, often long-lived credential that can read or modify project data outside the SSO and MFA path
- Unused or forgotten integrations expand the attack surface and are rarely monitored, making them ideal footholds for attackers
- Auditing and revoking stale tokens enforces least privilege and limits damage if a token is leaked or a third party is breached
- A single over-scoped connector compromise can exfiltrate or alter data across many sheets and workspaces

**Attack Prevented:** Token abuse, third-party and supply-chain compromise, data exfiltration, stale credential exploitation

#### ClickOps Implementation

**Step 1: Review Connectors**
1. Navigate to: **Admin Center → Integrations**
2. Review all connected apps
3. Remove unused connectors

**Step 2: API Access**
1. Navigate to: **Personal Settings → API Access**
2. Audit access tokens
3. Revoke unused tokens

**Step 3: Set an Access Token Expiration**
1. Configure the plan-wide **access token expiration time** in Admin Center
2. **This is the highest-value item in this control:** by default, a Smartsheet API token created without an expiration **remains active indefinitely** unless a person manually revokes it — a permanent, MFA-free credential to project data
3. The expiration is configurable from **minutes to years** and applies **uniformly plan-wide**; it cannot be varied per user or per integration ([Configure access token expiration time](https://help.smartsheet.com/articles/2483100-configure-access-token-expiration-time))
4. Set the shortest expiry your integrations can rotate against, and build rotation into the integration rather than choosing a long expiry to avoid it

---

### 3.2 Premium App Security

**Profile Level:** L2 (Walk)
**NIST 800-53:** CM-7

#### Description
Control which Smartsheet premium apps (such as Dynamic View, Control Center, and Data Shuttle) are enabled and configure their access permissions to match genuine business need.

#### Rationale
**Why This Matters:**
- Premium apps extend data access and data-movement capabilities, so each enabled app widens what an attacker or misconfiguration can reach
- Enabling apps only where there is a clear business need keeps the platform's functionality and data-flow surface minimal
- Scoped access permissions prevent premium apps from exposing or moving data beyond the teams authorized to use them
- Apps such as Data Shuttle move data in and out of Smartsheet, so unmanaged enablement can create unmonitored data egress paths

**Attack Prevented:** Unauthorized data movement, data exfiltration, excessive feature exposure, misconfiguration abuse

#### ClickOps Implementation

**Step 1: Control Premium Apps**
1. Navigate to: **Admin Center → Premium Apps**
2. Enable/disable by app
3. Configure access permissions

---

## 4. Monitoring & Detection

### 4.1 Activity Log (Enterprise)

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Enable and review the Enterprise Activity Log and export its events to your SIEM so administrative and user actions are recorded and monitored.

#### Rationale
**Why This Matters:**
- Comprehensive activity logging is what makes account compromise, data exfiltration, and insider misuse detectable rather than silent
- Exporting events to a SIEM enables correlation, alerting, and retention beyond the platform's native console
- An audit trail of sharing changes, logins, and admin actions is essential for incident investigation and forensics
- Without centralized logging, attacker actions and policy changes go unnoticed until after the damage is done

**Attack Prevented:** Undetected compromise, insider misuse, delayed incident response, audit gaps

#### ClickOps Implementation

**Step 1: Access Activity Log**
1. Navigate to: **Admin Center → Security & Controls → Activity Log**
2. Review user activities
3. Export for SIEM integration

> **Path not confirmed (2026-08-08):** this Activity Log path was not verified against a current Smartsheet article in this pass, and Smartsheet has reorganized Admin Center navigation. The path may have moved — verify it in the current Admin Center before relying on it in a runbook.

---

## Appendix A: Edition Compatibility

Verified against current Smartsheet documentation on 2026-08-08:

| Control | Guide Section | Plan requirement |
|---------|---------------|------------------|
| Require MFA (external collaborators) | [1.3](#13-require-mfa-for-external-collaborators) | Enterprise |
| Require work accounts with SSO | [1.1](#11-enforce-sso-with-mfa) | Enterprise |
| Exempt list for external collaborators | [1.3](#13-require-mfa-for-external-collaborators) | Enterprise |
| User session expiration | [1.4](#14-configure-user-session-expiration) | Enterprise |
| IdP-Managed Access | [1.5](#15-automate-the-user-lifecycle-from-your-idp) | Enterprise |
| User Auto-Provisioning | [1.5](#15-automate-the-user-lifecycle-from-your-idp) | Enterprise |
| Safe sharing list | [2.1](#21-configure-sharing-defaults) | Enterprise |
| Publishing controls | [2.1](#21-configure-sharing-defaults) | Business or Enterprise |
| Form security settings | [2.2](#22-form-security) | Business or Enterprise |
| Data egress policy | [2.3](#23-enforce-the-data-egress-policy) | Enterprise, or Advanced Work Management |
| Data retention policy | [2.4](#24-configure-the-data-retention-policy) | Advanced Work Management |
| AI Management | [2.5](#25-manage-ai-capabilities) | Pro, Business, or Enterprise |
| API access token expiration | [3.1](#31-connector-security) | Not stated in the cited documentation |

**Advanced Work Management / Safeguard note:** the **Governance Controls** surface that hosts the data egress and data retention policies is gated separately from the base plan. Smartsheet documents it as requiring a **Smartsheet Advanced Platinum** subscription, **or** Advanced Work Management **plus Safeguard**. Confirm your entitlement before planning around either control.

**Not verified this pass:** the plan requirements previously listed here for SAML SSO, Activity Log, and Group Admin were not re-confirmed against current Smartsheet documentation and have been removed rather than carried forward. Verify them directly before relying on them.

---

## Appendix B: References

**Official Smartsheet Documentation:**
- [Help Center](https://help.smartsheet.com/)
- [Configure Require MFA](https://help.smartsheet.com/articles/2483523-admin-center-configure-require-mfa)
- [Require Work Accounts with SSO](https://help.smartsheet.com/articles/2483524-admin-center-configure-require-work-accounts-sso)
- [Exempt List for External Collaborators](https://help.smartsheet.com/articles/2483521-admin-center-create-exempt-list-external-collaborators)
- [Configure User Session Expiration](https://help.smartsheet.com/articles/2483618-admin-center-configure-user-session-expiration)
- [Configure IdP-Managed Access](https://help.smartsheet.com/articles/2483300-admin-center-configure-idp-managed-access)
- [User Auto-Provisioning (Enterprise)](https://help.smartsheet.com/articles/2072731-user-auto-provisioning-enterprise-only)
- [Configure Publishing Controls](https://help.smartsheet.com/articles/2483487-admin-center-configure-publishing-controls)
- [Configure Safe Sharing](https://help.smartsheet.com/articles/855284-configure-safe-sharing)
- [Apply Security Settings to Forms](https://help.smartsheet.com/articles/2483290-apply-security-settings-forms)
- [Data Egress Policy](https://help.smartsheet.com/articles/2482620-data-egress-policy)
- [Configure Data Retention](https://help.smartsheet.com/articles/2482386-configure-data-retention)
- [Manage AI Capabilities](https://help.smartsheet.com/articles/2483723-manage-ai-capabilities-admin-center)
- [Configure Access Token Expiration Time](https://help.smartsheet.com/articles/2483100-configure-access-token-expiration-time)

**API & Developer Tools:**
- [Developer Portal](https://developers.smartsheet.com/)
- [API Introduction](https://developers.smartsheet.com/api/smartsheet/introduction)
- SDKs available for C#, Java, Node.js, and Python -- via [Developer Portal](https://developers.smartsheet.com/)

**Compliance Frameworks:**
- Smartsheet publicly claims SOC 1, SOC 2 Type II, SOC 3, ISO 27001:2022, ISO 27018:2019, and ISO 27701:2019. Request current attestations directly through your account team — certification pages describe Smartsheet's own posture and are not customer configuration guidance.

**Security Incidents:**
- No major direct Smartsheet data breach publicly reported. In the October 2023 Okta support system compromise, a Smartsheet service account credential was stolen and later used by threat actors to access Cloudflare's Atlassian environment (not a Smartsheet platform breach). Separately, Smartsheet patched an account-hijacking vulnerability before any known exploitation.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass: add 1.3 Require MFA + exempt list, 1.4 user session expiration, 1.5 IdP-managed access and auto-provisioning, 2.3 data egress policy, 2.4 data retention policy, 2.5 AI management; add require-work-accounts-with-SSO to 1.1; rewrite 2.1 publishing controls and add the safe sharing list (disabled by default); rewrite 2.2 around the plan-wide form security floor and note that CAPTCHA/attachment controls are undocumented; add API access token expiration to 3.1 (unexpiring tokens live indefinitely); remove the empty Detection Focus heading and annotate the unconfirmed Activity Log path; rebuild Appendix A from verified plan requirements only; remove Trust Center and marketing security links from Appendix B. Tier 3/4 sources not surveyed this pass. | Claude Code (Opus 5) |
| 2025-12-14 | 0.1.0 | draft | Initial Smartsheet hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
