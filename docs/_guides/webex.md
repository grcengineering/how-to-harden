---
layout: guide
title: "Webex Hardening Guide"
vendor: "Webex"
slug: "webex"
tier: "2"
category: "Productivity"
description: "Enterprise collaboration hardening for Cisco Webex including meeting security, SSO configuration, and admin controls"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-08-08"
---

## Overview

Cisco Webex is a leading enterprise collaboration platform providing video conferencing, messaging, and calling for **millions of users** worldwide. As a critical communication tool handling sensitive business discussions and data, Webex security configurations directly impact confidentiality and compliance with data protection requirements.

### Intended Audience
- Security engineers managing collaboration platforms
- IT administrators configuring Webex
- GRC professionals assessing communication security
- Meeting administrators managing site settings

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Webex Control Hub and Site Administration security including meeting security, SSO, user management, and data protection.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Meeting Security](#2-meeting-security)
3. [Admin & Site Security](#3-admin--site-security)
4. [Data Protection](#4-data-protection)
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
Configure SAML SSO to centralize authentication for Webex applications.

#### Rationale
**Why This Matters:**
- Centralizes Webex authentication in your corporate IdP so MFA, conditional access, and session policies apply to every login
- Standalone Webex passwords bypass IdP controls and are a prime target for credential stuffing and phishing
- A single sign-on point lets you revoke access across meetings, messaging, and calling instantly when an employee leaves
- Webex carries sensitive business discussions and recordings, so one compromised local login can expose all of it

**Attack Prevented:** Credential theft, phishing, credential stuffing, password reuse, orphaned-account access

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Control Hub** → **Management** → **Organization Settings** → **Authentication**
2. Click **Modify** for SSO configuration

**Step 2: Configure SAML**
1. Select **Integrate a 3rd-party identity provider**
2. Download Webex metadata
3. Configure IdP with Webex metadata
4. Upload IdP metadata to Webex

**Step 3: Configure IdP Application**
1. Create SAML application in your IdP
2. Webex supports SAML 2.0 and OAuth 2.0
3. Configure attribute mappings
4. Assign users/groups

**Step 4: Test and Enable**
1. Test SSO authentication
2. Verify user provisioning works
3. Enable SSO enforcement

**Time to Complete:** ~1 hour

---

### 1.2 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all Webex users.

#### Rationale
**Why This Matters:**
- A stolen or guessed password alone cannot grant access when a second factor is required
- Webex accounts unlock meetings, recordings, messages, and calling that attackers prize for espionage and fraud
- Phishing-resistant factors for admins block adversary-in-the-middle and push-fatigue attacks
- MFA is a baseline expectation for SOC 2, ISO 27001, and most regulatory frameworks

**Attack Prevented:** Credential stuffing, phishing, password spraying, account takeover

#### ClickOps Implementation

**Step 1: Enable Organization MFA**
1. Navigate to: **Control Hub** → **Management** → **Organization Settings**
2. Scroll to **Authentication** section
3. Enable **Require multi-factor authentication**
4. This makes MFA mandatory for all users

**Step 2: Configure via IdP (Recommended)**
1. Enable MFA in your identity provider
2. All SSO users subject to IdP MFA policies
3. Use phishing-resistant methods for admins

---

### 1.3 Configure User Provisioning

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Configure automatic user provisioning and deprovisioning.

#### Rationale
**Why This Matters:**
- SCIM provisioning removes departed users automatically, eliminating orphaned accounts with standing access to meetings and data
- Manual deprovisioning is slow and error-prone, leaving a window where ex-employees retain access
- Attribute and group mapping keeps Webex roles aligned with the authoritative directory, preventing privilege drift
- Consistent lifecycle management produces the access evidence auditors expect

**Attack Prevented:** Orphaned-account access, insider misuse, privilege creep, unauthorized access by former employees

#### ClickOps Implementation

**Step 1: Configure SCIM Provisioning**
1. Navigate to: **Control Hub** → **Users** → **Directory Sync**
2. Configure directory sync:
   - Okta
   - Azure Active Directory
   - Other SCIM providers

**Step 2: Configure Synchronization**
1. Map user attributes
2. Configure group synchronization
3. Enable automatic deprovisioning

**Step 3: Test Provisioning**
1. Create test user in IdP
2. Verify user appears in Webex
3. Test deprovisioning

---

## 2. Meeting Security

### 2.1 Configure Meeting Passwords

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2 |

#### Description
Require passwords for all Webex meetings, and extend that requirement to the two join paths that commonly escape it: participants dialling in by phone and participants joining from a video conferencing system.

#### Rationale
**Why This Matters:**
- A meeting without a password is protected only by the obscurity of its number, and Webex meeting numbers are short and sequential enough to be guessed or harvested — the password is what turns a discovered meeting into an inaccessible one
- **Phone and video-system join paths are the gap that matters:** an organization can require a password in the web client and still leave the meeting joinable by anyone who dials the bridge, which is precisely how a confidential discussion gets overheard by an uninvited caller
- Password enforcement is what makes every other meeting control meaningful — lobby, lock, and authentication settings all assume an attacker cannot simply walk in through an unprotected join path

**Attack Prevented:** Meeting bombing, uninvited dial-in eavesdropping, meeting-number enumeration, unauthorized joins from unmanaged video endpoints

#### ClickOps Implementation

**Step 1: Configure Site Password Settings**
1. Navigate to: **Control Hub** → **Services** → **Meeting** → **Sites**
2. Select your site → **Configure Site**
3. Navigate to **Common Settings** → **Security**

**Step 2: Enable Password Requirements**
1. Enable **Require meeting password**
2. Configure password complexity

**Step 3: Close the Phone and Video-System Join Paths**
1. Navigate to: **Control Hub** → **Services** → **Meeting** → **Sites** → select your site → **Configure Site** → **Common Settings** → **Site Options**
2. Require a password for participants **joining by phone**
3. Require a password for participants **joining from a video conferencing system**
4. Confirm both options are enabled — a site that enforces passwords only in the web client leaves these two paths open

**Step 4: Apply to All Meeting Types**
1. Apply to scheduled meetings
2. Apply to Personal Room meetings
3. Apply to PMR meetings

Source: [Cisco Webex best practices for secure meetings: Site Administration](https://help.webex.com/en-us/article/v5rgi1/Cisco-Webex-Best-Practices-for-Secure-Meetings:-Site-Administration)

---

### 2.2 Configure Meeting Lock and Lobby

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-3 |

#### Description
Configure automatic meeting lock and lobby controls, and verify which behaviours Webex already applies by default before treating them as work to be done.

> **Changed defaults — verify rather than assume:** Cisco's current secure-meeting guidance documents that Webex meetings **automatically lock 5 minutes after they start by default**, that the **lobby is enabled by default for scheduled meetings**, and that the default behaviour when a meeting is locked is that **everyone waits in the lobby**. Your task is to confirm these defaults are still in force on your site and tighten them where the business demands, not to enable them from scratch. Sources: [Control Hub best practices](https://help.webex.com/en-us/article/ov50hy/Webex-best-practices-for-secure-meetings:-Control-Hub) · [Site Administration best practices](https://help.webex.com/en-us/article/v5rgi1/Cisco-Webex-Best-Practices-for-Secure-Meetings:-Site-Administration).

#### Rationale
**Why This Matters:**
- Auto-lock prevents uninvited participants from slipping into a meeting after it starts
- A lobby lets the host vet each attendee before granting entry, stopping gate-crashers and eavesdroppers
- Holding unauthenticated guests in the lobby limits exposure of confidential discussions and shared content
- Combined controls defend against meeting bombing and unauthorized recording of sensitive conversations

**Attack Prevented:** Meeting bombing, unauthorized eavesdropping, gate-crashing, confidential-data exposure

#### ClickOps Implementation

**Step 1: Configure Auto-Lock**
1. Navigate to: **Site Settings** → **Security**
2. Configure **Automatically lock meetings**:
   - Lock after: 5 minutes (recommended)
   - Options: 0, 5, 10, 15, or 20 minutes

**Step 2: Configure Lobby Behavior**
1. Configure **When meeting is locked**:
   - **Everyone waits in lobby** (recommended)
   - Or **No one can join**
2. Configure host notification

**Step 3: Configure Guest Access by Participant Class**

Webex classifies who is waiting in the lobby into three groups, and each group's admission behaviour is set independently — so "the lobby is on" is not a single answer:

| Participant class | Who it covers | Typical hardened setting |
|-------------------|---------------|--------------------------|
| Internal users | Signed-in users from your own organization | Admit directly, or lobby for the most sensitive meetings |
| Verified external users | Signed-in users from another Webex organization whose identity Webex has verified | Lobby, admitted by the host |
| Unverified users | Anyone else, including anonymous and guest joins | Lobby at minimum; block entirely for confidential meetings |

1. Set the admission behaviour separately for internal users, verified external users, and unverified users — do not leave unverified users inheriting a permissive internal setting
2. Require sign-in for external participants where the meeting content warrants it ([2.3](#23-require-authentication-for-meetings))
3. Configure lobby hold time and host notification so waiting participants are actually vetted rather than silently queued

---

### 2.3 Require Authentication for Meetings

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2 |

#### Description
Require users to sign in before joining meetings.

#### Rationale
**Why This Matters:**
- Requiring sign-in ties every participant to a verified identity instead of an anonymous guest
- Authenticated attendance produces an accurate attendee record for audit and incident response
- Blocking anonymous joins removes a key vector for eavesdropping and meeting disruption
- Sign-in enforcement lets host controls and access policies apply per identity

**Attack Prevented:** Anonymous eavesdropping, meeting bombing, attendee spoofing, unauthorized access

#### ClickOps Implementation

**Step 1: Enable Sign-In Requirement**
1. Navigate to: **Site Settings** → **Security**
2. Enable **Require sign-in when joining meetings**
3. This prompts all participants for credentials

**Step 2: Configure Host Requirements**
1. Require hosts to be signed in
2. Require attendees to be signed in (L3)
3. Allow exceptions for external guests if needed

---

### 2.4 Configure Content Sharing Controls

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control what content can be shared in meetings.

#### Rationale
**Why This Matters:**
- Restricting who can share screen, applications, and files stops participants from hijacking the presentation
- Limiting file transfer reduces the risk of malware delivery and accidental data leakage during meetings
- Host control over participant sharing contains disruptive or malicious content injection
- Default sharing restrictions enforce least privilege so only authorized presenters expose content

**Attack Prevented:** Screen-sharing hijack, malware distribution, data exfiltration, meeting disruption

#### ClickOps Implementation

**Step 1: Configure Sharing Permissions**
1. Navigate to: **Site Settings** → **Common Settings**
2. Configure sharing options:
   - Screen sharing permissions
   - Application sharing
   - File transfer capabilities

**Step 2: Configure Host Controls**
1. Allow hosts to disable participant sharing
2. Configure annotation permissions
3. Set default sharing preferences

**Step 3: Disable Third-Party Virtual Cameras on macOS**

> **Enabled by default:** Support for third-party virtual cameras in the Webex app on macOS is **on by default**. A virtual camera lets arbitrary third-party software inject a video stream into the meeting, so the video other participants see need not come from a physical camera at all. Disable it unless a business workflow genuinely requires it. Source: [Cisco Webex best practices for secure meetings: Site Administration](https://help.webex.com/en-us/article/v5rgi1/Cisco-Webex-Best-Practices-for-Secure-Meetings:-Site-Administration).

1. Disable third-party virtual camera support for macOS clients at the site level
2. Where a team needs it, scope the exception rather than leaving the default in place organization-wide

---

### 2.5 Enable CAPTCHA on Personal Room Meetings

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 13.5 |
| NIST 800-53 | AC-3, SC-5 |

#### Description
Require a CAPTCHA before a participant can join a Personal Room meeting, configured at **Control Hub** → **Services** → **Meeting** → **Sites** → select your site → **Settings** → **Personal Meeting Room**.

#### Rationale
**Why This Matters:**
- A Personal Room address is stable and predictable — it is derived from the user and does not rotate per meeting, so it can be discovered once and probed indefinitely
- Without a CAPTCHA, that predictability invites **scripted enumeration**: automated tooling can walk Personal Room addresses across an organization to find which ones are live and unattended, at a rate no human attacker could match
- A CAPTCHA imposes a per-attempt human cost, which collapses bulk enumeration while barely affecting the legitimate participant who joins a room once

**Attack Prevented:** Automated Personal Room enumeration, bot-driven meeting joins, scripted meeting-bombing campaigns

#### ClickOps Implementation

**Step 1: Enable CAPTCHA**
1. Navigate to: **Control Hub** → **Services** → **Meeting** → **Sites**
2. Select your site → **Settings** → **Personal Meeting Room**
3. Enable the CAPTCHA requirement for joining Personal Room meetings

**Step 2: Pair With Room Locking**
1. Confirm Personal Rooms also enforce a password ([2.1](#21-configure-meeting-passwords)) and lobby behaviour ([2.2](#22-configure-meeting-lock-and-lobby))
2. Encourage hosts to lock their Personal Room when in use rather than relying on the CAPTCHA alone

Source: [Cisco Webex best practices for secure meetings: Site Administration](https://help.webex.com/en-us/article/v5rgi1/Cisco-Webex-Best-Practices-for-Secure-Meetings:-Site-Administration)

#### Validation & Testing
1. From a signed-out browser, attempt to join a Personal Room and confirm the CAPTCHA is presented before entry
2. Confirm the legitimate host join flow is unaffected

#### Compliance Mappings

| Framework | Control | How This Maps |
|-----------|---------|---------------|
| CIS Controls v8 | 13.5 Manage Access Control for Remote Assets | Restricts automated access to meeting resources |
| NIST 800-53 Rev 5 | SC-5 Denial-of-Service Protection | Rate-limits automated join attempts |
| NIST 800-53 Rev 5 | AC-3 Access Enforcement | Human-verification gate before admission |

---

### 2.6 Restrict Audio Callback to High-Fraud Countries

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1, 13.4 |
| NIST 800-53 | CM-7, SC-7 |

#### Description
Block Webex audio callback ("Call Me") to the countries associated with toll fraud, configured at **Control Hub** → **Services** → **Meetings** → **Configure Site** → **Common Settings** → **Audio Settings**. Cisco exposes a defined set of **19 blockable countries** in this setting.

#### Rationale
**Why This Matters:**
- Audio callback instructs Webex to dial **outbound** to a number the participant supplies — which means a meeting join can generate a paid international call at the organization's expense
- This is the classic **toll fraud / international revenue share fraud** pattern: an attacker joins meetings and requests callbacks to premium-rate numbers in high-fraud jurisdictions, and the charges accrue silently until a bill arrives
- Blocking the specific high-fraud destinations removes the profit motive without disrupting callback for the regions your people actually work in — the fraud depends on reaching those particular destinations

**Attack Prevented:** Toll fraud, international revenue share fraud, premium-rate callback abuse, unbudgeted telephony charges

#### ClickOps Implementation

**Step 1: Open Audio Settings**
1. Navigate to: **Control Hub** → **Services** → **Meetings** → **Configure Site**
2. Open **Common Settings** → **Audio Settings**

**Step 2: Block High-Fraud Destinations**
1. Review the list of blockable countries (19 are available) and block all of them unless a documented business need requires callback to a specific destination
2. Record any exception with its business justification and an owner, and re-review it on the same cadence as your access reviews

**Step 3: Monitor**
1. Review telephony charges for callback activity to unexpected destinations; a spike is a fraud indicator, not a usage trend

Source: [Cisco Webex best practices for secure meetings: Site Administration](https://help.webex.com/en-us/article/v5rgi1/Cisco-Webex-Best-Practices-for-Secure-Meetings:-Site-Administration)

#### Validation & Testing
1. Attempt a callback to a blocked destination from a test meeting and confirm it is refused
2. Confirm callback still works for the destinations your organization operates in

#### Compliance Mappings

| Framework | Control | How This Maps |
|-----------|---------|---------------|
| CIS Controls v8 | 4.1 Establish and Maintain a Secure Configuration Process | Callback restriction as standard site configuration |
| NIST 800-53 Rev 5 | CM-7 Least Functionality | Disables an outbound capability not required for business |
| NIST 800-53 Rev 5 | SC-7 Boundary Protection | Restricts outbound telephony destinations |

---

### 2.7 Reduce Meeting Discoverability and Exposure

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 13.5 |
| NIST 800-53 | AC-3, AC-22 |

#### Description
Reduce how easily a meeting can be found and joined by someone who was never invited: prefer scheduled meetings over Personal Room meetings, prevent participants from joining before the host, mark sensitive meetings unlisted, and hide the meeting link from the in-meeting information panel.

#### Rationale
**Why This Matters:**
- A Personal Room address is permanent and reusable, so one leaked link grants a standing invitation to every future conversation held there; a scheduled meeting's identifiers expire with the meeting, which caps the value of a leak
- Join-before-host lets participants occupy a meeting with no one present to vet them — the lobby and host controls that make Webex safe only work when a host is there to apply them
- Listed meetings appear on the site's public meeting list, turning the meeting calendar into a reconnaissance surface that shows an outsider what is being discussed, by whom, and when
- The in-meeting information panel displays the join link; hiding it stops a participant from screen-sharing or photographing a slide that hands the link to someone outside the meeting

**Attack Prevented:** Meeting-link harvesting, reconnaissance via public meeting listings, unhosted meeting occupation, re-use of a leaked Personal Room link

#### ClickOps Implementation

**Step 1: Prefer Scheduled Meetings**
1. Set organizational guidance that confidential discussions use scheduled meetings, not Personal Rooms
2. Reserve Personal Rooms for informal, low-sensitivity use, and apply [2.5](#25-enable-captcha-on-personal-room-meetings) where they remain in use

**Step 2: Prevent Join Before Host**
1. In the site's meeting settings, disable the option allowing participants to join before the host
2. Where an exception is required for large events, pair it with a lobby that holds everyone until the host arrives

**Step 3: Make Sensitive Meetings Unlisted**
1. Configure sensitive meetings as **unlisted** so they do not appear on the site's meeting list
2. Confirm the site default matches your risk appetite rather than leaving it at the permissive setting

**Step 4: Hide the Meeting Link In-Meeting**
1. Enable the setting that hides the meeting link from the in-meeting information panel, so the link cannot be read off a shared screen

Source: [Cisco Webex best practices for secure meetings: Site Administration](https://help.webex.com/en-us/article/v5rgi1/Cisco-Webex-Best-Practices-for-Secure-Meetings:-Site-Administration)

#### Validation & Testing
1. Confirm the site meeting list does not display meetings marked unlisted
2. Join a test meeting as a participant before the host and confirm entry is refused or held in the lobby
3. Open the in-meeting information panel and confirm the join link is not displayed

#### Compliance Mappings

| Framework | Control | How This Maps |
|-----------|---------|---------------|
| CIS Controls v8 | 3.3 Configure Data Access Control Lists | Limits who can discover and reach meeting content |
| CIS Controls v8 | 13.5 Manage Access Control for Remote Assets | Controls remote join conditions |
| NIST 800-53 Rev 5 | AC-22 Publicly Accessible Content | Prevents unintended publication of meeting details |
| NIST 800-53 Rev 5 | AC-3 Access Enforcement | Host presence required before admission |

---

## 3. Admin & Site Security

### 3.1 Limit Administrator Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Minimize administrator accounts to reduce risk.

#### Rationale
**Why This Matters:**
- A Webex full administrator can change site-wide meeting security in a single action — disabling password enforcement, lobby behaviour, or lock defaults for every meeting the organization holds — so one compromised admin account silently undoes every control in section 2
- Administrative sprawl is what makes that likely: Control Hub roles accumulate through project work and reorganizations, and an unreviewed admin list ends up containing people whose current job does not require the access their account still holds
- Granular roles exist precisely so that routine work (adding users, reading reports) does not require the role that can rewrite security policy; assigning full administrator by habit removes the distinction the role model was built to provide
- Departed and dormant admin accounts retain standing authority over meetings, recordings, and user provisioning until someone looks — which is what quarterly review exists to force

**Attack Prevented:** Administrative account takeover, silent rollback of meeting security settings, privilege sprawl, standing access retained after departure

#### ClickOps Implementation

**Step 1: Review Administrators**
1. Navigate to: **Control Hub** → **Users** → Filter by admin roles
2. Review all administrator accounts
3. Identify unnecessary admin access

**Step 2: Implement Role-Based Access**
1. Use granular admin roles:
   - Full Administrator
   - Site Administrator
   - User Administrator
   - Read-only Administrator
2. Assign minimum required role

**Step 3: Regular Access Reviews**
1. Quarterly review of admin access
2. Remove departed employees
3. Document business justification

---

### 3.2 Configure Enterprise Mobility Management

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.7 |
| NIST 800-53 | AC-19 |

#### Description
Configure EMM for mobile device security.

#### Rationale
**Why This Matters:**
- EMM/MDM policies enforce app protection on personal and corporate devices that access Webex data
- Blocking copy/paste and screenshots prevents corporate content from leaking into unmanaged apps
- Controlling file-sharing destinations keeps meeting and message data inside approved boundaries
- Device-level controls protect Webex data even when a phone is lost, stolen, or jailbroken

**Attack Prevented:** Data leakage, lost/stolen device exposure, unmanaged-app exfiltration, mobile data theft

#### ClickOps Implementation

**Step 1: Enable EMM Integration**
1. Navigate to: **Control Hub** → **Organization Settings** → **Device Management**
2. Configure EMM/MDM integration:
   - Microsoft Intune
   - VMware Workspace ONE
   - Other AppConfig providers

**Step 2: Configure App Protection**
1. Prevent copy/paste from Webex app
2. Prevent screenshots
3. Control file sharing destinations

---

### 3.3 Configure Audit Tracking

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor administrative audit logs.

#### Rationale
**Why This Matters:**
- Audit logs create an accountable record of every admin action for forensic investigation
- Exporting to a SIEM enables real-time alerting on suspicious configuration and privilege changes
- Without logging, account compromise and insider abuse can go undetected for long periods
- Retained audit trails satisfy SOC 2, NIST, and regulatory evidence requirements

**Attack Prevented:** Undetected privilege escalation, insider abuse, configuration tampering, delayed breach detection

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Control Hub** → **Management** → **Troubleshooting** → **Audit**
2. Review admin actions
3. Filter by user, date, or action

**Step 2: Export Logs**
1. Export logs for SIEM integration
2. Configure REST API access for automation
3. Set up regular exports

**Key Events to Monitor:**
- Admin login events
- Configuration changes
- User provisioning/deprovisioning
- Security setting modifications

---

### 3.4 Enforce Account Password, Lockout, and Deactivation Policies

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2, 5.3, 6.2 |
| NIST 800-53 | AC-2(3), AC-7, IA-5 |

#### Description
Configure the site's account policies — password composition and change requirements, lockout after failed sign-in attempts, and automatic deactivation of inactive accounts — for sites where Webex holds the credential rather than an external IdP.

#### Rationale
**Why This Matters:**
- Where SSO is not enforced for every user, the Webex-held password is the whole of the authentication boundary; a weak password policy there quietly reintroduces the risk SSO was adopted to remove
- Lockout after repeated failed attempts is what makes password guessing and credential-stuffing uneconomic; without it, an attacker can grind against a known username list indefinitely and undetected
- Inactive accounts are the accounts nobody watches: they hold valid credentials, generate no activity to alert on, and survive offboarding processes that only cover current staff — automatic deactivation removes them without depending on someone remembering
- Account policy is site-wide, so it is one of the few Webex settings that protects hosts, admins, and ordinary users with a single configuration

**Attack Prevented:** Password guessing and spraying, credential stuffing, takeover of dormant accounts, persistence through unmonitored accounts

#### ClickOps Implementation

**Step 1: Set Password Policy**
1. Navigate to: **Control Hub** → **Services** → **Meeting** → **Sites** → select your site → **Configure Site** → **Common Settings**
2. Configure the account password requirements — composition rules and change requirements — for users authenticating against Webex rather than an IdP

**Step 2: Set Lockout Policy**
1. Enable account lockout after a defined number of consecutive failed sign-in attempts
2. Set the lockout duration so repeated automated attempts are slowed rather than merely logged

**Step 3: Deactivate Inactive Accounts**
1. Enable automatic deactivation of accounts after a defined period of inactivity
2. Reconcile the deactivation window against your offboarding SLA — deactivation is the backstop for accounts offboarding missed, so it should be shorter than the interval between access reviews

Source: [Cisco Webex best practices for secure meetings: Site Administration](https://help.webex.com/en-us/article/v5rgi1/Cisco-Webex-Best-Practices-for-Secure-Meetings:-Site-Administration)

#### Validation & Testing
1. Attempt repeated failed sign-ins against a test account and confirm lockout triggers
2. Confirm a password failing the composition policy is rejected at change time
3. Review the user list for accounts past the inactivity threshold that remain active — any survivor indicates the policy is not applied

#### Compliance Mappings

| Framework | Control | How This Maps |
|-----------|---------|---------------|
| CIS Controls v8 | 5.2 Use Unique Passwords | Password composition policy |
| CIS Controls v8 | 5.3 Disable Dormant Accounts | Automatic inactivity deactivation |
| NIST 800-53 Rev 5 | AC-7 Unsuccessful Logon Attempts | Lockout after failed attempts |
| NIST 800-53 Rev 5 | AC-2(3) Disable Accounts | Inactivity-based deactivation |
| NIST 800-53 Rev 5 | IA-5 Authenticator Management | Password requirements |

---

## 4. Data Protection

### 4.1 Configure Encryption Settings

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-8, SC-28 |

#### Description
Verify and configure encryption for data protection.

> **Verification note (2026-08):** The end-to-end encryption toggles described below — an E2E option under **Services** → **Messaging** and a per-meeting E2E setting — are **not documented in either of Cisco's current secure-meeting best-practice articles**, and the targeted Webex encryption article returned 404 in this pass. Webex E2EE provisioning has changed over time and is licence- and meeting-type dependent. Verify the mechanism and its exact location in Control Hub before relying on this control; treat the TLS-in-transit and encryption-at-rest statements as the reliable part of this section.

#### Rationale
**Why This Matters:**
- TLS in transit protects meetings, messages, and recordings from network interception and man-in-the-middle attacks
- End-to-end encryption keeps sensitive spaces confidential even from the platform and underlying infrastructure
- Encryption at rest protects stored recordings and files if the underlying storage is compromised
- Verified encryption settings are essential evidence for data-protection and privacy compliance

**Attack Prevented:** Network interception, man-in-the-middle, data-at-rest theft, eavesdropping

#### Webex Encryption Features
1. **End-to-End Encryption (E2E):** Messages encrypted before reaching servers
2. **TLS 1.2+:** All data in transit encrypted
3. **Zero-Trust Architecture:** Standards-based encryption

#### ClickOps Implementation

**Step 1: Enable E2E Encryption**
1. Navigate to: **Control Hub** → **Services** → **Messaging**
2. Enable end-to-end encryption where available
3. Configure for sensitive spaces

**Step 2: Configure Meeting Encryption**
1. Enable end-to-end encryption for meetings
2. Note: Some features may be limited with E2E

---

### 4.2 Configure Data Loss Prevention

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Configure DLP controls for data protection.

#### Rationale
**Why This Matters:**
- Webex spaces persist: messages, files, and recordings accumulate in a searchable store, so a single over-shared space leaks not one conversation but the entire history it holds
- The most common loss path is not an attacker but an ordinary mistake — a confidential file posted to a space that quietly contains an external participant; external-participant indicators exist to make that mistake visible at the moment it would happen
- Without a DLP integration inspecting content, sensitive data leaving through Webex is undetectable by the tooling that covers email and endpoints, creating a channel that reporting does not cover
- Retention, eDiscovery, and legal hold determine what survives to be produced or breached; leaving them unset means the organization neither controls its exposure window nor can answer what was in it

**Attack Prevented:** Inadvertent data disclosure to external participants, exfiltration through an uninspected channel, uncontrolled retention of sensitive content, inability to produce records during investigation

#### ClickOps Implementation

**Step 1: Configure External Participant Indicators**
1. Enable external participant indicators
2. Users see when external participants join
3. Visual cues for sensitive discussions

**Step 2: Configure DLP Integration**
1. Navigate to: **Control Hub** → **Apps** → **Compliance**
2. Configure third-party DLP integration
3. Monitor for policy violations

**Step 3: Configure Retention**
1. Set message retention policies
2. Configure eDiscovery access
3. Enable legal holds

---

### 4.3 Configure Pro Pack Features

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Configure Pro Pack for advanced security controls.

#### Rationale
**Why This Matters:**
- Advanced file-sharing controls restrict where content can be sent, closing data-exfiltration paths
- eDiscovery and extended retention preserve records for legal hold and regulatory investigations
- Compliance exports give security teams the data needed for audits and incident response
- Granular Pro Pack controls extend protection beyond the defaults for security-sensitive and regulated environments

**Attack Prevented:** Data exfiltration, evidence loss, compliance gaps, uncontrolled file sharing

#### Prerequisites
- Webex Pro Pack license

#### ClickOps Implementation

**Step 1: Configure File Sharing Controls**
1. Navigate to: **Control Hub** → **Organization Settings**
2. Configure file sharing restrictions
3. Control sharing destinations

**Step 2: Configure Advanced Compliance**
1. Enable eDiscovery
2. Configure extended retention
3. Enable compliance exports

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Webex Control | Guide Section |
|-----------|---------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Admin controls | [3.1](#31-limit-administrator-access) |
| CC6.6 | Meeting security | [2.1](#21-configure-meeting-passwords) |
| CC6.6 | Meeting discoverability controls | [2.7](#27-reduce-meeting-discoverability-and-exposure) |
| CC6.1 | Account password and lockout policy | [3.4](#34-enforce-account-password-lockout-and-deactivation-policies) |
| CC6.7 | Encryption | [4.1](#41-configure-encryption-settings) |
| CC7.2 | Audit logging | [3.3](#33-configure-audit-tracking) |

### NIST 800-53 Rev 5 Mapping

| Control | Webex Control | Guide Section |
|---------|---------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | MFA | [1.2](#12-enforce-multi-factor-authentication) |
| AC-3 | Meeting controls | [2.2](#22-configure-meeting-lock-and-lobby) |
| AC-7 | Sign-in lockout | [3.4](#34-enforce-account-password-lockout-and-deactivation-policies) |
| CM-7 | Audio callback restriction | [2.6](#26-restrict-audio-callback-to-high-fraud-countries) |
| SC-5 | Personal Room CAPTCHA | [2.5](#25-enable-captcha-on-personal-room-meetings) |
| SC-8 | Encryption | [4.1](#41-configure-encryption-settings) |
| AU-2 | Audit logging | [3.3](#33-configure-audit-tracking) |

---

## Appendix A: References

**Official Cisco Documentation:**
- [Webex Help Center](https://help.webex.com/)
- [Webex Compliance and Certifications](https://help.webex.com/en-us/article/pdz31w/Webex-Compliance-and-Certifications)
- [Cisco Webex best practices for secure meetings: Site Administration](https://help.webex.com/en-us/article/v5rgi1/Cisco-Webex-Best-Practices-for-Secure-Meetings:-Site-Administration) -- dated 2025-03-22; primary source for this pass
- [Webex best practices for secure meetings: Control Hub](https://help.webex.com/en-us/article/ov50hy/Webex-best-practices-for-secure-meetings:-Control-Hub) -- primary source for this pass
- [Webex Security White Paper](https://www.cisco.com/c/en/us/products/collateral/conferencing/webex-meeting-center/white-paper-c11-737588.html)
- [Webex Hardening Guide](https://www.cisco.com/c/en/us/td/docs/voice_ip_comm/cloudCollaboration/wbxt/hardening-guide/webex-hardening-guide.html) -- **requires real-browser access**: cisco.com returns 403 to automated fetchers, so this link cannot be machine-verified and must be opened in a browser

**API Documentation:**
- [Webex Developer Portal](https://developer.webex.com/docs/getting-started)
- [Webex REST API Reference](https://developer.webex.com/docs/api/getting-started)

**Compliance Frameworks:**
- Cisco publishes Webex certification claims (SOC 2 Type II, SOC 3, and the ISO 27001/27017/27018/27701 family, plus EU Cloud Code of Conduct) through its Trust Portal. That portal is a compliance-marketing surface rather than configuration documentation and was removed from this appendix under the repo source standard; the specific certification versions and levels are **unverified in this pass**. Request current attestation documents from Cisco, or check [Webex Compliance and Certifications](https://help.webex.com/en-us/article/pdz31w/Webex-Compliance-and-Certifications), before citing them in an assessment.

**Security Incidents:**
- **May 2024 -- German Government Meeting Metadata Exposure:** An IDOR vulnerability in Cisco Webex allowed threat actors to access meeting metadata (topics, hosts, dates) by incrementing meeting URL numbers. Sensitive meetings of German government officials and European defense/tech companies were exposed. Meeting passwords and participant lists were not accessible. The flaw was fully patched by May 28, 2024.
- **March 2024 -- German Military Meeting Eavesdropping:** Russia-linked actors intercepted a German military Webex meeting discussing Ukraine support, attributed to participants joining via unsecured phone lines rather than a Webex platform vulnerability.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass against Cisco's secure-meeting best-practice articles: add 2.5 Personal Room CAPTCHA, 2.6 audio-callback country restriction, 2.7 meeting discoverability controls, and 3.4 account password/lockout/deactivation policy; document the auto-lock, lobby, and locked-meeting defaults and the three-way lobby participant classification in 2.2; extend 2.1 password enforcement to phone and video-system join paths; add the macOS third-party virtual camera default callout to 2.4; replace placeholder rationales in 2.1, 3.1, and 4.2 with real threat statements plus Attack Prevented lines; annotate 4.1 E2EE as undocumented in current articles; drop Trust Portal references and re-source the compliance mapping honestly. Tier 3/4 sources not surveyed this pass. | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, meeting security, and data protection | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
