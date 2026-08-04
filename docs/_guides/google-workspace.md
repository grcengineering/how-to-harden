---
layout: guide
title: "Google Workspace Hardening Guide"
vendor: "Google"
slug: "google-workspace"
platform: "Google Workspace"
platform_slug: "google-workspace"
product: "Common Controls"
tier: "1"
category: "Productivity"
description: "Platform-wide security hardening for Google Workspace — the Common Controls hub (authentication, OAuth, DLP engine, audit logging) shared by the Gmail, Google Drive, and Google Chat product guides."
version: "0.4.0"
maturity: "draft"
last_updated: "2026-08-03"
---

## Overview

Google Workspace is used by over **9 million organizations** worldwide for email, document collaboration, and cloud storage. As a primary target for phishing and credential theft, Google Workspace security is critical—phishing was responsible for financially devastating data breaches for 9/10 organizations in 2024. According to CISA, accounts with MFA enabled are 99% less likely to be compromised.

### Intended Audience
- Security engineers managing Google Workspace environments
- IT administrators configuring Admin Console security
- GRC professionals assessing cloud productivity compliance
- Third-party risk managers evaluating Google integrations

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Google Workspace Admin Console security configurations including authentication policies, OAuth app controls, Drive sharing settings, Gmail protection, Google Chat hardening, and device management. Google Cloud Platform (GCP) infrastructure is covered in a separate guide.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Network Access Controls](#2-network-access-controls)
3. [OAuth & Integration Security](#3-oauth--integration-security)
4. [Data Security](#4-data-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Third-Party Integration Security](#6-third-party-integration-security)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## Products in This Platform

Google Workspace is a multi-product platform. This guide is the **Common Controls hub** — the platform-wide controls that apply across every Google Workspace product. Product-specific controls live in their own guides:

| Product | Guide | Covers |
|---------|-------|--------|
| **Common Controls** (this guide) | — | Authentication & MFA, OAuth app allowlisting, the DLP engine, third-party integrations, admin audit logging |
| **Google Chat** | [Google Chat guide](/guides/google-chat/) | App & webhook allowlisting, external chat & spaces, file sharing, history & retention, Chat audit logging |
| **Google Drive** | [Google Drive guide](/guides/google-drive/) | External sharing restrictions, DLP-for-Drive |
| **Gmail** | [Gmail guide](/guides/gmail/) | Coming soon — controls not yet documented |

> **Moved controls:** the former §3.3 (Chat apps), §4.3–4.5 (Chat data), and §5.2 (Chat logging) now live in the **Google Chat** guide; the former §4.1 (Drive sharing) lives in the **Google Drive** guide. The DLP engine (§4.2) and admin audit logging (§5.1) remain here as platform-wide controls.

---

## 1. Authentication & Access Controls

### 1.1 Enforce Multi-Factor Authentication for All Users

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 6.5 |
| NIST 800-53 | IA-2(1), IA-2(6) |
| CIS Google Workspace | 1.1 |

#### Description
Require 2-Step Verification (2SV) for all users with enforcement, not just enrollment. Microsoft found that enabling MFA prevents 99.9% of automated attacks on cloud accounts.

#### Rationale
**Why This Matters:**
- Phishing remains the #1 attack vector against Google Workspace
- Password reuse and credential stuffing are common attack methods
- Accounts with MFA are 99% less likely to be compromised (CISA)

**Attack Prevented:** Credential theft, phishing, password spray, account takeover

**Real-World Incidents:**
- **Twitter (2020):** Compromised employee credentials led to high-profile account takeover
- **Colonial Pipeline (2021):** VPN credentials without MFA enabled ransomware deployment

#### Prerequisites
- Super Admin access to Google Admin Console
- User communication plan for 2SV enrollment
- Security keys for privileged users (recommended)

#### ClickOps Implementation

**Step 1: Enable 2-Step Verification Enrollment**
1. Navigate to: **Admin Console** → **Security** → **Authentication** → **2-Step Verification**
2. Check **Allow users to turn on 2-Step Verification**
3. Set **Enforcement** to **On** for all organizational units
4. Configure **New user enrollment period:** 7 days (grace period)
5. Click **Save**

**Step 2: Configure Allowed Methods**
1. In the same section, click **Allowed methods**
2. Select **Any except verification codes via text or phone call** (recommended)
3. This forces users to use authenticator apps or security keys instead of vulnerable SMS

**Step 3: Enforce Security Keys for Admins**
1. Navigate to: **Security** → **Authentication** → **2-Step Verification**
2. Select the Admin organizational unit
3. Set **Allowed methods** to **Only security key**
4. Click **Save**

**Time to Complete:** ~30 minutes

#### Code Implementation

#### Validation & Testing
**How to verify the control is working:**
1. Sign in as test user - 2SV prompt should appear
2. Check Admin Console → Reports → User Reports → Security
3. Verify 2SV enrollment percentage approaches 100%
4. Attempt sign-in with only password - should fail after enforcement

**Expected result:** All users prompted for second factor, enforcement active

#### Monitoring & Maintenance
**Ongoing monitoring:**
- Monitor Security → Investigation Tool for failed 2SV attempts
- Alert on suspicious sign-in attempts
- Track 2SV enrollment completion

**Admin Console Query:** Navigate to Security, then Investigation Tool. Set Event to Login, and filter by 2SV method = None, Login result = Success.

**Maintenance schedule:**
- **Weekly:** Review new user 2SV enrollment
- **Monthly:** Audit 2SV enforcement exceptions
- **Quarterly:** Review and rotate Super Admin security keys

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Low-Medium | Initial enrollment required; subsequent logins add ~5 seconds |
| **System Performance** | None | No performance impact |
| **Maintenance Burden** | Low | Minimal after initial rollout |
| **Rollback Difficulty** | Easy | Disable enforcement in Admin Console |

**Potential Issues:**
- Users without smartphones: Provide hardware security keys
- Shared device environments: Use security keys instead of mobile apps

**Rollback Procedure:**
1. Navigate to Admin Console → Security → 2-Step Verification
2. Set Enforcement to **Off**
3. Note: This leaves accounts vulnerable; use only for emergency troubleshooting

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | IA-2(1) | Multi-factor authentication |
| **ISO 27001** | A.9.4.2 | Secure log-on procedures |
| **CIS Google Workspace** | 1.1 | Ensure 2-Step Verification is enforced |

{% include pack-code.html vendor="google-workspace" section="1.1" %}

---

### 1.2 Restrict Super Admin Account Usage

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1), AC-6(5) |
| CIS Google Workspace | 1.2 |

#### Description
Limit Super Admin privileges to 2-4 dedicated accounts, enforce security keys for authentication, and use delegated admin roles for day-to-day administration.

#### Rationale
**Why This Matters:**
- Super Admin accounts have unrestricted access to all data and settings
- Compromised Super Admin = complete organization compromise
- Delegated roles follow principle of least privilege

**Attack Prevented:** Privilege escalation, lateral movement, admin account compromise

#### Prerequisites
- Inventory of current Super Admin accounts
- Security keys for all Super Admins
- Defined delegated admin roles

#### ClickOps Implementation

**Step 1: Audit Current Super Admins**
1. Navigate to: **Admin Console** → **Account** → **Admin roles**
2. Click **Super Admin** role
3. Review assigned users - should be 2-4 maximum
4. Document and remove unnecessary assignments

**Step 2: Create Delegated Admin Roles**
1. Navigate to: **Admin Console** → **Account** → **Admin roles**
2. Click **Create new role**
3. Create role-specific admins:
   - **User Admin:** Manage users, reset passwords
   - **Groups Admin:** Manage groups and memberships
   - **Help Desk Admin:** Reset passwords, view user info
4. Assign appropriate permissions for each role

**Step 3: Enforce Security Keys for Super Admins**
1. Create organizational unit: **Super Admins**
2. Move Super Admin accounts to this OU
3. Navigate to: **Security** → **2-Step Verification**
4. Select Super Admins OU
5. Set **Allowed methods** to **Only security key**

**Time to Complete:** ~45 minutes

#### Code Implementation

#### Validation & Testing
1. Verify only 2-4 Super Admin accounts exist
2. Confirm all Super Admins use security keys
3. Test delegated admin can perform assigned tasks only
4. Verify delegated admin cannot access Super Admin functions

{% include pack-code.html vendor="google-workspace" section="1.2" %}

---

### 1.3 Configure Context-Aware Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.4, 13.5 |
| NIST 800-53 | AC-2(11), AC-6(1) |

#### Description
Implement context-aware access policies that evaluate device, location, and user risk before granting access to Google Workspace applications.

#### Rationale
**Why This Matters:**
- Allows enforcement of device compliance before access
- Can block access from high-risk locations
- Provides additional layer beyond authentication

#### Prerequisites
- Google Workspace Enterprise Standard or Plus
- BeyondCorp Enterprise (for advanced features)
- Endpoint Verification deployed to managed devices

#### ClickOps Implementation

**Step 1: Deploy Endpoint Verification**
1. Navigate to: **Admin Console** → **Devices** → **Mobile & endpoints** → **Settings**
2. Enable **Endpoint Verification**
3. Deploy Chrome extension to managed devices
4. Or use Google's Endpoint Verification app for unmanaged devices

**Step 2: Create Access Level**
1. Navigate to: **Security** → **Access and data control** → **Context-Aware Access**
2. Click **Access Levels** → **Create Access Level**
3. Configure conditions:
   - Device must have Endpoint Verification
   - Device must be encrypted
   - Device must have screen lock
4. Save access level

**Step 3: Assign Access Level to Apps**
1. In Context-Aware Access, click **Assign Access Levels**
2. Select apps (Gmail, Drive, etc.)
3. Assign the created access level
4. Enable enforcement after testing

**Time to Complete:** ~1 hour

#### Code Implementation

{% include pack-code.html vendor="google-workspace" section="1.3" %}

---

### 1.4 Require Multi-Party Approvals for Sensitive Admin Actions

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.8 |
| NIST 800-53 | AC-3(2), AC-6(1) |

#### Description
Multi-party approvals (MPA) require a second Super Admin to approve a sensitive administrative change before it takes effect. Google shipped granular per-action controls in **June 2025**, letting you choose exactly which actions are gated instead of accepting a single all-or-nothing switch, and extended coverage to **Vault export creation in December 2025**. Gated actions include changes to 2-Step Verification enforcement, account recovery settings, domain-wide delegation grants, and the creation of Vault exports. Source: [More granular controls for multi-party approvals for sensitive admin actions](https://workspaceupdates.googleblog.com/2025/06/more-granular-controls-for-multi-party-approvals-for-sensitive-admin-actions.html).

#### Rationale
**Why This Matters:**
- A single compromised Super Admin is otherwise sufficient to disable 2SV enforcement tenant-wide, which unwinds [1.1](#11-enforce-multi-factor-authentication-for-all-users) in one click and leaves no approval trail
- Domain-wide delegation is the most valuable persistence mechanism in Google Workspace — a delegated service account can impersonate any user without triggering a user-facing sign-in, so gating the grant is far cheaper than detecting its abuse afterward
- Vault export creation is a bulk data-exfiltration primitive with a legitimate business purpose, which makes it hard to alert on; requiring a second approver converts it from a silent action into a reviewed one
- Account recovery changes are the classic path back in after a credential reset, and attackers modify them precisely because they are rarely monitored
- Granular per-action selection means you can gate the four highest-blast-radius operations without adding friction to routine user administration

**Attack Prevented:** Single-admin compromise leading to tenant-wide MFA rollback, covert domain-wide delegation for persistence, silent bulk data export via Vault, account-recovery hijacking

#### Prerequisites
- Google Workspace Enterprise Standard or Plus, Education Standard or Plus, or Cloud Identity Premium
- At least two Super Admin accounts (MPA cannot function with a single Super Admin)
- Both Super Admins enrolled in 2-Step Verification, ideally with security keys per [1.2](#12-restrict-super-admin-account-usage)
- A documented break-glass procedure for the case where the second approver is unavailable

#### ClickOps Implementation

**Step 1: Confirm Approver Coverage**
1. Navigate to: **Admin Console** → **Account** → **Admin roles**
2. Confirm at least two active Super Admin accounts exist and that both are reachable through separate communication channels
3. Do not enable MPA against a single Super Admin — you will lock yourself out of the gated actions

**Step 2: Enable Multi-Party Approvals**
1. Navigate to: **Admin Console** → **Account** → **Account settings** → **Multi-party approvals**
2. Set the feature to **On**
3. Click **Save**

**Step 3: Select Which Actions Require Approval**
1. In the same **Multi-party approvals** panel, review the per-action list
2. Enable approval for, at minimum:
   - **2-Step Verification** setting changes
   - **Account recovery** setting changes
   - **Domain-wide delegation** grants
   - **Vault export** creation
3. Leave lower-risk actions ungated so routine administration is not blocked
4. Click **Save**

**Step 4: Brief Your Admins on the Approval Flow**
1. Explain that a gated change enters a pending state and notifies other Super Admins rather than applying immediately
2. Establish an expected approval turnaround so legitimate changes are not stalled
3. Document how to identify and reject an approval request that no admin recognizes — an unexpected request is a compromise signal, not a formality

**Time to Complete:** ~30 minutes

#### Validation & Testing
**How to verify the control is working:**
1. As Super Admin A, attempt a gated change — for example, modifying 2SV enforcement on a test organizational unit
2. Confirm the change does not apply immediately and enters a pending-approval state
3. Confirm Super Admin B receives an approval request
4. Reject the request and confirm the original setting is unchanged
5. Repeat with approval and confirm the change applies only after the second admin approves
6. Review **Reporting** → **Audit and investigation** → **Admin log events** and confirm both the request and the approval decision are recorded

**Expected result:** Gated actions cannot be completed by a single administrator, and every request and decision is captured in the admin audit log

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | None | Affects administrators only; end users see no change |
| **System Performance** | None | No performance impact |
| **Maintenance Burden** | Low-Medium | Requires a reachable second approver and an agreed turnaround time |
| **Rollback Difficulty** | Easy | Disable in Account settings, though disabling may itself be a gated action |

**Potential Issues:**
- Single-Super-Admin tenants cannot use MPA — provision a second Super Admin first
- Time-sensitive incident response can be delayed if the second approver is unreachable; agree on an on-call rotation before enabling

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.3 | Access modification authorization |
| **NIST 800-53** | AC-3(2) | Dual authorization for privileged actions |
| **NIST 800-53** | AC-6(1) | Least privilege |
| **ISO 27001** | A.5.15 | Access control |

---

## 2. Network Access Controls

### 2.1 Configure Allowed IP Ranges for Admin Console

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17, SC-7 |

#### Description
Restrict Admin Console access to specific IP ranges (corporate network, VPN) to prevent unauthorized administrative access.

#### Rationale
**Why This Matters:**
- The Admin Console holds the keys to the entire tenant, so binding it to corporate egress IPs or VPN ranges makes a stolen admin credential useless from an attacker's network
- A network-location gate layers on top of authentication and MFA, shrinking the exposure window for credential stuffing and password spray that originate from arbitrary internet locations
- Session reauthentication controls force admins to re-prove identity for sensitive operations even if a session is hijacked

**Attack Prevented:** Stolen-credential admin access from untrusted networks, remote admin takeover, credential stuffing and password spray from external IPs

#### ClickOps Implementation

**Step 1: Configure Allowed IPs**
1. Navigate to: **Admin Console** → **Security** → **Access and data control** → **Context-Aware Access**
2. Create access level with IP conditions
3. Specify corporate egress IP ranges
4. Apply to Admin Console access

**Step 2: Alternative - Session Control**
1. Navigate to: **Security** → **Google Cloud session control**
2. Configure reauthentication frequency for sensitive apps

#### Code Implementation

{% include pack-code.html vendor="google-workspace" section="2.1" %}

---

## 3. OAuth & Integration Security

### 3.1 Enable OAuth App Whitelisting

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5 |
| NIST 800-53 | AC-3, CM-7 |
| CIS Google Workspace | 2.1 |

#### Description
Restrict which third-party applications can access Google Workspace data via OAuth. Block unverified apps and require admin approval for new integrations.

#### Rationale
**Why This Matters:**
- OAuth consent phishing is a growing attack vector
- Malicious apps can gain persistent access to email and files
- Users often grant excessive permissions without understanding risks

**Attack Prevented:** OAuth consent phishing, malicious app installation, data exfiltration

**Real-World Incidents:**
- **Google Docs Phishing (2017):** Fake "Google Docs" app tricked users into granting email access
- Multiple incidents of data-stealing apps masquerading as productivity tools

#### Prerequisites
- Inventory of currently authorized OAuth apps
- Business justification for each approved app
- User communication about approval process

#### ClickOps Implementation

**Step 1: Review Current OAuth Apps**
1. Navigate to: **Admin Console** → **Security** → **API controls** → **App access control**
2. Click **Manage Third-Party App Access**
3. Review list of apps with access to organizational data
4. Document apps that should be allowed

**Step 2: Configure App Whitelisting**
1. In **App access control**, click **Settings**
2. Set default policy: **Block all third-party API access** or **Block unconfigured third-party apps**
3. Configure trusted apps list
4. Click **Save**

**Step 3: Whitelist Approved Apps**
1. Click **Add app** → **OAuth App Name or Client ID**
2. Search for app or enter Client ID
3. Configure access level:
   - **Trusted:** Full access to requested scopes
   - **Limited:** Access to only non-sensitive scopes
   - **Blocked:** No access
4. Add business justification
5. Click **Configure**

**Time to Complete:** ~1 hour (initial configuration), ongoing for new app requests

#### Code Implementation

#### Validation & Testing
1. Verify blocked apps cannot access data
2. Test app approval workflow
3. Review Security Investigation Tool for blocked app attempts
4. Confirm whitelisted apps function correctly

**Expected result:** Only approved apps can access organizational data

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | AC-3 | Access enforcement |
| **CIS Google Workspace** | 2.1 | Ensure third-party apps are audited and controlled |

{% include pack-code.html vendor="google-workspace" section="3.1" %}

---

### 3.2 Retire Legacy App Access (Less Secure Apps & App Passwords)

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.2 |
| NIST 800-53 | IA-2, CM-7 |

#### Description
Less Secure Apps (LSA) — the setting that let applications sign in with only a username and password, bypassing 2-Step Verification — no longer exists. Google completed the platform-wide removal of LSA support on **May 1, 2025**, and the **Security → Less secure apps** page has been retired from the Admin Console. There is nothing left to toggle. What remains for administrators is the residual legacy-access surface: **app passwords** issued before the cutover, and OAuth clients that inherited the access those legacy connections used to provide. Source: [Control access to less secure apps](https://knowledge.workspace.google.com/admin/apps/control-access-to-less-secure-apps).

If you are working from an older checklist or a prior version of this guide that instructs you to navigate to **Security → Less secure apps**, treat that step as complete-by-platform rather than as an outstanding gap — the migration was performed by Google, not by your tenant.

#### Rationale
**Why This Matters:**
- LSA removal closed the largest MFA-bypass path in Google Workspace, but it did not revoke the app passwords users generated while LSA was still supported — those credentials are single-factor by design and survive the deprecation
- An app password grants mail and calendar access without ever presenting a 2SV challenge, so a leaked one defeats the enforcement you configured in [1.1](#11-enforce-multi-factor-authentication-for-all-users)
- Integrations that used to authenticate over basic credentials were migrated to OAuth, which moves the risk rather than eliminating it — the same vendor now holds a token with explicit scopes, and those scopes need the same governance as any other third-party app
- Auditing a control that no longer exists wastes assessment effort and produces false findings; auditing the credentials the deprecation left behind produces real ones

**Attack Prevented:** MFA bypass via residual single-factor app passwords, persistent access by legacy integrations that were never re-reviewed after the OAuth migration, password spray against legacy authentication paths

#### ClickOps Implementation

**Step 1: Confirm the Legacy Setting Is Gone**
1. Navigate to: **Admin Console** → **Security** → **Access and data control**
2. Confirm no **Less secure apps** entry is present — its absence is the expected state on every tenant, and it is not a misconfiguration
3. Record this in your control evidence as "removed by vendor, effective 2025-05-01" so future assessments do not re-open it

**Step 2: Audit and Remove Outstanding App Passwords**
1. Navigate to: **Admin Console** → **Directory** → **Users**
2. Open an individual user, then select **Security**
3. Review **App passwords** — the panel shows the count of active app passwords for that account
4. Click **Revoke all** for any user who no longer needs a legacy client, prioritizing Super Admins and other privileged accounts
5. For a tenant-wide view, run a **Reporting** → **Audit and investigation** → **Token log events** search and look for authentications that are not attributable to an approved OAuth client

**Step 3: Govern the OAuth Access That Replaced It**
1. Work through [3.1 Enable OAuth App Whitelisting](#31-enable-oauth-app-whitelisting) — the app access control policy defined there is now the enforcement point for every integration that previously relied on basic credentials
2. In **Security** → **API controls** → **App access control**, review any app added during the LSA migration window and confirm it still has a business owner and a justification
3. Set the default policy to block unconfigured third-party apps so no migrated integration silently retains access

**Time to Complete:** ~45 minutes

#### Validation & Testing
**How to verify the control is working:**
1. Confirm the **Less secure apps** page returns no result in Admin Console search — this is the expected post-deprecation state
2. Pick a sample of privileged users and confirm the **App passwords** count is zero on each
3. Attempt an IMAP or SMTP sign-in using a plain account password against a test account — it should fail, because basic authentication is no longer accepted
4. Cross-check the approved OAuth app list against your integration inventory and confirm no unowned app remains from the migration

**Expected result:** No legacy-app setting exists, no residual app passwords remain on privileged accounts, and every surviving integration is an explicitly approved OAuth client

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | IA-2 | Identification and authentication of organizational users |
| **NIST 800-53** | CM-7 | Least functionality — removal of legacy authentication paths |
| **ISO 27001** | A.9.4.2 | Secure log-on procedures |

---

## 4. Data Security

### 4.2 Enable Data Loss Prevention (DLP)

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1, 3.2 |
| NIST 800-53 | SC-8, SC-28 |

#### Description
Configure Google Workspace DLP rules to detect and prevent sharing of sensitive information like credit cards, SSNs, and confidential documents.

#### Rationale
**Why This Matters:**
- Sensitive data such as PII, financial records, and secrets routinely leaks through Drive and Chat sharing, most often by accident rather than malice
- DLP enforces policy at the moment of sharing, blocking external exposure or warning users before regulated data leaves the organization
- Automated content inspection with predefined detectors and OCR on images catches sensitive content that manual review and user judgment miss
- Rule matches generate admin alerts and audit evidence that privacy and compliance regimes require

**Attack Prevented:** Data exfiltration, accidental oversharing of PII and financial data, insider data leakage, compliance violations

#### Prerequisites
- Google Workspace Enterprise Standard or Plus
- Defined sensitive data types for your organization

#### ClickOps Implementation

**Step 1: Access DLP Settings**
1. Navigate to: **Admin Console** → **Security** → **Access and data control** → **Data protection**
2. Click **Manage Rules**

**Step 2: Create DLP Rule**
1. Click **Create rule**
2. Configure:
   - **Name:** Block sharing of PII
   - **Scope:** Entire organization or specific OUs
   - **Apps:** Drive, Chat
   - **Conditions:** Content matches predefined detectors (SSN, Credit Card, etc.)
   - **Actions:** Block external sharing, warn user, alert admin
3. Save and enable rule

#### Code Implementation

{% include pack-code.html vendor="google-workspace" section="4.2" %}

> **Google Chat DLP:** The same data protection rules apply to Chat messages and attachments. When creating a rule, set **Apps** to **Chat**, choose the conversation type (**internal** or **external**), and enable OCR to scan images. Attachments over 50 MB are sent without scanning. See [Chat 2.2](/guides/google-chat/#22-restrict-google-chat-file-sharing) to also cap what file types can be shared.

---

### 4.3 Govern AI and Agent Access with the AI Control Center

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 6.8 |
| NIST 800-53 | AC-3, AC-4, SC-28 |

#### Description
The AI control center is the single Admin Console surface for governing how Gemini and other AI agents reach Workspace data. It reached general availability in **May 2026** for Enterprise Standard and Enterprise Plus. It combines service-level Gemini controls, classification labels paired with trust rules and data-protection rules that constrain what AI can surface, and centralized visibility into AI usage across the tenant. Source: [Securely manage AI and agent access to Workspace data with the AI control center](https://workspaceupdates.googleblog.com/2026/05/securely-manage-AI-and-agent-access-to-Workspace-data-with-the-AI-control-center.html).

#### Rationale
**Why This Matters:**
- AI assistants inherit the permissions of the user invoking them, which means existing oversharing inside Drive becomes retrievable on demand rather than merely discoverable — a document a user technically could have found is now something an assistant will summarize for them unprompted
- Agent access is a new integration surface with the same supply-chain properties as OAuth apps: a third-party agent granted broad scopes can read across mailboxes and drives continuously, without the visible interaction pattern that makes human exfiltration noticeable
- Classification labels combined with trust rules let you mark sensitive content once and have every AI surface honor that boundary, rather than re-authoring exclusion logic per product
- Without centralized usage visibility, AI adoption inside a tenant is invisible to security teams until an incident forces an inventory
- Service-level controls let you stage rollout by organizational unit, so regulated teams can be excluded while the rest of the organization proceeds

**Attack Prevented:** AI-assisted discovery and exfiltration of overshared internal data, third-party agent overreach into mailboxes and drives, inadvertent exposure of regulated content through AI summarization, unsanctioned shadow-AI usage

#### Prerequisites
- Google Workspace Enterprise Standard or Enterprise Plus
- Super Admin access to the Admin Console
- A defined data classification scheme, and DLP configured per [4.2](#42-enable-data-loss-prevention-dlp)
- An inventory of AI tools and agents already in use, cross-referenced against the OAuth app list from [3.1](#31-enable-oauth-app-whitelisting)

#### ClickOps Implementation

**Step 1: Open the AI Control Center**
1. Navigate to: **Admin Console** → **Generative AI** → **AI control center**
2. Review the usage overview to establish a baseline of which AI features are already active and in which organizational units

**Step 2: Set Service-Level Gemini Controls**
1. In the AI control center, open the service controls for Gemini
2. Enable or disable each AI service per organizational unit, starting restrictive and expanding after review
3. Exclude organizational units that handle regulated data until a data-protection rule covering that data is in place
4. Click **Save**

**Step 3: Apply Classification Labels and Trust Rules**
1. Confirm your classification labels are defined under **Security** → **Access and data control**
2. In the AI control center, create trust rules that prevent labeled content from being surfaced by AI features
3. Pair each trust rule with a data-protection rule so the same classification drives both DLP enforcement and AI exclusion
4. Verify that the labels applied to your most sensitive Drive content actually match the rule conditions

**Step 4: Govern Third-Party Agent Access**
1. Review the agents and AI integrations listed in the control center
2. For each, confirm there is a business owner and that its scopes match its stated function
3. Remove or block any agent that cannot be attributed to an owner
4. Route all new agent requests through the same approval workflow as OAuth apps in [3.1](#31-enable-oauth-app-whitelisting)

**Step 5: Establish Ongoing Review**
1. Use the centralized usage visibility to track adoption by organizational unit
2. Set a recurring review to catch newly enabled AI features and newly granted agents

**Time to Complete:** ~1.5 hours

#### Validation & Testing
**How to verify the control is working:**
1. As a test user in an organizational unit where Gemini is disabled, confirm the AI features are unavailable
2. Apply a sensitive classification label to a test document, then ask an AI feature a question whose answer lives in that document — confirm the content is not surfaced
3. Remove the label and confirm the content becomes available again, proving the trust rule is the operative gate rather than a permissions accident
4. Confirm that a blocked agent can no longer retrieve Workspace data
5. Check the usage view and confirm activity is being recorded for the organizational units where AI is enabled

**Expected result:** AI features are available only where explicitly enabled, labeled content is excluded from AI surfacing, and every active agent is attributable to an owner

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Medium | Users in restricted organizational units lose access to AI features they may already rely on |
| **System Performance** | None | No performance impact |
| **Maintenance Burden** | Medium | Labels and trust rules need upkeep as classification schemes evolve |
| **Rollback Difficulty** | Easy | Re-enable services or disable trust rules in the AI control center |

**Potential Issues:**
- Requires Enterprise Standard or Enterprise Plus; lower editions have no equivalent surface
- Trust rules are only as good as label coverage — unlabeled sensitive content remains reachable by AI

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **SOC 2** | CC6.7 | Restriction of information transmission |
| **NIST 800-53** | AC-3 | Access enforcement |
| **NIST 800-53** | AC-4 | Information flow enforcement |
| **ISO 27001** | A.5.12 | Classification of information |

---

## 5. Monitoring & Detection

### 5.1 Enable Audit Logging and Investigation Tool

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-3, AU-6 |
| CIS Google Workspace | 5.1 |

#### Description
Enable and configure audit logging across all Google Workspace services. Use the Security Investigation Tool for threat detection and incident response.

#### Rationale
**Why This Matters:**
- Audit logs are essential for incident investigation
- Provides visibility into admin actions, file access, and sign-in events
- Required for compliance with most security frameworks

#### ClickOps Implementation

**Step 1: Verify Audit Logging**
1. Navigate to: **Admin Console** → **Reporting** → **Audit and investigation**
2. Verify logs are being captured for:
   - Admin activities
   - Login activities
   - Drive activities
   - Token activities
   - Rules activities

**Step 2: Configure Audit Log Exports**
1. Navigate to: **Reporting** → **Audit and investigation** → **Export to BigQuery**
2. Enable export to BigQuery for long-term retention
3. Configure retention period

**Step 3: Create Alert Rules**
1. Navigate to: **Security** → **Alert center** → **Configure alerts**
2. Enable critical alerts:
   - Suspicious login
   - Government-backed attack
   - Device compromised
   - Super Admin added

**Time to Complete:** ~30 minutes

#### Key Events to Monitor

| Event | Log Source | Detection Use Case |
|-------|------------|-------------------|
| `CHANGE_PASSWORD` | Admin | Unauthorized password resets |
| `GRANT_ADMIN_ROLE` | Admin | Privilege escalation |
| `CREATE_APPLICATION_SETTING` | Admin | OAuth app approval |
| `LOGIN_FAILURE` | Login | Brute force attempts |
| `SUSPICIOUS_LOGIN` | Login | Account compromise |
| `DOWNLOAD` | Drive | Data exfiltration |

#### Code Implementation

{% include pack-code.html vendor="google-workspace" section="5.1" %}

---

## 6. Third-Party Integration Security

### 6.1 Integration Risk Assessment Matrix

| Risk Factor | Low | Medium | High |
|-------------|-----|--------|------|
| **Data Access** | Read-only, limited scope | Read most data | Write access, full API |
| **OAuth Scopes** | Specific scopes | Broad API access | Full admin/Gmail access |
| **Session Duration** | Short-lived tokens | Refresh tokens | Offline access |
| **Vendor Security** | SOC 2 Type II + ISO | SOC 2 Type I | No certification |

### 6.2 Common Integrations and Recommended Controls

#### Obsidian Security
**Data Access:** Read (Gmail metadata, Drive metadata, audit logs)
**Recommended Controls:**
- ✅ Use dedicated service account
- ✅ Grant minimum required OAuth scopes
- ✅ Review access quarterly
- ✅ Monitor API usage via Reports

#### Slack
**Data Access:** Medium (Google Calendar, Drive file links)
**Recommended Controls:**
- ✅ Approve specific scopes only
- ✅ Limit to approved workspaces
- ✅ Monitor for unusual activity

---

## 7. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Google Workspace Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | MFA for all users | [1.1](#11-enforce-multi-factor-authentication-for-all-users) |
| CC6.1 | OAuth app controls | [3.1](#31-enable-oauth-app-whitelisting) |
| CC6.1 | Legacy app access retirement | [3.2](#32-retire-legacy-app-access-less-secure-apps--app-passwords) |
| CC6.2 | Super Admin restrictions | [1.2](#12-restrict-super-admin-account-usage) |
| CC6.3 | Multi-party approvals for sensitive admin actions | [1.4](#14-require-multi-party-approvals-for-sensitive-admin-actions) |
| CC6.6 | External sharing restrictions | [Drive 1.1](/guides/google-drive/#11-configure-external-drive-sharing-restrictions) |
| CC6.7 | AI and agent access governance | [4.3](#43-govern-ai-and-agent-access-with-the-ai-control-center) |
| CC6.6 | Chat external & file-sharing restrictions | [Chat 2.1](/guides/google-chat/#21-restrict-external-google-chat--spaces), [Chat 2.2](/guides/google-chat/#22-restrict-google-chat-file-sharing) |
| CC7.2 | Audit logging | [5.1](#51-enable-audit-logging-and-investigation-tool) |
| CC7.2 | Chat audit logging & content reporting | [Chat 3.1](/guides/google-chat/#31-enable-google-chat-audit-logging--content-reporting) |

### NIST 800-53 Rev 5 Mapping

| Control | Google Workspace Control | Guide Section |
|---------|------------------|---------------|
| IA-2(1) | MFA enforcement | [1.1](#11-enforce-multi-factor-authentication-for-all-users) |
| AC-6(1) | Least privilege admin | [1.2](#12-restrict-super-admin-account-usage) |
| AC-3(2) | Dual authorization for sensitive admin actions | [1.4](#14-require-multi-party-approvals-for-sensitive-admin-actions) |
| AC-3 | OAuth app control | [3.1](#31-enable-oauth-app-whitelisting) |
| CM-7 | Legacy authentication path removal | [3.2](#32-retire-legacy-app-access-less-secure-apps--app-passwords) |
| AC-4 | Information flow enforcement for AI and agents | [4.3](#43-govern-ai-and-agent-access-with-the-ai-control-center) |
| CM-7 | Chat app restriction | [Chat 1.1](/guides/google-chat/#11-restrict--allowlist-google-chat-apps) |
| AC-20 | Chat external messaging | [Chat 2.1](/guides/google-chat/#21-restrict-external-google-chat--spaces) |
| AU-9 | Chat history protection | [Chat 2.3](/guides/google-chat/#23-enforce-google-chat-history--retention) |
| AU-2 | Audit logging | [5.1](#51-enable-audit-logging-and-investigation-tool) |
| IR-6 | Chat content reporting | [Chat 3.1](/guides/google-chat/#31-enable-google-chat-audit-logging--content-reporting) |

### CIS Google Workspace Foundations Benchmark v1.3.0 Mapping

The recommendation IDs below are drawn from the **CIS Google Workspace Foundations Benchmark v1.3.0**. CIS renumbers recommendations between releases, so an ID that matches here will not necessarily match in v1.2.0 or a future v1.4.0 — always confirm the ID against the benchmark revision your auditor is using rather than assuming continuity. Download the current revision from [CIS Google Workspace Benchmark](https://www.cisecurity.org/benchmark/google_workspace).

| Recommendation | Google Workspace Control | Guide Section |
|---------------|------------------|---------------|
| 1.1 | Ensure 2SV is enforced | [1.1](#11-enforce-multi-factor-authentication-for-all-users) |
| 1.2 | Limit Super Admin accounts | [1.2](#12-restrict-super-admin-account-usage) |
| 2.1 | Control third-party apps | [3.1](#31-enable-oauth-app-whitelisting) |
| 3.1 | Restrict external sharing | [Drive 1.1](/guides/google-drive/#11-configure-external-drive-sharing-restrictions) |
| 3.1.4.2.2 | Restrict Google Chat externally to allowlisted domains | [Chat 2.1](/guides/google-chat/#21-restrict-external-google-chat--spaces) |

Controls [1.4](#14-require-multi-party-approvals-for-sensitive-admin-actions) and [4.3](#43-govern-ai-and-agent-access-with-the-ai-control-center) cover Google features that postdate v1.3.0 and have no corresponding CIS recommendation ID yet.

### CISA SCuBA Secure Configuration Baseline Mapping

CISA publishes Secure Configuration Baselines for Google Workspace and ships [ScubaGoggles](https://github.com/cisagov/ScubaGoggles), an open-source assessment tool that evaluates a live tenant against those baselines and produces a pass/fail report. The GWS Common Controls baseline is the one that overlaps this guide, and running ScubaGoggles is the fastest way to get independent evidence that these controls are actually in effect rather than merely documented.

| SCuBA Baseline Area | ScubaGoggles Checks | Guide Section |
|---------------------|---------------------|---------------|
| GWS Common Controls — 2SV enforcement | Verifies 2-Step Verification is enforced and that allowed methods exclude SMS and voice | [1.1](#11-enforce-multi-factor-authentication-for-all-users) |
| GWS Common Controls — account recovery restrictions | Verifies self-service account recovery is disabled for administrators and users | [1.2](#12-restrict-super-admin-account-usage), [1.4](#14-require-multi-party-approvals-for-sensitive-admin-actions) |
| GWS Common Controls — break-glass configuration | Verifies a documented emergency-access account exists and is appropriately constrained | [1.2](#12-restrict-super-admin-account-usage) |
| GWS Common Controls — post-SSO verification | Verifies additional verification is applied after SSO sign-in so a compromised IdP session is not sufficient on its own | [1.1](#11-enforce-multi-factor-authentication-for-all-users), [1.3](#13-configure-context-aware-access) |
| GWS Common Controls — third-party app access | Verifies app access control blocks unconfigured third-party applications | [3.1](#31-enable-oauth-app-whitelisting) |

## Appendix A: Edition/Tier Compatibility

| Control | Business Starter | Business Standard | Business Plus | Enterprise Standard | Enterprise Plus |
|---------|------------------|-------------------|---------------|---------------------|-----------------|
| 2-Step Verification | ✅ | ✅ | ✅ | ✅ | ✅ |
| Security Keys enforcement | ✅ | ✅ | ✅ | ✅ | ✅ |
| OAuth app whitelisting | ❌ | ✅ | ✅ | ✅ | ✅ |
| Context-Aware Access | ❌ | ❌ | ✅ | ✅ | ✅ |
| Multi-party approvals | ❌ | ❌ | ❌ | ✅ | ✅ |
| AI control center | ❌ | ❌ | ❌ | ✅ | ✅ |
| Data Loss Prevention | ❌ | ❌ | ❌ | ❌ | ✅ |
| Security Investigation Tool | ❌ | ❌ | ❌ | ✅ | ✅ |
| BigQuery export | ❌ | ❌ | ❌ | ✅ | ✅ |
| Google Chat external & spaces restrictions | ✅ | ✅ | ✅ | ✅ | ✅ |
| Google Chat history & content reporting | ✅ | ✅ | ✅ | ✅ | ✅ |
| Google Chat file-sharing & app controls | ✅ | ✅ | ✅ | ✅ | ✅ |
| Vault retention/holds for Chat | ❌ | ❌ | ✅ | ✅ | ✅ |

---

## Appendix B: References

**Official Google Documentation:**
- [Google Workspace Admin Help](https://knowledge.workspace.google.com/)
- [Security checklist for medium and large businesses](https://knowledge.workspace.google.com/admin/security/security-checklist-for-medium-and-large-businesses-100-users)
- [Control access to less secure apps (LSA removal, effective 2025-05-01)](https://knowledge.workspace.google.com/admin/apps/control-access-to-less-secure-apps)
- [Google Cloud MFA Requirement](https://docs.cloud.google.com/docs/authentication/mfa-requirement)
- [Data Protection and Compliance](https://business.safety.google/compliance/)
- [Compliance Reports Manager](https://cloud.google.com/security/compliance/compliance-reports-manager)

> **Documentation domain migration:** Google moved Workspace admin documentation from `support.google.com/a` to `knowledge.workspace.google.com`. Old article-ID links mostly redirect, but some retired articles land on the domain homepage instead of equivalent content — if you follow a `support.google.com/a/answer/NNNNNNN` link from an older checklist and arrive at a generic page, the article was retired rather than moved. Google Vault documentation has not migrated and still lives on `support.google.com/vault`.

**Admin Console Feature Announcements:**
- [More granular controls for multi-party approvals for sensitive admin actions (June 2025)](https://workspaceupdates.googleblog.com/2025/06/more-granular-controls-for-multi-party-approvals-for-sensitive-admin-actions.html)
- [Securely manage AI and agent access to Workspace data with the AI control center (May 2026)](https://workspaceupdates.googleblog.com/2026/05/securely-manage-AI-and-agent-access-to-Workspace-data-with-the-AI-control-center.html)

**Google Chat Hardening:**
- [Control external Chat & spaces chat options](https://knowledge.workspace.google.com/admin/chat/control-external-chat-and-spaces-chat-options)
- [Allow users to install Chat apps](https://knowledge.workspace.google.com/admin/chat/allow-users-to-install-chat-apps)
- [Control file sharing in Chat](https://knowledge.workspace.google.com/admin/chat/control-file-sharing-in-chat)
- [Turn chat history on or off for users](https://knowledge.workspace.google.com/admin/chat/turn-chat-history-on-or-off-for-an-organization)
- [Set a space history option for users](https://knowledge.workspace.google.com/admin/chat/set-a-space-history-option-for-users)
- [Prevent data leaks from Chat messages & attachments (DLP)](https://knowledge.workspace.google.com/admin/security/prevent-data-leaks-from-chat-messages-and-attachments)
- [Chat log events](https://knowledge.workspace.google.com/admin/reports/chat-log-events)
- [Chat Audit Activity Events (Reports API)](https://developers.google.com/workspace/admin/reports/v1/appendix/activity/chat)
- [Retain Google Chat messages with Vault](https://support.google.com/vault/answer/7657597)
- [Vault API — manage holds (HANGOUTS_CHAT corpus)](https://developers.google.com/workspace/vault/guides/holds)

**API & Developer Tools:**
- [Google Workspace Developer Hub](https://developers.google.com/workspace)
- [Admin SDK API Reference](https://developers.google.com/admin-sdk)
- [GAM - Google Workspace Admin CLI](https://github.com/GAM-team/GAM)

**Compliance Frameworks:**
- SOC 2 Type II, SOC 3, ISO/IEC 27001:2022, ISO 27017, ISO 27018, ISO 27701, FedRAMP (High), BSI C5, MTCS -- via [Compliance Reports Manager](https://cloud.google.com/security/compliance/compliance-reports-manager)
- [ISO/IEC 27001 Compliance](https://cloud.google.com/security/compliance/iso-27001)
- [SOC 2 Compliance](https://cloud.google.com/security/compliance/soc-2)

**Security Incidents:**
- Google Workspace has not had a major platform-level breach. Notable ecosystem incidents include the **Google Docs OAuth Phishing Attack (2017)**, where a fake "Google Docs" app tricked users into granting email access via OAuth consent.

**Third-Party Security Guides:**
- [CISA Google Common Controls](https://www.cisa.gov/resources-tools/services/gws-commoncontrols)
- [CISA SCuBA Secure Configuration Baseline for Google Chat](https://www.cisa.gov/resources-tools/services/gws-chat)
- [CISA ScubaGoggles (GWS assessment tool & baselines)](https://github.com/cisagov/ScubaGoggles) — run against a live tenant to validate the Common Controls baseline items mapped in §7
- [CIS Google Workspace Benchmark](https://www.cisecurity.org/benchmark/google_workspace) — §7 maps to **v1.3.0**; recommendation IDs shift between releases, so confirm against the revision your auditor uses

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-03 | 0.4.0 | draft | Currency pass. Rewrote §3.2 — Less Secure Apps was fully removed by Google on 2025-05-01 and the Admin Console page no longer exists, so the control is now "Retire Legacy App Access (Less Secure Apps & App Passwords)" covering residual app-password auditing and OAuth governance. Added §1.4 multi-party approvals for sensitive admin actions (2SV changes, account recovery, domain-wide delegation, Vault export creation) and §4.3 AI control center for Gemini and agent access governance (GA May 2026, Enterprise Standard/Plus). Migrated 9 `support.google.com/a` citations to `knowledge.workspace.google.com`. Labeled the CIS mapping as Foundations Benchmark v1.3.0 with a note that IDs shift between releases, and added a CISA SCuBA / ScubaGoggles baseline mapping table. | Claude Code (Sonnet 5) |
| 2026-06-29 | 0.3.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2026-05-29 | 0.3.0 | draft | Restructured Google Workspace into a multi-product platform (GRC-496): split Google Chat into the [google-chat](/guides/google-chat/) guide and Google Drive into the [google-drive](/guides/google-drive/) guide; this guide is now the Common Controls hub (authentication, OAuth, DLP engine, admin audit logging). Added a Gmail product stub. Repointed cross-references and compliance tables to the product guides; reorganized code packs into packs/google-chat and packs/google-drive. | Jai (PAI) |
| 2026-05-28 | 0.2.0 | draft | Added Google Chat hardening: app/webhook allowlisting (3.3), external chat & spaces restrictions (4.3), Chat file sharing (4.4), history & Vault retention (4.5), and Chat audit logging & content reporting (5.2). Mapped to CISA SCuBA GWS.CHAT baseline; added Chat code packs and references. | Claude Code (Opus 4.7) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with authentication, OAuth, data security, and monitoring controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
