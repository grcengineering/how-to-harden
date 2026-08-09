---
layout: guide
title: "Zoom Hardening Guide"
vendor: "Zoom"
slug: "zoom"
tier: "2"
category: "Productivity"
description: "Video conferencing security for meeting policies, recording controls, and app marketplace"
version: "0.2.2"
maturity: "draft"
last_updated: "2026-08-08"
---


## Overview

Zoom commands **55.91% global market share** with **70% of Fortune 100** as customers. The App Marketplace, OAuth tokens (access tokens valid 1 hour, refresh tokens valid 90 days and rotated on every use), and SDK integrations create supply chain risk. CVE-2025-49457 (CVSS 9.6) and CVE-2026-53412 (CVSS 9.8, unauthenticated remote account takeover) demonstrate ongoing client-side vulnerability management challenges. Customer Managed Key (CMK) provides encryption control for sensitive communications.

### Intended Audience
- Security engineers managing collaboration tools
- IT administrators configuring Zoom
- GRC professionals assessing video collaboration compliance
- Third-party risk managers evaluating SDK integrations

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Zoom security configurations including authentication, meeting security, Marketplace app governance, and encryption controls.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Meeting Security](#2-meeting-security)
3. [Marketplace App Security](#3-marketplace-app-security)
4. [Data Security & Encryption](#4-data-security--encryption)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML/OIDC SSO with MFA for all Zoom access.

#### Rationale
**Why This Matters:**
- Centralizes Zoom authentication in your corporate IdP so MFA and conditional access apply to every login
- Local Zoom passwords bypass IdP controls and are prime targets for credential stuffing — Zoom suffered a mass credential-stuffing account compromise in 2020
- SSO with SCIM deprovisions departed users automatically, eliminating orphaned accounts that retain meeting and recording access
- Meetings and cloud recordings can hold confidential discussions, so a single compromised login can expose sensitive collaboration data

**Attack Prevented:** Credential stuffing, phishing, MFA bypass, orphaned-account access

#### ClickOps Implementation

**Step 1: Configure SAML SSO (Business/Enterprise)**
1. Navigate to: **Admin → Advanced → Security → Single Sign-On**
2. Click **Enable Single Sign-On**
3. Configure:
   - **Sign-in page URL:** IdP login endpoint
   - **Sign-out page URL:** IdP logout endpoint
   - **Certificate:** Upload IdP certificate
   - **Service Provider Entity ID:** From Zoom

**Step 2: Enforce SSO Login**
1. Navigate to: **Admin → Advanced → Security**
2. Enable: **Only allow users to sign in with SSO**
3. Disable: **Allow users to sign in with work email**

**Step 3: Configure Two-Factor Authentication**
1. Navigate to: **Admin → Advanced → Security → Security**
2. Enable: **Sign in with Two-Factor Authentication**
3. Configure: **All users in your account**

---

### 1.2 Configure User Management

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Implement role-based access and user provisioning.

#### Rationale
**Why This Matters:**
- Role-based access enforces least privilege so members cannot reach admin settings, billing, or account-wide configuration
- Limiting the Owner and Admin roles shrinks the set of accounts able to disable security controls or export recordings
- SCIM provisioning keeps Zoom membership synchronized with the IdP, removing access the moment an employee is offboarded
- Auto-provisioning with a constrained default role prevents new SSO users from silently inheriting elevated permissions

**Attack Prevented:** Privilege escalation, orphaned-account access, insider misuse, unauthorized configuration changes

#### ClickOps Implementation

**Step 1: Configure Roles**
1. Navigate to: **Admin → User Management → Roles**
2. Create/modify roles:

| Role | Permissions |
|------|-------------|
| Member | Host meetings, basic features |
| Admin | Manage users, settings |
| Owner | Full account control (1 user only) |

**Step 2: Enable SCIM Provisioning**
1. Navigate to: **Admin → Advanced → Integration**
2. Enable: **SCIM token**
3. Configure IdP to sync users via SCIM

**Step 3: Configure Auto-Provisioning**
1. Navigate to: **Admin → Advanced → Security**
2. Enable: **Automatic provisioning for SSO users**
3. Set default role and group

---

### 1.3 Enforce a Minimum Zoom Client Version

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.2, 7.3 |
| NIST 800-53 | SI-2, CM-7(5) |

#### Description
Use Zoom's **System Updates** account setting to require a minimum client version per platform and force non-compliant clients to sign out and upgrade before they can rejoin. This is the account-level enforcement mechanism that actually closes client-side CVEs — patch availability alone does nothing if users keep running an old build.

#### Rationale
**Why This Matters:**
- Zoom's critical vulnerabilities are overwhelmingly *client-side*, so a patched server tenant does not protect an endpoint still running a vulnerable desktop build
- CVE-2025-49457 (CVSS 9.6, DLL hijacking) and CVE-2026-53412 (CVSS 9.8, unauthenticated remote account takeover in Zoom Workplace for Windows before 7.0.0 and the VDI client) are both fixed only by upgrading the client
- Without a minimum-version floor, upgrade is user-discretionary and long-tail endpoints stay exploitable for months after a fix ships
- Setting the floor per platform lets you enforce Windows, macOS, Linux, and mobile independently as fixes land on different schedules

**Attack Prevented:** Exploitation of known client CVEs, DLL hijacking, remote account takeover via unpatched endpoints

#### ClickOps Implementation

**Step 1: Open System Updates**
1. Navigate to: **Admin → Account Management → Account Settings → General**
2. Locate the **System Updates** section (Zoom desktop client and mobile app updates)

**Step 2: Set the Minimum Version Floor**
1. Enable: **Zoom desktop client and mobile app version control**
2. For each platform (Windows, macOS, Linux, iOS, Android), set the **minimum version** to the current fixed release — at minimum, Zoom Workplace for Windows **7.0.0** or later to remediate CVE-2026-53412
3. Choose the enforcement behavior: require users below the minimum to **sign out and upgrade** before rejoining

**Step 3: Enable Automatic Updates**
1. In the same **System Updates** section, enable automatic client updates
2. Select the **Slow** channel for stability or **Fast** for earliest fixes (L3 environments should prefer Fast for security releases)
3. Lock the setting so users and group admins cannot opt out

**Step 4: Re-baseline After Each Bulletin**
1. Subscribe to the [Zoom Security Bulletins](https://www.zoom.com/en/trust/security-bulletin/)
2. Raise the minimum version whenever a bulletin patches a High or Critical client vulnerability

**Time to Complete:** ~20 minutes

#### Validation & Testing
1. Sign in from a deliberately out-of-date client and confirm Zoom blocks the session and prompts for upgrade
2. Confirm the enforced minimum is visible and locked at the account level so groups cannot lower it
3. Review **Admin → Account Management → Reports → Active Hosts** or the sign-in report to confirm no sessions remain on versions below the floor

**Expected result:** Clients below the configured minimum version are forced to sign out and upgrade before they can join any meeting.

**Reference:** [Zoom — Managing system updates for the Zoom client](https://support.zoom.com/hc/en/article?id=zm_kb&sysparm_article=KB0067165)

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.1 | Vulnerability identification and remediation |
| **NIST 800-53** | SI-2 | Flaw remediation |
| **NIST 800-53** | CM-7(5) | Authorized software / allowlisting |
| **ISO 27001:2022** | A.8.8 | Management of technical vulnerabilities |

---

## 2. Meeting Security

### 2.1 Enforce Meeting Password and Waiting Room

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3

#### Description
Require passwords and waiting rooms to prevent unauthorized meeting access.

#### Rationale
**Why This Matters:**
- Passcodes and waiting rooms stop uninvited participants from joining via guessed or shared meeting IDs ("Zoombombing")
- Requiring authenticated users ties attendance to known identities, deterring anonymous disruption and eavesdropping
- Locking these settings at the account level prevents individual hosts from weakening protection on sensitive meetings
- Disabling rejoin-after-removal and self-rename closes paths for ejected or impersonating attendees to re-enter or hide

**Attack Prevented:** Meeting hijacking (Zoombombing), unauthorized eavesdropping, participant impersonation, meeting disruption

#### ClickOps Implementation

**Step 1: Configure Account-Level Settings**
1. Navigate to: **Admin → Account Management → Account Settings → Security**
2. Enable and lock:
   - **Require a passcode when scheduling new meetings:** Locked
   - **Require a passcode for participants joining by phone:** Locked
   - **Waiting Room:** Locked (enabled by default)

**Step 2: Configure Meeting Authentication**
1. Navigate to: **Admin → Account Settings → Security**
2. Enable: **Only authenticated users can join meetings**
3. Configure: Authentication methods (SSO, Zoom account)

**Step 3: Disable Risky Features**
1. Navigate to: **Admin → Account Settings → Meeting**
2. Disable (or lock as disabled):
   - **Allow participants to rename themselves:** Disabled
   - **Allow removed participants to rejoin:** Disabled
   - **File transfer:** Disable or restrict to hosts

#### Code Implementation

{% include pack-code.html vendor="zoom" section="2.1" %}

---

### 2.2 Meeting Encryption Settings

**Profile Level:** L2 (Walk)
**NIST 800-53:** SC-8

#### Description
Configure end-to-end encryption for sensitive meetings.

#### Rationale
**Why This Matters:**
- End-to-end encryption ensures only meeting participants — not Zoom servers or network intermediaries — can decrypt audio and video
- Enhanced and E2EE encryption protect confidential discussions against interception on untrusted networks and provider-side compromise
- Verifying the security code with participants confirms there is no machine-in-the-middle injecting a substitute key
- Sensitive meetings (legal, executive, healthcare) carry confidentiality and regulatory requirements that plain transport encryption alone may not satisfy

**Attack Prevented:** Eavesdropping, machine-in-the-middle interception, provider-side data exposure

#### ClickOps Implementation

**Step 1: Enable E2EE**
1. Navigate to: **Admin → Account Settings → Security**
2. Enable: **End-to-end encrypted meetings**
3. Configure: **Default encryption type:** Enhanced encryption (or E2EE for L3)

**Step 2: Verify E2EE in Meetings**
- Green shield icon indicates E2EE
- Verify security code with participants for high-sensitivity meetings

---

### 2.3 Configure Zoom Phone Security (If Used)

**Profile Level:** L2 (Walk)
**NIST 800-53:** SC-8

#### Description
Secure Zoom Phone configurations.

#### Rationale
**Why This Matters:**
- Requiring consent for call recording keeps voice capture compliant with two-party-consent and wiretap regulations
- Voicemail encryption protects stored messages that often contain credentials, callback numbers, and confidential business details
- Correct E911 configuration ensures emergency calls route to the right responders with accurate location information
- Unsecured telephony is a frequent target for toll fraud, voicemail harvesting, and interception of sensitive conversations

**Attack Prevented:** Toll fraud, voicemail interception, unlawful recording, emergency-call misrouting

#### ClickOps Implementation

1. Navigate to: **Admin → Phone System Management**
2. Configure:
   - **Call recording:** Require consent
   - **Voicemail encryption:** Enable
   - **Emergency calling:** Configure E911

---

### 2.4 Disable and Lock Remote Control

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1, 4.8 |
| NIST 800-53 | AC-3, CM-7, SC-7 |

#### Description
Turn the in-meeting **Remote control** feature off for the entire account and lock it so no host, group admin, or user can re-enable it. Remote control lets one participant take keyboard and mouse control of another's machine, and Zoom's own consent dialog is the only thing standing between a social-engineering pretext and full endpoint takeover.

#### Rationale
**Why This Matters:**
- The remote-control consent prompt is a single click, and the display name of the requester is fully attacker-controlled — an attacker who renames themselves "Zoom" makes the prompt read like a routine system notification rather than a hand-over of the machine
- Trail of Bits documented the **ELUSIVE COMET** campaign (2025) using exactly this technique: attackers posing as media or investment interviewers requested remote control mid-call, then stole cryptocurrency and installed persistent malware
- Because Zoom is already an approved, signed application, the takeover generates no malware alert and no unusual process lineage — the attacker simply drives an existing trusted session
- Almost no organization has a genuine business need for participant-to-participant remote control; support teams should use a dedicated, audited remote-support tool instead

**Attack Prevented:** Social-engineered endpoint takeover, ELUSIVE COMET-style remote-control abuse, cryptocurrency theft, malware installation via trusted session

**Real-World Incidents:**
- **2025 — ELUSIVE COMET:** A threat actor targeted cryptocurrency holders through fake podcast and media interview invitations, requesting Zoom remote control during the call while impersonating a system prompt, then draining wallets and deploying malware ([Trail of Bits](https://blog.trailofbits.com/2025/04/17/mitigating-elusive-comet-zoom-remote-control-attacks/))

#### ClickOps Implementation

**Step 1: Disable Remote Control Account-Wide**
1. Navigate to: **Admin → Account Management → Account Settings**
2. Select the **Meeting** tab
3. Scroll to **In Meeting (Basic)**
4. Locate **Remote control** and toggle it **Off**

**Step 2: Lock the Setting**
1. Click the **lock icon** next to **Remote control**
2. Confirm the lock — this prevents groups, hosts, and individual users from re-enabling it

**Step 3: Disable Related Control Surfaces**
1. In the same **In Meeting (Basic)** section, disable and lock **Remote support** (host-initiated desktop control)
2. Verify no group under **Admin → User Management → Group Management → Settings** has an overriding value

**Step 4: Brief High-Risk Users**
1. Tell executives, finance, and treasury staff that Zoom will never ask for remote control, and that any such prompt during an external call is an attack
2. Where possible, have high-risk users remove the Zoom client entirely and join sensitive external calls from the browser client, which does not implement remote control

**Time to Complete:** ~15 minutes

#### Validation & Testing
1. Start a test meeting with two accounts and confirm the **Request remote control** option is absent from the participant and screen-share menus
2. As a group admin, confirm the setting appears greyed out and cannot be re-enabled
3. Confirm the lock persists after a user signs out and back in

**Expected result:** Remote control is unavailable to every participant on the account and cannot be re-enabled at the group or user level.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **SOC 2** | CC6.6 | Protection against external threats |
| **NIST 800-53** | CM-7 | Least functionality |
| **NIST 800-53** | AC-3 | Access enforcement |
| **ISO 27001:2022** | A.8.19 | Installation of software on operational systems |

---

## 3. Marketplace App Security

### 3.1 Implement App Approval Workflow

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7

#### Description
Control Zoom App Marketplace installations.

#### Rationale
**Why This Matters:**
- Marketplace apps access meeting data and recordings
- OAuth refresh tokens remain valid for 90 days, so an abandoned integration keeps standing access to meeting content for a full quarter
- Compromised apps can access all user meetings
- JWT-type apps were fully deprecated on **September 1, 2023** and no longer function, but their credentials frequently remain provisioned and unmanaged in the account

**Attack Prevented:** Meeting data and recording exfiltration via malicious or abandoned Marketplace apps with standing OAuth access

#### ClickOps Implementation

**Step 1: Configure App Installation Policy**
1. Navigate to: **Admin → Advanced → App Marketplace**
2. Configure:
   - **Pre-approve apps:** Enable
   - **Who can install:** Admins only

**Step 2: Review Installed Apps**
1. Navigate to: **Admin → Advanced → App Marketplace → Manage**
2. Review each app:
   - Permissions/scopes
   - Installation date
   - Active users
3. Remove unused apps

**Step 3: Restrict App Categories**
1. Block categories not needed:
   - Games
   - Social
   - Productivity (if not required)

**Step 4: Audit for Deprecated JWT Apps**
1. Navigate to: **Admin → Advanced → App Marketplace → Manage**
2. Filter the created/installed app list for any app whose type is **JWT**
3. For each JWT app found:
   - Confirm the owning team and identify the Server-to-Server OAuth or general OAuth app that replaced it
   - Delete the JWT app to deprovision its API Key and API Secret
   - Rotate any copies of that Key/Secret still held in CI systems, secret managers, `.env` files, or scripts
4. Treat any JWT credential discovered outside Zoom as exposed and rotate the successor app's credentials as well

> **Note:** JWT app credentials stopped working on **September 1, 2023** ([Zoom JWT app type deprecation](https://developers.zoom.us/changelog/platform/jwt-app-type-deprecation/)). They no longer grant API access, but leftover secrets are unmanaged credential material — they pollute secret scanning, obscure ownership, and signal integrations that were never properly migrated.

---

### 3.2 OAuth Token Management

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5(13)

#### Description
Manage OAuth tokens for marketplace apps.

#### Rationale
**Why This Matters:**
- Zoom access tokens expire after **1 hour** for every app type, so a stolen access token has a short blast radius — the durable credential to protect is the refresh token
- Refresh tokens are valid for **90 days** and **rotate on every use**: each refresh returns a new refresh token and invalidates the previous one, so a leaked refresh token still grants up to 90 days of renewable access until it is used or revoked
- Because refresh tokens rotate, a refresh failure on a legitimate integration can indicate an attacker used the token first — treat unexplained refresh errors as a possible compromise signal, not just a bug
- Server-to-Server OAuth apps use **no refresh token at all**: they mint a fresh 1-hour access token directly from the account ID, client ID, and client secret, which makes the **client secret** the standing credential requiring rotation and vaulting
- Reviewing and revoking unused tokens removes standing access held by abandoned or compromised integrations, and prompt revocation on offboarding closes the window in which an attacker can ride a stolen token

**Attack Prevented:** OAuth token theft, persistent third-party access, data exfiltration via compromised apps

#### Key Settings

| Token Type | Default Validity | Recommendation |
|------------|-----------------|----------------|
| Access Token (all app types) | 1 hour | N/A (Zoom managed, non-configurable) |
| Refresh Token (user-level / account-level OAuth) | 90 days, rotates on every use | Monitor refresh failures as compromise signals; revoke on offboarding or app removal |
| Server-to-Server OAuth | No refresh token — access token minted from client credentials | Vault the client secret and rotate on a defined schedule |

**Reference:** [Zoom — OAuth token lifetimes and refresh behavior](https://developers.zoom.us/docs/integrations/oauth/)

#### User-Level Revocation
1. Users: **Profile → Apps → Uninstall**
2. Admins: **Admin → App Marketplace → Remove access**

---

## 4. Data Security & Encryption

### 4.1 Configure Customer Managed Key (CMK)

**Profile Level:** L3 (Run)
**NIST 800-53:** SC-12

#### Description
Use customer-managed encryption keys for meeting content.

#### Rationale
**Why This Matters:**
- Customer-managed keys give your organization sole control over the keys that encrypt meeting content at rest
- Revoking or rotating the key in your KMS cuts off access to encrypted data, including against provider-side or legal compulsion
- KMS-backed key management produces an auditable trail of every key use for compliance and incident response
- Regulated communications often require demonstrable customer control of encryption keys that default provider-managed encryption cannot prove

**Attack Prevented:** Provider-side data exposure, unauthorized data-at-rest access, key-compromise blast radius

#### ClickOps Implementation (Enterprise)

**Step 1: Enable CMK**
1. Navigate to: **Admin → Advanced → Security → Data at Rest Encryption**
2. Enable: **Customer Managed Key**
3. Configure key in your cloud KMS (AWS KMS, Azure Key Vault)

**Step 2: Configure Key Rotation**
1. Set key rotation in cloud KMS
2. Document key recovery procedures

---

### 4.2 Configure Recording Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Secure meeting recordings.

#### Rationale
**Why This Matters:**
- Cloud recordings capture full meeting audio, video, and shared screens, making them a concentrated target for data theft
- Password protection and viewer authentication stop recordings from being opened by anyone holding a shared link
- Restricting downloads to authenticated users prevents silent redistribution of sensitive recorded content
- Recording consent and default expiration limit both legal exposure and the lifetime an exposed recording remains reachable

**Attack Prevented:** Unauthorized recording access, link-sharing leakage, data exfiltration, retention-policy violations

#### ClickOps Implementation

**Step 1: Recording Settings**
1. Navigate to: **Admin → Account Settings → Recording**
2. Configure:
   - **Recording consent:** Required
   - **Cloud recording:** Password protect
   - **Download restriction:** Authenticated users only

**Step 2: Recording Access**
1. Configure: **Who can access cloud recordings**
2. Enable: **Viewer authentication required**
3. Set: **Default expiration:** 30 days (L2)

#### Code Implementation

{% include pack-code.html vendor="zoom" section="4.2" %}

---

### 4.3 Restrict Zoom Team Chat External Permissions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3, AC-20, AC-21 |

#### Description
Use **External Permissions** in Zoom Team Chat to control whether external (non-account) users can be added to group chats and channels, whether internal users can join externally owned chats, and which of those actions require admin approval. Team Chat persists messages and files outside the meeting lifecycle and is governed separately from meeting settings.

#### Rationale
**Why This Matters:**
- Team Chat is a persistent store of messages and file attachments that survives long after a meeting ends, and it is monitored far less rigorously than email or cloud storage
- Unrestricted external chat is a low-friction exfiltration channel — a user can add an outside address to a channel and quietly mirror internal discussion and shared files to it
- Internal users joining externally *owned* channels puts your staff in a room whose retention, membership, and admin controls belong entirely to someone else's tenant
- External chat is a proven social-engineering staging ground: an attacker with a foothold in a shared channel gains internal context, org-chart knowledge, and a trusted-looking path to deliver lures
- Admin-approval workflows preserve legitimate partner collaboration while making every external connection a reviewed, attributable decision

**Attack Prevented:** Data exfiltration via chat, unauthorized external collaboration, social engineering through trusted channels, uncontrolled data residency in third-party tenants

#### ClickOps Implementation

**Step 1: Open External Permissions**
1. Navigate to: **Admin → Account Management → Account Settings**
2. Select the **Chat** tab
3. Locate the **External Permissions** section

**Step 2: Restrict External Membership**
1. Set who may add external users to internal group chats and channels — restrict to specific roles, or disable entirely for L2/L3
2. Where external collaboration is required, allow it only for **allowlisted domains** rather than any external address
3. Disable or gate the ability for internal users to **join externally owned chats and channels**

**Step 3: Require Admin Approval**
1. Enable the admin-approval workflow for external chat connections so each external channel or contact is reviewed before it becomes active
2. Assign a named owner for the approval queue — an unwatched queue defaults to either blocking business or rubber-stamping requests

**Step 4: Lock and Verify Group Overrides**
1. Lock the External Permissions settings at the account level
2. Navigate to: **Admin → User Management → Group Management → Settings → Chat** and confirm no group carries a more permissive override

**Time to Complete:** ~30 minutes

#### Validation & Testing
1. As a standard user, attempt to add an external email address to an internal channel and confirm it is blocked or routed to admin approval
2. Attempt to join an externally owned channel from an invitation and confirm the configured restriction applies
3. Confirm the settings display as locked and cannot be raised at the group level
4. Review **Admin → Account Management → Reports** chat and operation logs to confirm external chat events are being recorded

**Expected result:** External participation in Team Chat is limited to approved domains or blocked entirely, and every external connection is admin-reviewed and logged.

**Reference:** [Zoom — Managing Team Chat external permissions](https://support.zoom.com/hc/en/article?id=zm_kb&sysparm_article=KB0074841)

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **SOC 2** | CC6.7 | Restricted transmission of information |
| **NIST 800-53** | AC-20 | Use of external systems |
| **NIST 800-53** | AC-21 | Information sharing |
| **ISO 27001:2022** | A.5.14 | Information transfer |

---

## 5. Monitoring & Detection

### 5.1 Enable Audit Logging

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Configure Zoom audit logging.

#### Rationale
**Why This Matters:**
- Sign-in, meeting, and operation logs provide the evidence trail needed to detect account compromise and policy changes
- Forwarding logs to a SIEM enables correlation and alerting that Zoom's native reports alone cannot deliver
- Without comprehensive logging, breaches go undetected and forensic reconstruction after an incident becomes impossible
- Audit records of administrative actions reveal unauthorized settings changes such as disabling encryption or waiting rooms

**Attack Prevented:** Undetected account compromise, unauthorized configuration changes, insider misuse, delayed incident response

#### ClickOps Implementation

**Step 1: Access Reports**
1. Navigate to: **Admin → Account Management → Reports**
2. Review:
   - Sign in/out activity
   - Meeting reports
   - Webinar reports

**Step 2: Operation Logs (Enterprise)**
1. Navigate to: **Admin → Account Management → Reports → Activity**
2. Export operation logs
3. Forward to SIEM

#### Detection Queries

---

## 6. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | Zoom Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO enforcement | 1.1 |
| CC6.6 | Meeting security | 2.1 |
| CC6.7 | Encryption | 4.1 |

### HIPAA Considerations

- Enable E2EE for healthcare meetings
- Configure recording consent
- Use CMK for data at rest
- Sign BAA with Zoom

---

## Appendix A: Edition Compatibility

| Control | Basic | Pro | Business | Enterprise |
|---------|-------|-----|----------|------------|
| MFA | ✅ | ✅ | ✅ | ✅ |
| SSO (SAML) | ❌ | ❌ | ✅ | ✅ |
| E2EE | ✅ | ✅ | ✅ | ✅ |
| CMK | ❌ | ❌ | ❌ | ✅ |
| Audit Logs | ❌ | ❌ | ✅ | ✅ |

---

## Appendix B: References

**Official Zoom Documentation:**
- [Zoom Trust Center](https://trust.zoom.com/)
- [Zoom Support](https://support.zoom.com/)
- [Zoom Compliance Page](https://www.zoom.com/en/trust/legal-compliance/)
- [Zoom Meeting Security Guide](https://www.zoom.com/en/products/virtual-meetings/resources/securing-your-meetings/)
- [Zoom Security White Paper](https://explore.zoom.us/docs/doc/Zoom-Security-White-Paper.pdf)
- [Zoom Security Bulletins](https://www.zoom.com/en/trust/security-bulletin/)
- [Changing Security Settings in a Meeting](https://support.zoom.com/hc/en/article?id=zm_kb&sysparm_article=KB0061231)
- [Security Best Practices](https://support.zoom.com/hc/en/article?id=zm_kb&sysparm_article=KB0060720)

**API Documentation:**
- [Zoom Developer API Reference](https://developers.zoom.us/docs/api/)
- [Zoom SDKs](https://developers.zoom.us/)

**Compliance Frameworks:**
- SOC 2 Type II (Security, Availability, Confidentiality, Privacy), SOC 2 + HITRUST, ISO 27001:2013, ISO 27017, ISO 27018, ISO 27701 -- via [Zoom Trust Center](https://trust.zoom.com/)

**Third-Party Guides:**
- [Zoom Service Hardening Guide](https://socprime.com/blog/zoom-service-hardening-guide/)
- [Zoom Security Best Practices](https://www.reco.ai/hub/zoom-security-best-practices)

**Security Incidents:**
- **2020 -- Credential Stuffing / Account Sales:** Over 500,000 Zoom user accounts were compromised via credential stuffing and their details posted for sale on the dark web. This prompted significant security improvements to the platform.
- **2025 -- DLL Hijacking Vulnerability (CVE-2025-49457, CVSS 9.6):** A critical vulnerability in how the Zoom Windows client loads DLLs allowed attackers to position a malicious DLL for execution. Patched via client update. Zoom disclosed 30 vulnerabilities in 2025 (average CVSS 6.3) and 36 in 2024. Mitigated by enforcing a minimum client version -- see [1.3 Enforce a Minimum Zoom Client Version](#13-enforce-a-minimum-zoom-client-version).
- **2025 -- ELUSIVE COMET Remote-Control Campaign:** A threat actor lured cryptocurrency holders into fake podcast and media interviews on Zoom, then requested in-meeting remote control while impersonating a Zoom system prompt via a controlled display name. Victims who approved the prompt handed over keyboard and mouse control, leading to wallet theft and malware installation. Documented by [Trail of Bits](https://blog.trailofbits.com/2025/04/17/mitigating-elusive-comet-zoom-remote-control-attacks/); mitigated by [2.4 Disable and Lock Remote Control](#24-disable-and-lock-remote-control).
- **2026 -- Unauthenticated Remote Account Takeover (CVE-2026-53412, CVSS 9.8):** A critical flaw in Zoom Workplace for Windows before version 7.0.0 and the corresponding VDI client allowed unauthenticated remote attackers to take over accounts. Patched in July 2026; remediation requires upgrading the client, making minimum-version enforcement the operative control. ([The Hacker News](https://thehackernews.com/2026/07/zoom-patches-critical-windows-flaw-that.html))

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.2 | draft | Cheat-sheet cell repair: added missing Attack Prevented line(s) to §3.1 (no content-facts changed) | Claude Code (Fable 5) |
| 2026-08-08 | 0.2.1 | draft | Add first Code Packs via the Zoom REST API v2 with Server-to-Server OAuth (api/ type only — Zoom publishes no first-party CLI): 2.1 meeting-security posture verification (`GET /v2/accounts/me/settings` groups schedule_meeting/in_meeting/meeting_security plus `GET /v2/accounts/me/lock_settings` for account-level locks), 4.2 recording-security posture verification (settings `recording` group + locks). Both endpoints, scopes, and the S2S OAuth token flow fetch-verified this session against developers.zoom.us; packs are read-only verification by design since the accounts API documents no settings-update surface for these groups. Pack yml keys pending central sync | Claude Code (Fable 5) |
| 2026-08-03 | 0.2.0 | draft | Correct OAuth token lifetimes (1h access, 90d rotating refresh, S2S has none); add JWT deprecation audit to 3.1; add 1.3 minimum client version, 2.4 remote control lock (ELUSIVE COMET), 4.3 Team Chat external permissions; add CVE-2026-53412 | Claude Code (Sonnet 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Zoom hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
