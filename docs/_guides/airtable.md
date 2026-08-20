---
layout: guide
title: "Airtable Hardening Guide"
vendor: "Airtable"
slug: "airtable"
tier: "2"
category: "Productivity"
description: "Low-code platform hardening for Airtable Business and Enterprise Scale including SSO, admin panel controls, AI governance, export controls, and collaboration security"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

Airtable is a leading low-code platform combining spreadsheets and databases, used by **hundreds of thousands of organizations** for workflow automation, project management, and business applications. As a repository for business-critical data and processes, Airtable security configurations directly impact data protection and operational integrity.

### Intended Audience
- Security engineers managing business platforms
- IT administrators configuring Airtable at Business or Enterprise Scale
- GRC professionals assessing low-code security
- Business operations teams managing workspaces

**Plan naming:** Airtable's current plans are **Free**, **Team**, **Business**, and **Enterprise Scale** ([Airtable pricing](https://www.airtable.com/pricing)). A standalone plan called "Enterprise" no longer exists — where older documentation or this guide's history said "Enterprise," read it as Business or Enterprise Scale as noted per control.

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Airtable Enterprise Admin Panel security including SSO configuration, domain management, access controls, and collaboration settings.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Domain & User Management](#2-domain--user-management)
3. [Access & Collaboration Controls](#3-access--collaboration-controls)
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
Configure SAML SSO to centralize authentication for Airtable users.

#### Rationale
**Why This Matters:**
- Centralizes Airtable authentication in your corporate IdP so MFA, conditional access, and password policy apply to every login
- Standalone Airtable passwords bypass IdP controls and are a prime target for phishing and credential stuffing
- Federating logins under SSO eliminates shadow personal accounts that admins cannot see or revoke
- Bases hold business-critical records and customer data, so a single unmanaged login can expose entire workspaces

**Attack Prevented:** Credential theft, phishing, password reuse, unmanaged shadow accounts

#### Prerequisites
- Airtable **Business** or **Enterprise Scale** plan — SSO is available on both, not Enterprise Scale only ([Configuring SSO in the admin panel](https://support.airtable.com/docs/configuring-sso-in-the-admin-panel))
- Verified domain in the admin panel
- SAML 2.0 compatible identity provider

#### ClickOps Implementation

**Step 1: Verify Domain**
1. Navigate to: **Admin Panel** → **Settings** → **Security & compliance** → **Email domains and SSO**
2. Add your organization's domain
3. Complete domain verification via DNS
4. SCIM and SSO cannot be configured for unverified domains

**Step 2: Configure SSO**
1. Navigate to: **Admin Panel** → **Settings** → **Security & Authentication**
2. Begin SSO configuration
3. Select identity provider — supported providers include:
   - Okta
   - Microsoft Entra ID (Azure AD)
   - OneLogin
   - Google
   - ADFS
   - Custom SAML

**Step 3: Configure IdP Settings**
1. Download Airtable SP metadata
2. **Select the correct metadata version:** Okta and OneLogin require the **V1** metadata option from the dropdown; other identity providers use **V2**. Choosing the wrong version is the most common cause of a failed first SSO handshake.
3. Configure IdP application:
   - NameID: User's email address
   - NameID format: EmailAddress or unspecified
4. Upload IdP metadata to Airtable

**Step 4: Test and Enforce**
1. Test SSO authentication
2. Select enforcement:
   - **Optional:** Users can use SSO or password
   - **Required:** Users must use SSO only
3. Verify before requiring to prevent lockout

**Time to Complete:** ~1 hour

---

### 1.2 Configure Two-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for organization members.

#### Rationale
**Why This Matters:**
- A second authentication factor blocks account takeover even when a password is phished, leaked, or reused
- Enforcing 2FA organization-wide removes the gap left by members who would otherwise opt out
- Airtable accounts can read and export sensitive business data, making them high-value targets for credential attacks
- IdP-enforced MFA gives consistent, auditable coverage across every federated user

**Attack Prevented:** Account takeover, credential stuffing, password reuse, phishing

#### Prerequisites
- Enterprise Scale plan for enforced 2FA

#### ClickOps Implementation

**Step 1: Enable 2FA via SSO (Recommended)**
1. Configure MFA in your identity provider
2. All SSO users subject to IdP MFA
3. Preferred approach for enterprise

**Step 2: Enable Native 2FA (Enterprise Scale)**
1. Navigate to: **Admin Panel** → **Settings** → **Security & compliance** → **Two-factor authentication**
2. Choose the enforcement scope:
   - **Members** — enforced for organization members only
   - **All users** — enforced for members and other users in scope
   - **Disabled**
3. Members enroll with an authenticator app; where SMS is still offered on a plan, treat it as a legacy fallback rather than an acceptable factor
4. Enforce for all organization members

Sources: [Settings — Airtable enterprise admin panel](https://support.airtable.com/docs/settings-airtable-enterprise-admin-panel), [Enabling two-factor authentication](https://support.airtable.com/docs/enabling-two-factor-authentication)

---

### 1.3 Configure SCIM Provisioning

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Configure SCIM for automatic user lifecycle management.

#### Rationale
**Why This Matters:**
- Automatic deprovisioning revokes Airtable access the moment a user is disabled in the IdP, closing the window for orphaned accounts
- Manual offboarding is error-prone and routinely leaves departed employees and contractors with standing data access
- SCIM keeps group and role assignments in sync with the IdP, preventing privilege drift over time
- Centralized lifecycle management produces a consistent, auditable record of who has access and why

**Attack Prevented:** Orphaned-account access, privilege creep, insider data exfiltration after offboarding

#### Prerequisites
- Airtable **Business** or **Enterprise Scale** plan — SCIM is available on both ([Configuring SSO in the admin panel](https://support.airtable.com/docs/configuring-sso-in-the-admin-panel))
- A verified email domain (SCIM cannot be configured for unverified domains)

#### ClickOps Implementation

**Step 1: Configure SCIM (Okta/Entra)**
1. Identity provider sync is configured alongside SSO under **Admin Panel** → **Settings** → **Security & Authentication** (the same area that holds **Email domains and SSO** under **Security & compliance**)
2. Generate the SCIM token from that configuration
3. Configure the IdP SCIM integration
4. Airtable ships default SCIM integrations for **Okta** and **Microsoft Entra ID**

**Step 2: Custom SCIM (Enterprise API)**
1. Use Enterprise API for custom integrations
2. Build custom SCIM workflows
3. Requires developer support

**Step 3: Verify Provisioning**
1. Test user creation from IdP
2. Verify user appears in Airtable
3. Test deprovisioning

---

## 2. Domain & User Management

### 2.1 Configure Domain Federation

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Verify and federate your organization's domains for complete control.

#### Rationale
**Why This Matters:**
- Domain verification unlocks full admin panel functionality
- Controls all accounts using your domain
- Required for SSO and SCIM configuration
- Until the domain is claimed, employees who signed up with their work email hold accounts outside every control in this guide — no SSO, no enforced 2FA, no audit coverage, and no way for an administrator to revoke them

**Attack Prevented:** Shadow account sprawl outside admin control, unmanaged accounts surviving offboarding, bypass of SSO and 2FA enforcement through unclaimed work-email sign-ups

#### ClickOps Implementation

**Step 1: Add Domain**
1. Navigate to: **Admin Panel** → **Settings** → **Security & compliance** → **Email domains and SSO**
2. Click **Add domain**
3. Enter organization domain

**Step 2: Verify Domain**
1. Add DNS TXT record
2. Work with IT/DNS team
3. Verify in Admin Panel

**Step 3: Claim Existing Accounts**
1. View accounts using your domain
2. Migrate to organization membership
3. Consolidate shadow accounts

---

### 2.2 Configure Session Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Configure session timeout and security settings.

#### Rationale
**Why This Matters:**
- Bounded session lifetimes force periodic re-authentication, shrinking the value of a stolen or hijacked session token
- Long-lived sessions on shared or unattended devices let anyone resume an authenticated Airtable session
- Shorter sessions for sensitive bases limit how long an attacker can operate after a single compromise
- Documented session policy supports compliance evidence for access-control requirements

**Attack Prevented:** Session hijacking, unattended-device access, stolen-token reuse

#### ClickOps Implementation

**Step 1: Configure Session Length**
1. Navigate to: **Admin Panel** → **Settings** → **Security & compliance**
2. Configure **Fixed Web Session length**
3. Set how long users can stay signed in

**Step 2: Configure Session Controls**
1. Balance security with usability
2. Consider shorter sessions for sensitive data
3. Document session policy

---

### 2.3 Configure IP Restrictions

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Restrict access to approved IP addresses.

#### Rationale
**Why This Matters:**
- Restricting sign-in to approved networks blocks access attempts from outside your corporate or VPN ranges
- Even valid stolen credentials are useless to an attacker connecting from an unapproved IP
- Network-level controls add a layer that does not depend on user behavior or password strength
- Allowlisting reduces exposure of business-critical bases to the open internet

**Attack Prevented:** Credential theft from external networks, unauthorized remote access, account takeover from attacker infrastructure

#### Prerequisites
- Airtable **Enterprise Scale** plan
- **Request-gated:** IP restrictions are not self-service. Contact your Airtable account manager to have the capability enabled before attempting to configure it ([Settings — Airtable enterprise admin panel](https://support.airtable.com/docs/settings-airtable-enterprise-admin-panel)).

#### ClickOps Implementation

**Step 1: Configure IP Allowlist**
1. Navigate to: **Admin Panel** → **Settings** → **Security & compliance**
2. Configure **IP restrictions**
3. Add approved IP ranges in CIDR notation

**Step 2: Apply Restrictions**
1. Only users from approved IPs can sign in
2. Test from approved locations
3. Document emergency procedures — because enablement runs through your account manager, a lockout is not something you can unwind yourself in the console

---

### 2.4 Govern Admin Panel Access and Roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.8 |
| NIST 800-53 | AC-2, AC-6(1), AC-6(7) |

#### Description
Inventory who holds admin panel access and scope each administrator to the areas they need. The admin panel is the single console from which every other control in this guide is set, and it exposes the organization's full estate: **Organization**, **Users**, **Roles**, **Groups**, **Solutions**, **Workspaces**, **Bases**, **Interfaces**, **Data sets**, **HyperDB**, **Managed apps**, **Components**, **Reports**, and **Settings** ([Overview of the admin panel](https://support.airtable.com/docs/overview-of-the-admin-panel)).

#### Rationale
**Why This Matters:**
- Admin panel access is the master key to this guide — an administrator can disable enforced 2FA, loosen IP restrictions, permit external invites, and turn off export controls, so a single compromised admin undoes every other control at once
- The panel spans users, roles, groups, workspaces, bases, interfaces, data sets, HyperDB, managed apps, and reports, so admin access is organization-wide data access, not just settings access
- Administrators can also read the audit log, which means a compromised admin can see exactly what evidence exists of their activity
- Roles and Groups are managed from the same console, so an administrator can grant themselves or others standing access to any workspace without leaving the panel
- Fewer administrators means fewer credentials that are worth phishing, and a shorter list to review when access is audited

**Attack Prevented:** Privileged account takeover collapsing every other control, unauthorized organization-wide data access, silent grant of standing access through Roles and Groups, tampering with security settings

#### Prerequisites
- Airtable **Business** or **Enterprise Scale** plan (admin panel)
- A named owner for the administrator roster

#### ClickOps Implementation

**Step 1: Inventory Administrators**
1. Navigate to: **Admin Panel** → **Users**
2. Record every account holding admin panel access, with a named human owner and a business justification
3. Remove admin access from anyone who cannot be tied to a current justification

**Step 2: Scope Roles Deliberately**
1. Navigate to: **Admin Panel** → **Roles**
2. Assign the narrowest role that lets each administrator do their job, rather than granting full organization administration by default
3. Review **Admin Panel** → **Groups** at the same time — group membership drives access grants and drifts silently as teams change

**Step 3: Protect Admin Accounts**
1. Require SSO for administrators (see [1.1](#11-configure-saml-single-sign-on)) and enforce 2FA (see [1.2](#12-configure-two-factor-authentication))
2. Where available, keep administrators inside the IP restrictions applied to the rest of the organization (see [2.3](#23-configure-ip-restrictions))
3. Review the administrator roster on a fixed cadence and after every reorganization

#### Validation & Testing
1. Confirm the administrator list in **Admin Panel** → **Users** matches the documented roster exactly, with no unexplained entries
2. Confirm every administrator authenticates through SSO with 2FA enforced
3. Review audit log entries for admin settings changes and confirm each maps to an approved change (see [4.1](#41-configure-audit-logging))

#### Compliance Mappings

| Framework | Control | Mapping |
|-----------|---------|---------|
| CIS Controls v8 | 5.4 | Restrict administrator privileges to dedicated accounts |
| CIS Controls v8 | 6.8 | Define and maintain role-based access control |
| NIST 800-53 Rev 5 | AC-2 | Account management |
| NIST 800-53 Rev 5 | AC-6(1) | Authorize access to security functions |
| NIST 800-53 Rev 5 | AC-6(7) | Review of user privileges |
| SOC 2 | CC6.2 | Privileged access is authorized and reviewed |

---

### 2.5 Configure Encryption Key Management and Compliance Settings

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12, SC-28, PL-4 |

#### Description
For regulated environments, configure the compliance-tier settings under **Admin Panel** → **Settings** → **Security & compliance**: enterprise key management (EKM), a custom terms of use presented to users, and the HIPAA toggle. All three are **Enterprise Scale** capabilities ([Settings — Airtable enterprise admin panel](https://support.airtable.com/docs/settings-airtable-enterprise-admin-panel)).

#### Rationale
**Why This Matters:**
- Enterprise key management puts the encryption key under the organization's control, so revoking the key is a unilateral action that cuts access to the data without depending on the vendor's deletion process
- Customer-held keys give a hard, provable answer to the regulator's question of who can decrypt the data, which platform-managed encryption alone does not
- A custom terms of use presents organization-specific acceptable-use conditions at the point of access, which is what makes a later misuse finding enforceable rather than merely disappointing
- The HIPAA toggle changes how the platform must be operated for regulated health data — enabling it deliberately, and confirming which workspaces it covers, is the difference between a supported configuration and an unsupported one
- These settings are contractual and architectural rather than everyday toggles, so they need to be set once, documented, and re-verified at audit rather than rediscovered

**Attack Prevented:** Loss of control over data decryption, unenforceable acceptable-use violations, regulated data processed outside a supported configuration

#### Prerequisites
- Airtable **Enterprise Scale** plan
- Key management infrastructure and an owner for the key lifecycle (EKM)
- Legal review of the custom terms text
- A determination of whether regulated health data is in scope (HIPAA)

#### ClickOps Implementation

**Step 1: Configure Enterprise Key Management**
1. Navigate to: **Admin Panel** → **Settings** → **Security & compliance**
2. Configure enterprise key management with the organization's key material
3. Document key ownership, rotation, and the operational consequences of revocation before enabling — revoking the key makes the data inaccessible by design

**Step 2: Publish Custom Terms of Use**
1. From the same **Security & compliance** area, configure the custom terms of use
2. Use legally reviewed text describing organization-specific acceptable use of Airtable data
3. Record when the terms were published and when they last changed

**Step 3: Set the HIPAA Configuration**
1. Enable the HIPAA setting only where a determination has been made that regulated health data is in scope
2. Confirm the required agreements are in place with Airtable before processing regulated data
3. Document which workspaces and bases are treated as in scope

#### Validation & Testing
1. Confirm EKM is active and that the key owner can demonstrate the revocation procedure without executing it in production
2. Confirm the custom terms of use is presented to users as intended
3. Confirm the HIPAA setting state matches the organization's documented determination, and that no regulated data sits in a workspace outside that scope

#### Compliance Mappings

| Framework | Control | Mapping |
|-----------|---------|---------|
| CIS Controls v8 | 3.11 | Encrypt sensitive data at rest |
| NIST 800-53 Rev 5 | SC-12 | Cryptographic key establishment and management |
| NIST 800-53 Rev 5 | SC-28 | Protection of information at rest |
| NIST 800-53 Rev 5 | PL-4 | Rules of behavior (custom terms of use) |
| SOC 2 | CC6.1 | Encryption keys are managed |

---

## 3. Access & Collaboration Controls

### 3.1 Configure Collaborator Invitations

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Control who can invite external collaborators.

#### Rationale
**Why This Matters:**
- Unrestricted invites let any member share bases with outside parties, expanding the data exposure surface uncontrollably
- Restricting invitations to verified domains keeps collaboration inside organizations you trust and govern
- External collaborators retain access to whatever they were shared on until explicitly removed, creating long-lived exposure
- Centralized invite policy prevents accidental oversharing of sensitive records to personal or competitor accounts

**Attack Prevented:** Data leakage via oversharing, unauthorized external access, accidental exposure of sensitive bases

#### ClickOps Implementation

**Step 1: Configure Invitation Policy**
1. Navigate to: **Admin Panel** → **Settings** → **Sharing & data** → **Collaborator invites**
2. Choose the invitation scope:
   - **Unrestricted** — members can invite anyone
   - **Domain-restricted** — invites limited to verified domains
   - **Org-unit only** — invites limited to members of the org unit

**Step 2: Restrict Portal Guest Invites**
1. From the same **Sharing & data** area, configure who may invite **portal guests**
2. Portal guests are external identities with standing access until removed — treat guest invitation as a separate decision from collaborator invitation
3. Review the guest population on the same cadence as external collaborators

**Step 3: Restrict Group Creation to Admins**
1. Also under **Sharing & data**, restrict group creation to administrators
2. Groups are an access-granting primitive: a member who can create a group can create a durable, reusable access bundle outside the administrator's review
3. Apply this alongside the Groups review in [2.4](#24-govern-admin-panel-access-and-roles)

Source: [Settings — Airtable enterprise admin panel](https://support.airtable.com/docs/settings-airtable-enterprise-admin-panel)

---

### 3.2 Configure Workspace Permissions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege for workspace access.

#### Rationale
**Why This Matters:**
- Least-privilege roles ensure each user can only read or change the data their job requires
- Over-broad Creator or Editor access lets a single compromised account modify or delete entire bases
- Scoping permissions by team and function limits the blast radius of any account compromise or insider misuse
- Granular base-level roles support separation of duties and audit requirements

**Attack Prevented:** Privilege escalation, lateral movement, insider data tampering, blast-radius expansion

#### ClickOps Implementation

**Step 1: Configure Workspace Structure**
1. Navigate to: **Admin Panel** → **Workspaces**
2. Organize by team or function
3. Set appropriate access levels
4. Review the adjacent inventory surfaces in the same panel — **Bases**, **Interfaces**, **Data sets**, **HyperDB**, **Managed apps**, and **Components** — so permission review covers every place organization data actually lives, not workspaces alone ([Overview of the admin panel](https://support.airtable.com/docs/overview-of-the-admin-panel))

**Step 2: Configure Base Permissions**
1. Set base-level permissions:
   - Creator
   - Editor
   - Commenter
   - Read only
2. Apply minimum necessary access

---

### 3.3 Configure Interface Permissions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control access to Airtable Interfaces.

#### Rationale
**Why This Matters:**
- Interfaces expose curated views of underlying base data, so uncontrolled access can leak records the viewer should not see
- Restricting who can create and edit interfaces prevents unauthorized reshaping or exposure of sensitive data
- Sensitivity labels give users a clear visual cue to handle high-risk bases and interfaces appropriately
- Scoped interface access aligns shared dashboards with the principle of least privilege

**Attack Prevented:** Unauthorized data disclosure, oversharing through interface views, mishandling of sensitive data

#### ClickOps Implementation

**Step 1: Configure Interface Access**
1. Navigate to: **Base** → **Interfaces**
2. Configure who can:
   - Create interfaces
   - View interfaces
   - Edit interfaces

**Step 2: Apply Sensitivity Labels**
1. Navigate to: **Admin Panel** → **Settings** → **Security & compliance** → **Sensitivity labels**
2. Create custom labels
3. Apply to bases and interfaces
4. Visual cue for data sensitivity

**Sensitivity labels are advisory, not enforcing.** A label changes what a user *sees* about a base or interface; it does not restrict who can open, edit, share, or export it. Access is still governed entirely by the permissions in [3.2](#32-configure-workspace-permissions), the invite policy in [3.1](#31-configure-collaborator-invitations), and the export controls in [3.5](#35-configure-data-export-controls). Treat labels as a signal to users, never as a control.

**Plan availability — Tier 1 sources disagree.** Airtable's dedicated article states sensitivity labels are an **Enterprise Scale** capability ([App sensitivity in the admin panel](https://support.airtable.com/docs/app-sensitivity-in-admin-panel)), while the admin panel settings index lists them as available from **Business** upward ([Settings — Airtable enterprise admin panel](https://support.airtable.com/docs/settings-airtable-enterprise-admin-panel)). The dedicated article is treated as primary here; both are recorded rather than silently reconciled. Confirm against your own plan before designing a labelling scheme around it.

---

### 3.4 Govern Airtable AI and Omni

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.3, 3.3 |
| NIST 800-53 | AC-3, CM-7, SA-9 |

#### Description
Configure the AI controls under **Admin Panel** → **Settings** → **AI settings**: the master Airtable AI toggle, the model-developer allowlist, per-workspace AI restriction, Omni enablement, internet access, web prototype generation, AI Labs, and credit usage ([Settings — Airtable enterprise admin panel](https://support.airtable.com/docs/settings-airtable-enterprise-admin-panel), [Using Omni AI in Airtable](https://support.airtable.com/docs/using-omni-ai-in-airtable)).

#### Rationale
**Why This Matters:**
- Omni is an agent, not a chat box: it reads base data, builds tables and automations, and can research the web, so enabling it grants an autonomous actor write access to organization data
- **Omni mirrors the permissions of the user who invokes it**, which means every over-broad permission grant from [3.2](#32-configure-workspace-permissions) is inherited directly by the agent — an over-permissioned user becomes an over-permissioned agent that acts far faster than they would
- The model-developer allowlist decides which third parties may process base content (OpenAI, Anthropic, Gemini, Meta, IBM, Amazon), which is a vendor and data-residency decision that belongs in vendor review rather than a default
- Internet access and web prototype generation turn a data-reading agent into one that also communicates outward, which is the pathway that turns a prompt-injection payload sitting in a record into data egress
- Restricting AI by workspace lets regulated or sensitive workspaces stay outside AI processing while the rest of the organization uses it, instead of forcing one org-wide answer

**Attack Prevented:** Prompt-injection-driven data egress through an agent with internet access, unreviewed data flow to third-party model providers, privilege inheritance by an agent acting under an over-permissioned user, unsanctioned AI processing of regulated data

> **Changed default — AI is enabled by default outside the EU.** Airtable AI is **on by default** for organizations outside the European Union; EU organizations are opt-in for GDPR reasons. If nobody in your organization has made an explicit decision about AI, the default has made it for you and AI is already enabled. Verify the current state before assuming otherwise. ([Settings — Airtable enterprise admin panel](https://support.airtable.com/docs/settings-airtable-enterprise-admin-panel))

#### Prerequisites
- Admin panel access
- A vendor review covering the model developers you intend to allow
- A determination of which workspaces may process data with AI

#### ClickOps Implementation

**Step 1: Set the Master AI Toggle Deliberately**
1. Navigate to: **Admin Panel** → **Settings** → **AI settings**
2. Confirm the current state of the master **Airtable AI** toggle — do not assume it is off
3. Record the enablement decision, its owner, and its date

**Step 2: Restrict Model Developers**
1. In the same AI settings area, set the allowed model developers from the available list: **OpenAI**, **Anthropic**, **Gemini**, **Meta**, **IBM**, **Amazon**
2. Allow only developers that have passed vendor review, and remove the rest — an unreviewed developer on the allowlist is an unreviewed processor of base content
3. Re-review when Airtable adds a developer to the list

**Step 3: Scope AI by Workspace**
1. Use the restrict-AI-by-workspace setting to keep regulated or sensitive workspaces out of AI processing
2. Align the scoped list with the sensitivity labels applied in [3.3](#33-configure-interface-permissions)
3. Re-check scope whenever a new workspace holding sensitive data is created

**Step 4: Govern Omni Specifically**
1. Decide whether **Omni** is enabled, treating it as an agent with the invoking user's permissions rather than as a feature
2. Tighten the permissions in [3.2](#32-configure-workspace-permissions) *before* enabling Omni — the agent inherits whatever is over-broad today
3. Set **internet access** and **web prototype generation** according to whether the organization accepts an agent that can both read base data and reach outward
4. Decide on **AI Labs** participation explicitly, since preview capabilities change behavior under an existing toggle
5. Monitor **credit usage** — an unexplained jump is a usable signal that AI is being driven harder than the sanctioned use case explains

#### Validation & Testing
1. Confirm the master AI toggle state matches the recorded decision, especially for non-EU organizations where the default is on
2. Confirm only reviewed model developers appear on the allowlist
3. Confirm a workspace excluded from AI cannot be operated on by AI features
4. Confirm that a user with restricted base access cannot obtain restricted data by invoking Omni — the agent should mirror their permissions, not exceed them
5. Review credit usage against the expected baseline

#### Compliance Mappings

| Framework | Control | Mapping |
|-----------|---------|---------|
| CIS Controls v8 | 2.3 | Address unauthorized software and services |
| CIS Controls v8 | 3.3 | Configure data access control lists |
| NIST 800-53 Rev 5 | AC-3 | Access enforcement |
| NIST 800-53 Rev 5 | CM-7 | Least functionality |
| NIST 800-53 Rev 5 | SA-9 | External system services (model developers) |
| SOC 2 | CC6.1 | Logical access to data processed by third parties |

---

### 3.5 Configure Data Export Controls

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1, 3.3 |
| NIST 800-53 | AC-3, AC-4, SC-7 |

#### Description
Restrict how base data can leave Airtable using the export controls under **Admin Panel** → **Settings** → **Sharing & data** → **Data export**: block CSV download, printing, and copy-paste; scope the restriction to non-members only or to all users; and maintain a trusted-domain allowlist ([Collaboration and export controls in the admin panel](https://support.airtable.com/docs/collaboration-export-controls-in-admin-panel)).

#### Rationale
**Why This Matters:**
- Permissions decide who can *see* a base; export controls decide whether what they see can be walked out of the platform in bulk, which is the difference between a read and a breach
- CSV download turns a scoped view into a portable, permanent, uncontrolled copy that no later permission change can retract
- Copy-paste and printing are the quiet exfiltration paths that survive when only file download is blocked
- Scoping to non-members only lets the organization restrict external collaborators and portal guests without breaking the internal workflows that depend on export
- A trusted-domain allowlist keeps sanctioned integration destinations working while everything else is denied, so the control can be enforced rather than perpetually granted exceptions

**Attack Prevented:** Bulk data exfiltration by a compromised or departing account, uncontrolled copies escaping permission changes, external collaborator data theft, insider data harvesting

> **Documented limitation:** Per Airtable, "Export controls do not allow admins to manage screenshots." A determined user with legitimate read access can still capture what is on screen. Export controls raise the cost and create a record; they do not make read access safe. Pair them with least-privilege permissions ([3.2](#32-configure-workspace-permissions)) and audit logging ([4.1](#41-configure-audit-logging)).

#### Prerequisites
- Admin panel access
- An inventory of workflows that legitimately depend on CSV export
- The list of trusted destination domains

#### ClickOps Implementation

**Step 1: Set the Export Restrictions**
1. Navigate to: **Admin Panel** → **Settings** → **Sharing & data** → **Data export**
2. Block **CSV download**, **printing**, and **copy-paste** as your policy requires
3. Enable them individually rather than as a block — leaving copy-paste open while blocking CSV download is a common and largely self-defeating configuration

**Step 2: Choose the Scope**
1. Apply the restriction either to **non-members only** or to **all users**
2. Start with non-members if internal export workflows are load-bearing, then tighten
3. Record which internal workflows justify any exemption

**Step 3: Maintain the Trusted-Domain Allowlist**
1. Add the domains that sanctioned integrations legitimately export to
2. Review the allowlist on the same cadence as the third-party integration review in [4.2](#42-configure-api-and-integration-security)
3. Remove domains belonging to retired integrations

#### Validation & Testing
1. Attempt a CSV download as a restricted user and confirm it is blocked
2. Confirm copy-paste and printing behave as configured, not just file download
3. Confirm export to a non-allowlisted domain is refused while a sanctioned destination still works
4. Review audit log export events to confirm the remaining export activity has an owner and a reason (see [4.1](#41-configure-audit-logging))

#### Compliance Mappings

| Framework | Control | Mapping |
|-----------|---------|---------|
| CIS Controls v8 | 3.1 | Establish and maintain a data management process |
| CIS Controls v8 | 3.3 | Configure data access control lists |
| NIST 800-53 Rev 5 | AC-3 | Access enforcement |
| NIST 800-53 Rev 5 | AC-4 | Information flow enforcement |
| NIST 800-53 Rev 5 | SC-7 | Boundary protection |
| SOC 2 | CC6.7 | Restrict transmission and removal of information |

---

### 3.6 Restrict Share Links and Public Interfaces

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3, AC-22 |

#### Description
Constrain unauthenticated and semi-authenticated access paths using the sharing settings under **Admin Panel** → **Settings** → **Sharing & data**: the share-link policy (public, flexible, private, members-only), the prevent-public-interface-sharing setting, the attachment-type allowlist, synced-views restrictions, and the HyperDB install restriction ([Settings — Airtable enterprise admin panel](https://support.airtable.com/docs/settings-airtable-enterprise-admin-panel)).

#### Rationale
**Why This Matters:**
- A public share link is access without an identity: no SSO, no 2FA, no IP restriction, and no name in the audit log — every authentication control in this guide is bypassed by one URL
- Share links are durable and forwardable, so a link created for one recipient becomes access for everyone it is ever pasted to, including search engines if it is indexed
- Public interfaces present a curated view of live base data to anyone with the address, which makes them the highest-consequence sharing setting in the product
- Synced views propagate data into bases with different permissions, so an unrestricted sync quietly relocates records into a workspace with a broader audience than the source
- The attachment-type allowlist governs what files enter and leave through base records, which is both a malware path inbound and a data path outbound
- HyperDB installation brings additional data surface under management, so restricting who can install it keeps the estate reviewable

**Attack Prevented:** Unauthenticated data exposure through leaked or indexed share links, public interface disclosure of live records, permission bypass via synced views, malware delivery through unrestricted attachments

#### Prerequisites
- Admin panel access
- An inventory of existing share links and public interfaces
- A decision on whether any public sharing is acceptable

#### ClickOps Implementation

**Step 1: Set the Share-Link Policy**
1. Navigate to: **Admin Panel** → **Settings** → **Sharing & data**
2. Choose the share-link level: **public**, **flexible**, **private**, or **members-only**
3. Default to the most restrictive level the organization's workflows tolerate — moving from public to members-only is the single highest-value change in this control

**Step 2: Prevent Public Interface Sharing**
1. Enable the setting preventing public interface sharing
2. Audit existing public interfaces before enforcing, so you know what breaks and who owns it
3. Re-check after enforcement that no interface remains publicly reachable

**Step 3: Restrict Attachments, Synced Views, and HyperDB**
1. Configure the attachment-type allowlist to the file types the business actually needs
2. Apply the synced-views restrictions so data cannot be replicated into a workspace with a wider audience than its source
3. Restrict who may install HyperDB

#### Validation & Testing
1. Open an existing share link in a private browser session with no Airtable account and confirm the result matches your configured policy
2. Confirm a member cannot create a public interface once the restriction is enabled
3. Confirm a disallowed attachment type is rejected
4. Confirm a synced view cannot be created into a workspace outside the permitted scope

#### Compliance Mappings

| Framework | Control | Mapping |
|-----------|---------|---------|
| CIS Controls v8 | 3.3 | Configure data access control lists |
| NIST 800-53 Rev 5 | AC-3 | Access enforcement |
| NIST 800-53 Rev 5 | AC-22 | Publicly accessible content |
| SOC 2 | CC6.1 | Logical access to information assets is restricted |

---

## 4. Monitoring & Compliance

### 4.1 Configure Audit Logging

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor audit logs for security events.

#### Rationale
**Why This Matters:**
- Audit logs provide the record needed to detect, investigate, and respond to suspicious activity in Airtable
- Without logging, account compromise, data exports, and permission changes go unnoticed until damage is done
- Monitoring provisioning and external-collaborator events surfaces unauthorized access early
- Retained logs supply the forensic evidence and compliance proof required after a security incident

**Attack Prevented:** Undetected breaches, insider misuse, unnoticed data exfiltration, tampering without accountability

#### Prerequisites
- Airtable **Enterprise Scale** plan ([Accessing enterprise audit logs in Airtable](https://support.airtable.com/docs/accessing-enterprise-audit-logs-in-airtable))

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Admin Panel** → **Reports** → **Audit log**
2. Review logged events:
   - User login/logout
   - Permission changes
   - Base access
   - Data exports

**Step 2: Work Within the Retention and Result Limits**
1. Audit log events are retained and searchable for **180 days** — anything the organization needs beyond that window must be exported before it ages out
2. The admin panel UI returns a maximum of **10,000 events** per view; larger result sets require the API
3. Where an investigation or compliance obligation exceeds either limit, build a scheduled export via the API rather than relying on the console

**Step 3: Enable Change Events (Enterprise Scale)**
1. Contact account manager to enable
2. Provides detailed change tracking
3. API access for integration

**Key Events to Monitor:**
- User provisioning/deprovisioning
- Permission changes
- External collaborator additions
- Data exports
- SSO configuration changes
- AI and Omni usage (see [3.4](#34-govern-airtable-ai-and-omni))

---

### 4.2 Configure API and Integration Security

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.3, 2.7, 3.11 |
| NIST 800-53 | SC-12, CM-7, SA-9, AC-20 |

#### Description
Govern the programmatic and third-party surface from **Admin Panel** → **Settings** → **Integrations & development**, alongside personal access token hygiene. This area controls API access to organization bases and workspaces (with an allowlist), third-party API access, custom-code development and its developer allowlist, third-party extensions, integrations inside automations and external source sync, sync via email/API/admin panel, Slack link previews, and Drive shortcut blocking ([Settings — Airtable enterprise admin panel](https://support.airtable.com/docs/settings-airtable-enterprise-admin-panel)).

#### Rationale
**Why This Matters:**
- Personal access tokens can read and export base data programmatically, bypassing SSO, 2FA, and every interactive login control in this guide
- Blocking API access org-wide with a narrow allowlist inverts the default: instead of hoping no one issues an unsanctioned token, only sanctioned callers work at all
- Third-party extensions and integrations execute against live base data, so an unvetted extension is a supply-chain path that never touches Airtable's authentication
- Custom-code development inside the platform means members can ship code that reads organization data — a developer allowlist decides whether that capability is scoped or universal
- External source sync and sync-via-email are data ingress and egress paths that permission review of bases alone will not surface
- Unmanaged or never-expiring tokens are durable credentials that persist long after the integration and often long after the person who created them

**Attack Prevented:** Token leakage and standing-credential abuse, automated data exfiltration, supply-chain compromise via third-party extensions and integrations, unreviewed code execution against organization data, undisclosed data egress through sync paths

#### Prerequisites
- Admin panel access
- An inventory of sanctioned integrations and their owners
- A review path for extension and developer allowlist requests

#### ClickOps Implementation

**Step 1: Restrict API Access**
1. Navigate to: **Admin Panel** → **Settings** → **Integrations & development**
2. Block API access to organization bases and workspaces, then add only the sanctioned callers to the allowlist
3. Block third-party API access where no reviewed third party requires it

**Step 2: Control Extensions and Custom Code**
1. Set the third-party extensions policy: **allow all**, **deny non-Airtable**, or **deny all** — deny non-Airtable is the usual defensible middle position
2. Prevent custom-code development, and use the developer allowlist to grant it only to reviewed builders
3. Re-review the developer allowlist whenever a builder changes roles or leaves

**Step 3: Close the Sync and Integration Paths**
1. Block integrations inside automations and external source sync unless a reviewed use case requires them
2. Block sync via email, API, and admin panel where those paths are not needed
3. Configure Slack link previews and Drive shortcut blocking according to whether metadata about bases should leave the platform through those surfaces

**Step 4: Manage Personal Access Tokens**
1. Users generate tokens in account settings — maintain an inventory mapping each sanctioned token to a named owner and integration
2. Configure token expiration policies
3. Review API access patterns, identify unauthorized integrations, and revoke unnecessary tokens

#### Validation & Testing
1. Confirm an API call from a non-allowlisted caller is refused while a sanctioned integration still works
2. Confirm a member cannot install a third-party extension that the policy denies
3. Confirm a non-allowlisted user cannot create custom code in a base
4. Reconcile active tokens against the inventory and investigate any that cannot be mapped to a sanctioned integration

#### Compliance Mappings

| Framework | Control | Mapping |
|-----------|---------|---------|
| CIS Controls v8 | 2.3 | Address unauthorized software |
| CIS Controls v8 | 2.7 | Allowlist authorized scripts and applications |
| CIS Controls v8 | 3.11 | Encrypt sensitive data at rest (token handling) |
| NIST 800-53 Rev 5 | CM-7 | Least functionality |
| NIST 800-53 Rev 5 | SA-9 | External system services |
| NIST 800-53 Rev 5 | AC-20 | Use of external systems |
| NIST 800-53 Rev 5 | SC-12 | Cryptographic key/credential management |
| SOC 2 | CC6.1 | Logical access via programmatic interfaces is authorized |

---

### 4.3 Configure Conditional Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Use IdP conditional access for enhanced security.

#### Rationale
**Why This Matters:**
- Conditional access evaluates device health, location, and risk signals before granting an Airtable session
- Requiring compliant devices keeps business data off unmanaged or jailbroken endpoints
- Blocking risky sign-ins and enabling continuous evaluation revokes access when conditions change mid-session
- Session controls reduce the chance of data exfiltration from compromised or non-compliant contexts

**Attack Prevented:** Access from compromised devices, risky sign-ins, session-based data exfiltration, location-based attacks

#### ClickOps Implementation

**Step 1: Configure IdP Conditional Access**
1. Configure in Microsoft Entra or other IdP
2. Enforce session control
3. Protect against data exfiltration

**Step 2: Configure Policies**
1. Require compliant devices
2. Block risky sign-ins
3. Enable continuous access evaluation

---

### 4.4 Configure Data Retention Policies

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1, 3.5 |
| NIST 800-53 | SI-12, AU-11, MP-6 |

#### Description
Set the organization's retention posture under **Admin Panel** → **Settings**. Airtable retains revision history for **3 years** by default and keeps deleted content in trash for **30 days**; custom inactivity-based retention policies are available at **Enterprise Scale** ([Settings — Airtable enterprise admin panel](https://support.airtable.com/docs/settings-airtable-enterprise-admin-panel)).

#### Rationale
**Why This Matters:**
- Three years of revision history means a record's *former* values remain readable long after someone "removed" sensitive data from a cell — deletion in Airtable is not deletion until retention says so
- The same history is an asset for investigation and a liability for regulated data, so the retention period is a deliberate risk trade-off rather than a default to inherit
- The 30-day trash window is a real recovery capability against ransomware-style mass deletion and against a departing employee clearing records, but only if responders know it exists and act inside it
- Custom inactivity policies clear out abandoned bases and workspaces, which is what stops the estate from accumulating forgotten data that nobody reviews but everybody still holds
- Retention that outlives the organization's own data-minimization commitments is an audit finding waiting to be written

**Attack Prevented:** Sensitive data recoverable long after apparent deletion, unrecoverable mass deletion by a compromised or departing account, unbounded accumulation of unreviewed data in abandoned bases

#### Prerequisites
- Admin panel access
- Airtable **Enterprise Scale** for custom inactivity-based policies
- The organization's documented retention and data-minimization requirements

#### ClickOps Implementation

**Step 1: Record the Defaults**
1. Navigate to: **Admin Panel** → **Settings**
2. Confirm the current revision-history retention (default **3 years**) and trash window (**30 days**)
3. Compare both against the organization's stated retention commitments and record any gap

**Step 2: Set Custom Inactivity Policies (Enterprise Scale)**
1. Configure inactivity-based retention so abandoned bases and workspaces are cleared rather than accumulating indefinitely
2. Choose the inactivity threshold with the data owners, not unilaterally — an aggressive threshold destroys seasonal workloads
3. Communicate the policy before it first takes effect

**Step 3: Operationalize the Trash Window**
1. Document the 30-day trash window in the incident-response runbook as the recovery path for mass deletion
2. Ensure whoever responds to a deletion incident knows the window exists and how to restore within it
3. Treat the window as the deadline it is — after 30 days, restoration is no longer a self-service option

#### Validation & Testing
1. Confirm the configured retention values match the organization's documented requirements
2. Confirm a custom inactivity policy applies as intended to a test workspace before broad rollout
3. Confirm restoration from trash works and is understood by the responders who would need it under pressure
4. Confirm that data required to be minimized is not still readable through revision history

#### Compliance Mappings

| Framework | Control | Mapping |
|-----------|---------|---------|
| CIS Controls v8 | 3.1 | Establish and maintain a data management process |
| CIS Controls v8 | 3.5 | Securely dispose of data |
| NIST 800-53 Rev 5 | SI-12 | Information management and retention |
| NIST 800-53 Rev 5 | AU-11 | Audit record retention |
| NIST 800-53 Rev 5 | MP-6 | Media sanitization |
| SOC 2 | CC6.5 | Data is disposed of when no longer required |

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Airtable Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Workspace permissions | [3.2](#32-configure-workspace-permissions) |
| CC6.2 | Admin panel access and roles | [2.4](#24-govern-admin-panel-access-and-roles) |
| CC6.6 | IP restrictions | [2.3](#23-configure-ip-restrictions) |
| CC7.2 | Audit logging | [4.1](#41-configure-audit-logging) |
| CC6.7 | Session security | [2.2](#22-configure-session-security) |
| CC6.7 | Data export controls | [3.5](#35-configure-data-export-controls) |
| CC6.1 | Share links and public interfaces | [3.6](#36-restrict-share-links-and-public-interfaces) |
| CC6.1 | AI and Omni governance | [3.4](#34-govern-airtable-ai-and-omni) |
| CC6.1 | API and integration security | [4.2](#42-configure-api-and-integration-security) |
| CC6.1 | Encryption key management | [2.5](#25-configure-encryption-key-management-and-compliance-settings) |
| CC6.5 | Data retention | [4.4](#44-configure-data-retention-policies) |

### NIST 800-53 Rev 5 Mapping

| Control | Airtable Control | Guide Section |
|---------|------------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | 2FA | [1.2](#12-configure-two-factor-authentication) |
| AC-2 | SCIM | [1.3](#13-configure-scim-provisioning) |
| AC-3 | Permissions | [3.2](#32-configure-workspace-permissions) |
| AC-6(1) | Admin panel access and roles | [2.4](#24-govern-admin-panel-access-and-roles) |
| AC-4 | Data export controls | [3.5](#35-configure-data-export-controls) |
| AC-22 | Share links and public interfaces | [3.6](#36-restrict-share-links-and-public-interfaces) |
| CM-7 | API and integration security | [4.2](#42-configure-api-and-integration-security) |
| SA-9 | AI and Omni governance | [3.4](#34-govern-airtable-ai-and-omni) |
| SC-12 | Encryption key management | [2.5](#25-configure-encryption-key-management-and-compliance-settings) |
| SI-12 | Data retention | [4.4](#44-configure-data-retention-policies) |
| AU-2 | Audit logging | [4.1](#41-configure-audit-logging) |

---

## Appendix A: Plan Compatibility

Airtable's current plans are **Free**, **Team**, **Business**, and **Enterprise Scale** ([Airtable pricing](https://www.airtable.com/pricing)). A standalone "Enterprise" plan no longer exists.

| Feature | Free | Team | Business | Enterprise Scale |
|---------|------|------|----------|------------------|
| SAML SSO | ❌ | ❌ | ✅ | ✅ |
| SCIM (default Okta / Entra ID integrations) | ❌ | ❌ | ✅ | ✅ |
| Enforced 2FA | ❌ | ❌ | ❌ | ✅ |
| IP Restrictions | ❌ | ❌ | ❌ | ✅* |
| Audit Logs (180-day retention) | ❌ | ❌ | ❌ | ✅ |
| Change Events | ❌ | ❌ | ❌ | ✅ |
| Sensitivity Labels | ❌ | ❌ | ⚠️ | ✅ |
| Data Retention (custom inactivity policies) | ❌ | ❌ | ❌ | ✅ |
| Enterprise Key Management (EKM) | ❌ | ❌ | ❌ | ✅ |
| Custom Terms of Use | ❌ | ❌ | ❌ | ✅ |
| HIPAA | ❌ | ❌ | ❌ | ✅ |

*IP restrictions are Enterprise Scale **and** request-gated — enablement runs through your Airtable account manager rather than self-service ([Settings — Airtable enterprise admin panel](https://support.airtable.com/docs/settings-airtable-enterprise-admin-panel)).

⚠️ Sensitivity labels — Tier 1 sources disagree. The dedicated article states Enterprise Scale ([App sensitivity in the admin panel](https://support.airtable.com/docs/app-sensitivity-in-admin-panel)); the settings index lists Business upward. See [3.3](#33-configure-interface-permissions).

---

## Appendix B: References

**Official Airtable Documentation (hardening and configuration):**
- [Settings — Airtable enterprise admin panel](https://support.airtable.com/docs/settings-airtable-enterprise-admin-panel) — the primary settings reference for security, sharing, AI, integrations, and retention
- [Admin Panel Overview](https://support.airtable.com/docs/overview-of-the-admin-panel)
- [Configuring SSO in the Admin Panel](https://support.airtable.com/docs/configuring-sso-in-the-admin-panel)
- [Enabling Two-Factor Authentication](https://support.airtable.com/docs/enabling-two-factor-authentication)
- [Accessing Enterprise Audit Logs](https://support.airtable.com/docs/accessing-enterprise-audit-logs-in-airtable)
- [Collaboration and Export Controls in the Admin Panel](https://support.airtable.com/docs/collaboration-export-controls-in-admin-panel)
- [App Sensitivity in the Admin Panel](https://support.airtable.com/docs/app-sensitivity-in-admin-panel)
- [Using Omni AI in Airtable](https://support.airtable.com/docs/using-omni-ai-in-airtable)
- [Domain Federation and Verification](https://support.airtable.com/docs/airtable-domain-federation-and-verification)
- [HIPAA and FERPA Compliance](https://support.airtable.com/docs/hipaa-and-ferpa-compliance)
- [DORA Compliance](https://support.airtable.com/docs/dora-compliance)
- [Airtable Support](https://support.airtable.com/)
- [Airtable Pricing](https://www.airtable.com/pricing) — current plan names and tiers

**API & Developer Tools:**
- [Airtable Web API Introduction](https://airtable.com/developers/web/api/introduction)
- [Airtable Developers Portal](https://airtable.com/developers)
- [airtable.js (JavaScript Client)](https://github.com/Airtable/airtable.js)
- [GitHub Organization](https://github.com/airtable)

**Compliance Frameworks:**
- SOC 2 Type II (annual audit) — available via account manager or sales@airtable.com
- ISO/IEC 27001:2022, ISO/IEC 27701:2019 (annual audits) — attested via Airtable's trust and security page, a compliance-attestation surface rather than a hardening document
- Airtable's [security practices](https://support.airtable.com/docs/airtable-security-practices) article corroborates platform-level protections but is a description of Airtable's own infrastructure, not administrator configuration guidance — it is not a hardening source
- TX-RAMP Level 2 certified
- GDPR, UK GDPR, CCPA/CPRA compliance
- 256-bit AES encryption at rest, 256-bit SSL/TLS in transit

**Security Incidents:**
- No major public security incidents identified as of early 2026.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass against support.airtable.com and airtable.com/pricing. Corrected plan naming to Free/Team/Business/Enterprise Scale, corrected SSO and SCIM to Business and Enterprise Scale, and refreshed the console paths for SSO, 2FA, IP restrictions, collaborator invites, sensitivity labels, and audit logs. Corrected audit logging (Reports → Audit log, Enterprise Scale, 180-day retention, 10,000-event UI cap) and made IP restrictions Enterprise Scale and request-gated. Added 2.4 admin panel access and roles, 2.5 EKM/custom terms/HIPAA, 3.4 Airtable AI and Omni governance, 3.5 data export controls, 3.6 share link and public interface restrictions, and 4.4 data retention. Rewrote 4.2 as API and integration security covering the Integrations & development settings. Added the changed-default callout that Airtable AI is on by default outside the EU. Fixed the missing Attack Prevented line in 2.1. Documented the sensitivity-label plan-tier conflict between two Tier 1 sources as both-with-callout per SOURCES.md. Removed the non-canonical /docs/enterprise-sso link and the trust-and-security and platform/governance marketing pages from Appendix B. Tier 2 (CIS/DISA/CISA SCuBA) publishes no Airtable baseline; Tier 3/4 research not surveyed this pass. | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, domain management, and collaboration controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
