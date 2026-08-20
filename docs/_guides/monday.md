---
layout: guide
title: "Monday.com Hardening Guide"
vendor: "Monday.com"
slug: "monday"
tier: "2"
category: "Productivity"
description: "Work management platform hardening for Monday.com including SAML SSO, 2FA, IP restriction, AI governance, and audit log streaming"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

Monday.com is a leading work management platform used by **millions of users** for project management, workflows, and team collaboration. As a repository for project data and business operations, Monday.com security configurations directly impact operational security and data protection.

### Intended Audience
- Security engineers managing work management platforms
- IT administrators configuring Monday.com Enterprise
- GRC professionals assessing collaboration security
- Account administrators managing access controls

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Monday.com security including SAML SSO, authentication policies, admin controls, and account security.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Account Security](#2-account-security)
3. [Access Controls](#3-access-controls)
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
Configure SAML SSO to centralize authentication for Monday.com users.

#### Rationale
**Why This Matters:**
- Centralizes Monday.com authentication in your corporate IdP, enforcing MFA and conditional access on every login
- Local email-and-password logins bypass IdP controls and are a prime target for credential stuffing and phishing
- IdP-managed provisioning and deprovisioning removes departed users automatically, eliminating orphaned accounts with standing access to project data
- Work boards hold project plans, customer records, and business operations data — a single compromised login can expose the whole account

**Attack Prevented:** Credential theft, phishing, MFA bypass, orphaned-account access

#### Prerequisites
- Monday.com Enterprise plan
- SAML 2.0 compatible IdP
- Account administrator access

#### ClickOps Implementation

**Step 1: Access Admin Section**
1. Click your profile picture (top right)
2. Select **Administration**
3. Navigate to **Security** section

**Step 2: Configure SSO**
1. Click **Single Sign-On (SSO)** in Authentication policies
2. Click **Add SSO policy**
3. Select your IdP (Okta, Azure, etc.)

**Step 3: Enter IdP Settings**
1. In **SAML SSO URL** field, paste Login URL
2. In **Identity provider issuer** field, paste Entity ID
3. In **Public certificate** field, paste Signing Certificate
4. Format hints provided for each IdP

**Step 4: Test Connection**
1. Test connection (mandatory step)
2. Verify authentication works
3. Enable SAML on account

**Time to Complete:** ~1 hour

---

### 1.2 Configure Login Restriction Policies

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2 |

#### Description
Configure login policies to enforce SSO or allow exceptions.

#### Rationale
**Why This Matters:**
- Enforcing SSO as the only login path closes the password-based side door that attackers use to skip the IdP entirely
- Unrestricted exceptions let users authenticate with weak local passwords that lack MFA and conditional access
- A tightly scoped, documented break-glass account preserves emergency access during an IdP outage without leaving a permanent bypass
- Every uncontrolled exception is a standing weakness that can be discovered and abused long after it was created

**Attack Prevented:** SSO bypass, password-based account takeover, credential stuffing, unauthorized exception abuse

#### ClickOps Implementation

**Step 1: Access Login Policies**
1. Navigate to: **Administration** → **Security**
2. Access login restriction settings

**Step 2: Configure Restrictions**
1. Customize email and password policy
2. Exclude specific users from SSO requirement if needed
3. Configure break-glass access

**Step 3: Configure Break-Glass Access**
1. Use "Guests" or "Guests and a single user" options
2. Enable for SSO provider outage scenarios
3. Document emergency procedures

---

### 1.3 Enable Monday Certificate Encryption

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-8 |

#### Description
Enable certificate encryption for SAML assertions.

#### Rationale
**Why This Matters:**
- Encrypting SAML assertions keeps identity attributes and authentication claims confidential as they pass through the browser between IdP and Monday.com
- Unencrypted assertions can be read or tampered with by anyone able to intercept the redirect, enabling identity spoofing
- Signing and encryption together ensure assertions are both authentic and unreadable, defeating replay and forgery attempts
- Protects the trust relationship at the core of SSO, where a forged assertion equals a full account login

**Attack Prevented:** SAML assertion interception, assertion tampering, identity spoofing, replay attacks

#### ClickOps Implementation

**Step 1: Configure Certificate**
1. In SAML settings, find **Enable Monday Certificate**
2. Enable the checkbox
3. This encrypts SAML assertions from IdP

**Step 2: Update IdP Configuration**
1. Download Monday.com certificate
2. Configure IdP to encrypt assertions
3. Test encrypted authentication

---

### 1.4 Configure Google SSO (Alternative)

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2 |

#### Description
Configure Google Single Sign-On (available on Pro and Enterprise).

#### Rationale
**Why This Matters:**
- Google SSO centralizes authentication so login security inherits your Google Workspace MFA and policy controls
- Restricting to organizational Google accounts blocks sign-in from personal Gmail addresses that the organization cannot govern or revoke
- Centralized login lets administrators disable a Google account once and cut off Monday.com access immediately
- Without domain restriction, anyone with a personal Google account could establish an unmanaged foothold in the workspace

**Attack Prevented:** Unauthorized personal-account access, unmanaged account sprawl, orphaned-account access, credential theft

#### ClickOps Implementation

**Step 1: Enable Google SSO**
1. Navigate to: **Administration** → **Security** → **SSO**
2. Enable Google Single Sign-On

**Step 2: Configure Domain Restriction**
1. Restrict to organizational Google accounts
2. Block personal accounts
3. Test authentication

---

### 1.5 Enable Two-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 6.4 |
| NIST 800-53 | IA-2(1), IA-2(2) |

#### Description
Enable account-wide Two-Factor Authentication in the Administration → Security → Authentication tab and require it for members, guests, or both, so password-based logins carry a second factor. Available on all monday.com plans; only admins can enable it for the account.

#### Rationale
**Why This Matters:**
- 2FA is the one strong-authentication control available on every monday.com plan, including the plans that cannot buy SAML SSO
- Password-only logins fall to credential stuffing and phishing; a second factor blocks reuse of a breached password outright
- 2FA can be required for **guests** as well as members, closing the common gap where external collaborators authenticate more weakly than staff
- Where SSO covers members, requiring 2FA for guests keeps the non-SSO population from becoming the soft entry point

**Attack Prevented:** Credential stuffing, password reuse, phishing of static credentials, weak guest authentication

#### ClickOps Implementation

**Step 1: Enable 2FA for the Account**
1. Click your profile picture (top right) → **Administration** → **Security**
2. Open the **Authentication** tab
3. Under **Two-Factor Authentication**, click **Add two-factor authentication**
4. Choose your own method — authentication app or text message (SMS)

**Step 2: Choose Who It Applies To**
1. Once enabled, select whether 2FA is required for **members**, **guests**, or **both**
2. Members and guests are prompted to complete 2FA setup on their next login
3. Each person chooses their own method

**Step 3: Prefer Authenticator Apps**
1. SMS is not available on free or trial accounts, and is the weaker of the two methods (SIM-swap and interception risk)
2. Standardize on an authenticator app and treat SMS as a fallback only

#### Validation & Testing
Log in as a test member and confirm the 2FA prompt appears. Admins can reset a person's 2FA method at **Administration → Directory → Users** via the three-dot menu — restrict who holds admin rights accordingly, since 2FA reset is an account-takeover path. Source: [Two-Factor Authentication](https://support.monday.com/hc/en-us/articles/360000787745-Two-Factor-Authentication) (content verified via the vendor's help-center API, 2026-08).

---

## 2. Account Security

### 2.1 Restrict Account Membership

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Control who can join your Monday.com account.

#### Rationale
**Why This Matters:**
- Restricting account membership prevents unauthorized self-signup that would silently grant outsiders access to internal boards
- Just-In-Time provisioning creates accounts automatically on first login, so an over-broad join policy can spawn unmanaged users
- Explicit provisioning gives administrators a deliberate gate over who exists in the account and what they can see
- Every uncontrolled member is an additional attack surface and a potential path to project and customer data

**Attack Prevented:** Unauthorized account access, uncontrolled JIT account creation, account sprawl, data exposure to outsiders

**Authorized domain and invitation rights are two separate settings — do not conflate them.** monday.com's documentation is explicit: "Authorized domain controls who can join without an invitation. Who can send invitations is a separate setting." On a new account the creator's email domain is authorized automatically, and by default members can invite people from *any* domain unless an admin restricts invitations. Locking down one and leaving the other open still leaves an open door. Review both under **Administration → Security**. Note also that activating SSO disables the **Authorized Domain** option — access is then governed by the IdP plus the Email and password policy. Source: [Restrict who can join your account](https://support.monday.com/hc/en-us/articles/115005319589-Restrict-who-can-join-your-account) (content verified via the vendor's help-center API, 2026-08).

#### ClickOps Implementation

**Step 1: Configure the Authorized Domain**
1. Navigate to: **Administration** → **Security** → **Authentication** tab
2. Expand **Authentication policies**, click the three-dot menu next to **Email and password**, and select **Edit**
3. Enable **Authorized Domain** and enter your corporate domain

**Step 2: Restrict Who Can Invite**
1. In the same Security area, restrict invitation rights — leaving invitations open lets members invite from any domain regardless of the authorized domain
2. Decide deliberately whether members may invite at all, or whether invitations are admin-only

**Step 3: Control Guest Domains (Enterprise)**
1. On Enterprise, admins control which email domains guests can be invited from, with three options: **Approve any domain** (the default), **Approve specific domains**, and **Don't approve specific domains**
2. Move off the default — "Approve any domain" places no restriction whatsoever on guest email domains
3. Note that a guest must have a different email domain from the account's first user in order to be invited at all

**Step 4: Use JIT Provisioning Deliberately**
1. Monday.com uses Just-In-Time provisioning by default
2. Users created on first login if they don't exist
3. Consider disabling for explicit provisioning

---

### 2.2 Configure Session Duration

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Set an account-wide session duration so users are logged out automatically — either after a period of inactivity or on a fixed interval regardless of activity — and keep the immediate force-logout capability available for incident response. Enterprise plan, admin only.

#### Rationale
**Why This Matters:**
- Bounded session duration limits how long an abandoned or unlocked session stays usable, shrinking the window for hijacking
- Long-lived sessions on shared or unattended devices let anyone resume an authenticated session without re-authenticating
- Forcing periodic re-authentication ensures revoked or deprovisioned access actually takes effect on active sessions
- The immediate "log out all users" action is a first-move containment control when an account compromise is suspected

**Attack Prevented:** Session hijacking, unattended-device access, stolen-token reuse, lingering-session abuse

**Correction (2026-08): this is an Enterprise-only control, and its granularity is days — not minutes.** Earlier revisions of this guide presented session timeout as an L1 control available to all plans with an arbitrary timeout value. monday.com's documented options are a **No-activity timeout** of 5, 10, or 15 days, and a separate **Session expired** interval that logs out all users whether active or not. Plan accordingly: on non-Enterprise plans there is no session-duration control at all, and even on Enterprise the shortest inactivity window is five days — so treat 2FA (1.5), IP restriction (2.4), and device hygiene as the compensating controls rather than assuming a tight session bound. Source: [How to set a session duration on your account](https://support.monday.com/hc/en-us/articles/4410500266514-How-to-set-a-session-duration-on-your-account) (content verified via the vendor's help-center API, 2026-08).

#### Prerequisites
- Enterprise plan
- Account admin

#### ClickOps Implementation

**Step 1: Access Session Settings**
1. Click your profile picture (top right) → **Administration**
2. Navigate to: **Security** → **Advanced** tab

**Step 2: Set the Inactivity Timeout**
1. Under **No-activity timeout**, select logout after 5, 10, or 15 days with no activity
2. Click **Confirm**

**Step 3: Set the Absolute Session Limit**
1. Under **Session expired**, select an interval that logs out all users regardless of activity, then **Confirm**
2. Be aware that all users are logged out immediately when the interval elapses
3. To remove either limit, set **never logout automatically** for that option

**Step 4: Keep Force-Logout Available for Incidents**
1. Navigate to: **Administration** → **Security** → **Sessions** tab
2. Use the immediate log-out-all-users action if you suspect the account has been compromised

#### Validation & Testing
Confirm the configured values persist in **Security → Advanced**, and rehearse the **Sessions** force-logout as part of your incident runbook alongside the Panic Button (2.5).

---

### 2.3 Manage Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect administrator accounts.

#### Rationale
**Why This Matters:**
- Admin accounts can change security settings, manage users, and access every board, so each one is a high-value target
- Limiting admins to a small, documented set reduces the blast radius if any single admin credential is compromised
- Regular review removes lingering admin rights from users who no longer need them, closing privilege-creep gaps
- A compromised admin can disable SSO, exfiltrate data, and lock out legitimate users — minimizing their number contains that risk

**Attack Prevented:** Privilege escalation, admin-account takeover, insider abuse, security-control tampering

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Navigate to: **Administration** → **Users**
2. Review administrator accounts
3. Document all admins

**Step 2: Apply Least Privilege**
1. Limit admins to 2-3 users
2. Remove unnecessary admin access
3. Review quarterly

---

### 2.4 Restrict Access by IP Address

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 12.2, 13.4 |
| NIST 800-53 | AC-3, AC-17, SC-7 |

#### Description
Define an allowed list of IP addresses or CIDR ranges under Administration → Security → IP address restriction so account logins only succeed from approved networks. Enterprise plan, admins only.

#### Rationale
**Why This Matters:**
- A network-layer allowlist turns a stolen password or session into a failure unless the attacker is also inside an approved network
- It is the strongest available compensating control given monday.com's day-granularity session duration (2.2)
- The mobile app is bound by the same restriction, so the control is not trivially bypassed by switching clients
- Paired with tenant-level restrictions (2.7), it constrains both *where* your account can be reached from and *which* monday.com accounts your network can reach

**Attack Prevented:** Credential-replay from attacker infrastructure, off-network account access, session reuse outside approved locations

**Shared views and Forms are NOT covered by the allowlist.** monday.com states plainly that "shared views are not restricted to the IP's added to the allowed list. Therefore, everyone that has a link to a shared view will be able to view them, regardless of their IP address," and that "links to monday Forms are also not restricted." Anything published as a shared view or Form is reachable from anywhere with the link — govern those through sharing controls (3.1), not through this control. Source: [How to set up IP restrictions on an account](https://support.monday.com/hc/en-us/articles/360020408039-How-to-set-up-IP-restrictions-on-an-account) (content verified via the vendor's help-center API, 2026-08).

#### Prerequisites
- Enterprise plan
- Account admin, with the admin's own current IP included in the list

#### ClickOps Implementation

**Step 1: Build the Allowed List First**
1. Click your profile picture (top right) → **Administration**
2. Navigate to: **Security**, then expand **IP address restriction**
3. Add each entry with a descriptive name (for example "Office", "VPN egress") and its IP address; use CIDR notation for ranges
4. Click **Add** for each entry — add everything *before* activating

**Step 2: Activate**
1. Select the checkbox above the list, then click **Activate**
2. Activation fails if your own IP is not on the list — this is the built-in lockout guard, not a bug to work around

**Step 3: Account for Integrations**
1. Third-party apps and platforms integrating with the account need their IPs added, or the integration breaks
2. For monday code apps, enable the Static IPs feature for the app and allow the published monday code IP addresses

#### Validation & Testing
Attempt a login from an address outside the list and confirm it is refused, including from the mobile app. Then confirm a known shared view is still reachable off-network — that is expected behavior, and it should drive a review of what is published as a shared view.

---

### 2.5 Prepare the Panic Button for Incident Lockdown

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 17.4 |
| NIST 800-53 | IR-4, AC-2(13) |

#### Description
Know where the Panic Button lives and what it costs before you need it. Activating Panic mode blocks the entire monday.com account so that no one — including account admins — can access it until an admin contacts monday.com support and receives unblock instructions. Enterprise plan, admins only.

#### Rationale
**Why This Matters:**
- When credentials are known to be compromised, an account-wide freeze stops exfiltration faster than chasing individual sessions and users
- Because recovery requires a vendor support round-trip, the decision to activate must be pre-authorized — discovering the recovery path mid-incident wastes the time the control was meant to buy
- Only account admins can request the unblock, so a lockdown with no reachable admin is an outage with no exit
- Documented alongside the Audit Log (4.1), it gives responders a detect-then-contain pair rather than detection alone

**Attack Prevented:** Ongoing exfiltration during an active compromise, continued attacker access after credential theft, uncontrolled blast radius while triage is underway

#### Prerequisites
- Enterprise plan
- Account admin able to contact monday.com support for recovery

#### ClickOps Implementation

**Step 1: Locate the Control**
1. Click your profile picture (top right) → **Administration**
2. Navigate to: **Security** → **Advanced**
3. The red **Activate Panic mode** button is here — confirm the path now, not during an incident

**Step 2: Pre-Authorize and Document**
1. Record in the incident runbook who is authorized to activate Panic mode and on what trigger
2. Record the support contact route for recovery, and name at least two admins who can initiate it
3. Note the confirmation step ("Yes, activate Panic mode") — there is no self-service undo

#### Validation & Testing
Do not test in production. Validate by tabletop: walk the runbook end to end, confirming both the activation path and a named admin's ability to reach monday.com support. Source: [The Panic Button](https://support.monday.com/hc/en-us/articles/360003250699-The-Panic-Button) (content verified via the vendor's help-center API, 2026-08).

---

### 2.6 Evaluate the Guardian Add-On

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11, 3.13 |
| NIST 800-53 | SC-12, SC-13, SC-28, SI-4 |

#### Description
For regulated data, evaluate the Enterprise-only Guardian add-on, which supplies Tenant-Level Encryption with a dedicated periodically rotated key, Bring Your Own Key, Data Leak Prevention scanning of updates and uploaded files, and support for multiple SSO vendors on one account.

#### Rationale
**Why This Matters:**
- Tenant-Level Encryption gives the account its own exclusive, separately stored, periodically rotated key rather than shared platform encryption
- BYOK moves key lifecycle control to the customer — including the ability to revoke access — which is what most regulated-industry key-management requirements actually ask for
- DLP scanning of updates and uploaded files catches PII and payment data being pasted into boards, a leakage path no permission setting addresses
- Multiple SSO vendors on one account resolves the post-merger and multi-region case where a single IdP cannot cover the whole population

**Attack Prevented:** Unauthorized access to data at rest without customer-controlled keys, undetected exposure of PII/PHI/payment data in board content, weak authentication for populations outside the primary IdP

**Correction (2026-08): "multiple IdPs cannot be connected to one monday.com account" is no longer accurate.** Guardian's Multiple SSOs capability allows configuring multiple SSO vendors within the same account. Without Guardian, the single-IdP limitation still applies. Source: [Guardian add-on](https://support.monday.com/hc/en-us/articles/25276756886674-Guardian-add-on) (content verified via the vendor's help-center API, 2026-08).

#### Prerequisites
- Enterprise plan
- Guardian add-on purchased (contact your account contact)

#### ClickOps Implementation

**Step 1: Scope the Requirement**
1. Determine whether your obligations require customer-managed keys (BYOK) or content-level DLP — if neither, Guardian is not required
2. Confirm whether more than one IdP must serve the account (mergers, multi-region entities)

**Step 2: Enable and Configure**
1. Engage your monday.com account contact to add Guardian to the account
2. For DLP, define the scanning parameters that monitor updates and uploaded files against your policy (for example PII and payment details)
3. For BYOK, establish key lifecycle ownership — creation, rotation, and revocation — inside your existing KMS process
4. For Multiple SSOs, configure each additional SSO vendor and map its population

#### Validation & Testing
Post a test string matching your DLP policy into a board update and confirm it is flagged. For BYOK, rehearse key revocation in a non-production account and confirm the expected loss of access.

---

### 2.7 Pin Hosting Region and Apply Tenant-Level Restrictions

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 12.2, 13.4 |
| NIST 800-53 | SC-7, AC-4, SA-9 |

#### Description
Choose the account's hosting region (EU, US, or APAC) deliberately at account setup, and have network administrators apply tenant-level restrictions so devices on the corporate network can only reach approved monday.com accounts.

#### Rationale
**Why This Matters:**
- Hosting region is a setup-time decision that determines which jurisdiction's laws govern the data — it is not a toggle you flip later
- Tenant-level restrictions stop the "personal monday.com account" exfiltration path: without them, a user on the corporate network can move data into an account you do not control
- The restriction covers page loads, API requests, SCIM requests, and Form submissions, so it closes the programmatic routes as well as the browser
- Combined with IP restriction (2.4), it constrains both directions: which networks may reach your account, and which accounts your network may reach

**Attack Prevented:** Data movement into unmanaged monday.com tenants, form-based exfiltration to third-party accounts, jurisdictional exposure from an unconsidered hosting region

#### Prerequisites
- Enterprise plan
- Network administration control over an on-premises or cloud SSL proxy
- Your monday.com account ID(s) — available from your CSM

#### ClickOps Implementation

**Step 1: Choose the Hosting Region at Setup**
1. monday.com offers hosting in the **EU**, **US**, or **APAC** regions
2. Select the region against your regulatory obligations before the account is provisioned — review this as part of account setup, which should be performed only by an authorized member of the organization

**Step 2: Apply Tenant-Level Restrictions**
1. Configure the organization's SSL proxy to inject the `x-monday-allowed-accounts` HTTP header on all requests leaving the network
2. Set the header value to a comma-delimited list of the allowed monday.com account IDs
3. Access attempts to any account outside the list — including Form submissions from other accounts — will fail

**Step 3: Record the Limitation**
1. Tenant-level restrictions depend on the request originating from the organization's network, so features routed through third-party services (Slack and GitHub integration webhooks, Email to Board) can still reach non-permitted accounts
2. Treat those paths as out of scope for this control and govern them through integration security (3.3)

#### Validation & Testing
From a device on the restricted network, attempt to load an unapproved monday.com account and confirm the block screen appears. Sources: [Tenant-level restrictions](https://support.monday.com/hc/en-us/articles/8491691268754-Tenant-level-restrictions), [monday.com secure configuration checklist](https://support.monday.com/hc/en-us/articles/34336185460498-monday-com-secure-configuration-checklist) (content verified via the vendor's help-center API, 2026-08).

---

## 3. Access Controls

### 3.1 Configure Workspace Permissions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Configure permissions across workspaces and boards.

#### Rationale
**Why This Matters:**
- Scoping workspace and board access to the people who need it enforces least privilege and limits who can see sensitive project data
- Default-open or over-shared boards expose plans, customer details, and operational data to users far beyond the intended audience
- Viewer-only access for stakeholders prevents accidental or malicious edits while still supporting visibility
- Tight permissions contain lateral movement, so a single compromised account cannot reach every board in the account

**Attack Prevented:** Unauthorized data access, over-sharing, lateral movement, accidental or malicious data modification

#### ClickOps Implementation

**Step 1: Configure Workspace Access**
1. Organize by team or function
2. Set workspace-level permissions
3. Control board visibility

**Step 2: Configure Board Permissions**
1. Set appropriate board permissions
2. Restrict editing to necessary users
3. Use viewer access for stakeholders

---

### 3.2 Configure Guest Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control guest access to workspaces and boards.

#### Rationale
**Why This Matters:**
- Guests are external collaborators outside your identity governance, so their access must be scoped to only the boards they truly need
- Over-permissioned guests can view or edit internal project data that should never leave the organization
- Board-level restrictions and activity monitoring catch guest accounts being misused or left active after a project ends
- Each unrestricted guest is a potential data-leakage path and a lower-trust account that attackers may target

**Attack Prevented:** Data leakage to external parties, guest-account abuse, over-privileged external access, lingering guest access

#### ClickOps Implementation

**Step 1: Restrict Which Domains Guests Can Come From (Enterprise)**
1. Navigate to: **Administration** → **Security**
2. Choose the guest domain policy: **Approve any domain** (the default — no restriction at all), **Approve specific domains** (an allowlist), or **Don't approve specific domains** (a denylist)
3. Prefer **Approve specific domains** and enumerate the partner domains you actually work with
4. Remember that the authorized-domain setting and the invitation-rights setting are separate controls (see 2.1) — a guest domain policy does not restrict who may send invitations

**Step 2: Configure Guest Settings**
1. Configure guest permissions in the same Security area
2. Require 2FA for guests as well as members (see 1.5)

**Step 3: Restrict Guest Capabilities**
1. Limit what guests can see/edit
2. Configure board-level guest access
3. Monitor guest activity in the Audit Log (4.1)

#### Validation & Testing
Attempt to invite a guest from a domain outside the approved list and confirm the invitation is rejected. Source: [Restrict who can join your account](https://support.monday.com/hc/en-us/articles/115005319589-Restrict-who-can-join-your-account) (content verified via the vendor's help-center API, 2026-08).

---

### 3.3 Configure Integration Security

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Control third-party integrations and apps.

#### Rationale
**Why This Matters:**
- Third-party apps and integrations request OAuth scopes that can read or modify board data, making them a direct supply-chain attack surface
- Limiting who can install apps prevents employees from connecting unvetted tools that quietly siphon project data
- Reviewing granted permissions and removing unused integrations shrinks the set of external services holding tokens to your account
- A compromised or malicious integration can exfiltrate data continuously without ever triggering a user login alert

**Attack Prevented:** Malicious or compromised app installs, OAuth scope abuse, supply-chain data exfiltration, token theft

**Correction (2026-08): monday.com has no app allowlist — governance is an approval queue, not a catalog.** Account admins are the only users who can install apps. When a non-admin attempts an install, *all* admins are notified by email, bell notification, and the marketplace **Manage apps → Pending installs** queue, and the app is not installed until an admin approves it. There is no mechanism to pre-approve a catalog of permitted apps, so the control depends entirely on admins reviewing each request — including the app's requested permissions on its listing page — rather than on a standing allowlist. Source: [How to manage apps on your account](https://support.monday.com/hc/en-us/articles/15265913506450-How-to-manage-apps-on-your-account) (content verified via the vendor's help-center API, 2026-08).

#### ClickOps Implementation

**Step 1: Review Installed Integrations**
1. Navigate to: **Administration** → **Apps** → **Installed apps**
2. Review installed integrations and their plans
3. Uninstall what is unnecessary (admins only), then delete any orphaned automations left behind in the Autopilot Hub — uninstalling an app does not remove automations built with it

**Step 2: Work the Approval Queue**
1. Open **monday marketplace → Manage apps → Pending installs**
2. For each request, click **View app**, review the app's permissions on its listing page, and check **User requests** to see who asked and why
3. **Approve** or deny — approving makes the app installable by other users too, so treat approval as an organization-wide decision

**Step 3: Scope Apps to Workspaces**
1. In **Administration → Apps → Installed apps**, click the three dots next to an app and select **Permissions**
2. Add the app to all workspaces or only specific ones — scope integrations to the workspaces that need them rather than the whole account

**Step 4: Delegate App Administration Safely (Enterprise)**
1. Enterprise admins can create a custom role for app administration instead of granting full admin
2. Navigate to: **Administration → Permissions → Member** tab, check **Access the Apps section** under Admin Privileges, then **New role**
3. Assign the role at **Administration → Directory → Users** via the User role dropdown

#### Validation & Testing
As a non-admin, request an app install and confirm the admin notification and pending-install entry appear, and that the app is unavailable until approved. Audit the full integration inventory at **Administration → Connections → Automation connections**.

---

### 3.4 Govern AI Permissions and Agents

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 5.4 |
| NIST 800-53 | AC-3, AC-6, CM-7 |

#### Description
Use the Administration → AI governance section to decide whether AI is enabled on the account at all, and — on Enterprise — which account roles may use each agent type and AI feature, which workspaces those features operate in, and how AI credit consumption is monitored.

#### Rationale
**Why This Matters:**
- AI agents and features read board data to operate, so an unscoped rollout puts every workspace's content in scope for AI processing
- The **Enable AI features** master toggle is available on all plans and is the only AI control non-Enterprise accounts have — knowing that prevents a false assumption of granular governance
- Role-based grants per agent type (user agents, monday agents, third-party agents, org agents, external AI connectors) let you admit first-party agents while excluding third-party ones
- Workspace-level scoping for AI Sidekick and AI Blocks keeps AI out of workspaces holding regulated or sensitive boards
- Credit monitoring surfaces anomalous AI consumption, which is both a cost signal and a usage-pattern signal

**Attack Prevented:** Uncontrolled AI processing of sensitive board content, third-party agent access to workspace data, shadow AI usage inside a sanctioned tool

#### Prerequisites
- Account admin
- Enterprise plan for everything beyond the master enable/disable toggle

#### ClickOps Implementation

**Step 1: Decide Whether AI Runs at All**
1. Click your profile picture (top right) → **Administration**
2. Navigate to: **AI governance** → **AI permissions**
3. Set **Enable AI features** to On or Off — this toggle is available on all plans; every other setting on this tab is Enterprise-only

**Step 2: Scope Agents by Role (Enterprise)**
1. In the **AI agents** section, set each agent type — user agents, monday agents, third-party agents, org agents, external AI connectors — to **Selected Roles** and choose which account roles may use it
2. Set permissions for a specific agent or inherit from the parent level, depending on how granular you need to be
3. Treat third-party agents and external AI connectors as the highest-scrutiny categories

**Step 3: Scope Features by Role and Workspace (Enterprise)**
1. For each AI feature, select **Selected Roles** and choose the permitted roles
2. For **AI Sidekick** and **AI Blocks**, additionally choose whether the feature is enabled in all workspaces, enabled in selected workspaces, or disabled in selected workspaces
3. Note that changing permissions does not stop AI blocks or agents that are already running — audit existing automations separately

**Step 4: Monitor Consumption**
1. Open the **Credits** tab to review credit usage for the current billing cycle and drill into where credits are spent
2. Set usage limits and treat unexplained spikes as an investigation trigger

#### Validation & Testing
Sign in as a user in an excluded role and confirm the corresponding agent or AI feature is unavailable. Source: [AI Permissions and Governance](https://support.monday.com/hc/en-us/articles/30934592475410-AI-Permissions-and-Governance) (content verified via the vendor's help-center API, 2026-08).

---

### 3.5 Control Personal API Tokens

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2, 6.8 |
| NIST 800-53 | IA-5, AC-6 |

#### Description
Inventory personal API tokens, treat them as full-privilege credentials, and regenerate them on a defined cadence and on every role change or suspected exposure. Admins can view personal API tokens under Administration → Connections.

#### Rationale
**Why This Matters:**
- A monday.com personal API token carries **all** permission scopes of the user who owns it — its authorization mirrors exactly what that person can reach in the UI, so an admin's token is an admin-equivalent credential
- Personal tokens have no documented expiry, so a token leaked into a script, CI log, or notebook stays valid indefinitely until someone acts
- Regeneration is the revocation mechanism: regenerating immediately invalidates the previous token, which is also why rotation breaks any integration still holding the old value
- Tokens bypass the interactive login path, so 2FA (1.5) does not protect an API call made with a stolen token

**Attack Prevented:** Token theft and replay, over-privileged programmatic access, persistent unauthorized API access after offboarding, credential leakage via code and logs

#### ClickOps Implementation

**Step 1: Inventory Tokens**
1. As an admin, click your profile picture (top right) → **Administration** → **Connections** → **Personal API token**
2. Individual users find their own token at the profile icon → **Developers** → **API token** → **Show**
3. Pay particular attention to tokens held by admins — those tokens inherit admin reach

**Step 2: Prefer Scoped App Tokens for Integrations**
1. Where an integration can authenticate as an app with declared permission scopes, use that instead of a personal token
2. Reserve personal tokens for interactive and short-lived use, not for production automation owned by an individual

**Step 3: Rotate and Revoke**
1. Regenerate a token to invalidate the current one — this is the only revocation path, and it takes effect immediately
2. Regenerate on role change, on offboarding, and on any suspected exposure
3. Update every dependent integration at the same time, since regeneration breaks anything still using the old token

#### Validation & Testing
Regenerate a test user's token and confirm an API call with the previous value is rejected. Source: [Authentication](https://developer.monday.com/api-reference/docs/authentication).

---

## 4. Monitoring & Compliance

### 4.1 Configure Audit Logging

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Monitor account activity through the Audit Log, and use the Audit Log API to stream those events into a SIEM for correlation and alerting. The Audit Log and its API are Enterprise-plan features accessible only to the account admin.

#### Rationale
**Why This Matters:**
- Audit logs record logins, permission changes, admin actions, and SSO configuration changes, providing the evidence trail to detect abuse
- Without logging, account compromise and insider misuse go unnoticed until damage is already done
- Reviewable history enables incident investigation, forensics, and root-cause analysis after a security event
- Audit records also satisfy compliance and accountability requirements for who did what and when

**Attack Prevented:** Undetected account compromise, insider misuse, unauthorized configuration changes, evidence tampering

**Records are not time-deleted, but that is a vendor statement, not a contract.** monday.com documents that "audit log records will not be deleted after a certain amount of time. This may change in the future, though." Stream events to your own SIEM rather than relying on the platform as your system of record. Note also that Audit Log timestamps are always presented in GMT — normalize on ingest or your correlation windows will be wrong.

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Click your profile picture (top right) → **Administration**
2. Navigate to: **Security** → **Audit** tab
3. Review logged events; filter by **User name** or by **Event type**

**Step 2: Monitor Key Events**
1. Logins and failed logins, including device and source IP per session
2. Permission changes and admin actions
3. Attachment downloads and board-data exports
4. SSO configuration changes

**Step 3: Stream to a SIEM via the Audit Log API**
1. In **Administration → Security → Audit**, click **Monitor by API** to generate the audit API token, and store it as a secret
2. Query `https://<YOUR_DOMAIN>.monday.com/audit-api/get-logs` with the token as a bearer authorization header (REST, GET, paginated via `page` and `per_page`)
3. Filter with `user_id`, `event`, `ip_address`, `start_time`, and `end_time` as query parameters
4. Respect the documented rate limit of 50 requests per minute when sizing the polling job
5. Alert on collector failure — a silently broken pull means no monday.com telemetry reaches detection

#### Validation & Testing
Trigger a known auditable action (a failed login, then a board export) and confirm both appear in the Audit Log UI and in the SIEM within your expected latency. Sources: [The Audit Log](https://support.monday.com/hc/en-us/articles/360001259429-The-Audit-Log), [Audit Log API](https://support.monday.com/hc/en-us/articles/4406042650002-Audit-Log-API) (content verified via the vendor's help-center API, 2026-08).

---

### 4.2 Configure Data Export Controls

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Control ability to export data from Monday.com.

#### Rationale
**Why This Matters:**
- Bulk export turns dispersed board data into a single portable file, so unrestricted export is a fast path to mass data exfiltration
- Limiting who can export and monitoring export activity deters and detects both insider theft and compromised-account abuse
- Requiring documented approval for exports creates accountability around data leaving the platform
- A departing employee or attacker with export rights can walk away with the entire project and customer dataset in one action

**Attack Prevented:** Data exfiltration, insider data theft, bulk data extraction, unauthorized data movement

#### ClickOps Implementation

**Step 1: Configure Export Settings**
1. Navigate to: **Administration** → **Security**
2. Configure export permissions

**Step 2: Restrict Exports**
1. Limit who can export data
2. Monitor export activity
3. Document approved exports

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Monday.com Control | Guide Section |
|-----------|-------------------|---------------|
| CC6.1 | SSO/SAML | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Admin access | [2.3](#23-manage-admin-access) |
| CC6.6 | Session security | [2.2](#22-configure-session-security) |
| CC6.7 | Certificate encryption | [1.3](#13-enable-monday-certificate-encryption) |
| CC7.2 | Audit logging | [4.1](#41-configure-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | Monday.com Control | Guide Section |
|---------|-------------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| AC-2 | Membership | [2.1](#21-restrict-account-membership) |
| AC-3 | Guest access | [3.2](#32-configure-guest-access) |
| AC-6 | Permissions | [3.1](#31-configure-workspace-permissions) |
| AU-2 | Audit logging | [4.1](#41-configure-audit-logging) |

---

## Appendix A: Plan Compatibility

| Feature | Free | Basic | Standard | Pro | Enterprise |
|---------|------|-------|----------|-----|------------|
| Two-factor authentication (1.5) | ✅ (app only) | ✅ | ✅ | ✅ | ✅ |
| Google SSO | ❌ | ❌ | ❌ | ✅ | ✅ |
| SAML SSO | ❌ | ❌ | ❌ | ❌ | ✅ |
| Session duration (2.2) | ❌ | ❌ | ❌ | ❌ | ✅ |
| IP address restriction (2.4) | ❌ | ❌ | ❌ | ❌ | ✅ |
| Panic Button (2.5) | ❌ | ❌ | ❌ | ❌ | ✅ |
| Guardian add-on: TLE/BYOK, DLP, Multiple SSOs (2.6) | ❌ | ❌ | ❌ | ❌ | Add-on |
| Tenant-level restrictions (2.7) | ❌ | ❌ | ❌ | ❌ | ✅ |
| Guest email-domain policy (3.2) | ❌ | ❌ | ❌ | ❌ | ✅ |
| Custom app-admin roles (3.3) | ❌ | ❌ | ❌ | ❌ | ✅ |
| Enable AI features toggle (3.4) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Granular AI permissions and workspace scoping (3.4) | ❌ | ❌ | ❌ | ❌ | ✅ |
| Audit Log + Audit Log API (4.1) | ❌ | ❌ | ❌ | ❌ | ✅ |
| Admin Controls | ❌ | ❌ | ✅ | ✅ | ✅ |

**Notes:**
- 2FA is available on all plans, but SMS as a second factor is not available on free or trial accounts — use an authenticator app.
- A single monday.com account supports one SSO vendor by default. The Enterprise **Guardian** add-on adds Multiple SSOs, allowing several SSO vendors on the same account (see 2.6).
- Hosting region (EU / US / APAC) is selected at account setup, not changed later (see 2.7).

---

## Appendix B: References

**Official Monday.com Documentation:**
- [Monday.com Help Center](https://support.monday.com/hc/en-us)
- [monday.com secure configuration checklist](https://support.monday.com/hc/en-us/articles/34336185460498-monday-com-secure-configuration-checklist)
- [SAML Single Sign-on](https://support.monday.com/hc/en-us/articles/360000460605-SAML-Single-Sign-on)
- [Custom SAML 2.0](https://support.monday.com/hc/en-us/articles/360000461565-Custom-SAML-2-0)
- [Two-Factor Authentication](https://support.monday.com/hc/en-us/articles/360000787745-Two-Factor-Authentication)
- [Restrict Who Can Join](https://support.monday.com/hc/en-us/articles/115005319589-Restrict-who-can-join-your-account)
- [How to set a session duration on your account](https://support.monday.com/hc/en-us/articles/4410500266514-How-to-set-a-session-duration-on-your-account)
- [How to set up IP restrictions on an account](https://support.monday.com/hc/en-us/articles/360020408039-How-to-set-up-IP-restrictions-on-an-account)
- [The Panic Button](https://support.monday.com/hc/en-us/articles/360003250699-The-Panic-Button)
- [Guardian add-on](https://support.monday.com/hc/en-us/articles/25276756886674-Guardian-add-on)
- [Tenant-level restrictions](https://support.monday.com/hc/en-us/articles/8491691268754-Tenant-level-restrictions)
- [How to manage apps on your account](https://support.monday.com/hc/en-us/articles/15265913506450-How-to-manage-apps-on-your-account)
- [AI Permissions and Governance](https://support.monday.com/hc/en-us/articles/30934592475410-AI-Permissions-and-Governance)
- [The Audit Log](https://support.monday.com/hc/en-us/articles/360001259429-The-Audit-Log)
- [Audit Log API](https://support.monday.com/hc/en-us/articles/4406042650002-Audit-Log-API)

monday.com's help center returns HTTP 403 to non-browser fetchers. Every `support.monday.com` article above was content-verified through monday.com's own first-party help-center API (`support.monday.com/api/v2/help_center/...`, published non-draft article bodies) in 2026-08; the human-readable article URLs are cited here.

**API Documentation:**
- [Monday.com API Reference](https://developer.monday.com/api-reference/)
- [Authentication (API tokens and scopes)](https://developer.monday.com/api-reference/docs/authentication)
- [Monday.com Developer Documentation](https://developer.monday.com/)

**Compliance Frameworks:**
- [Monday.com Frameworks, Standards and Certifications](https://support.monday.com/hc/en-us/articles/360000769869-monday-com-Frameworks-Standards-and-Certifications) — current certification scope

**Security Incidents:**
- No major public security incidents identified for Monday.com as of this revision. The platform maintains a managed private bug bounty program.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | ai-drafted | Currency pass: corrected 2.2 session duration to Enterprise-only with day-granularity options (was presented as an all-plan L1 control), corrected 3.3 app governance to an approval-queue model (no allowlist exists), corrected the "multiple IdPs cannot be connected" note (Guardian adds Multiple SSOs); added 1.5 two-factor authentication, 2.4 IP address restriction (with the verbatim shared-views/Forms carve-out), 2.5 Panic Button, 2.6 Guardian add-on, 2.7 hosting region + tenant-level restrictions, 3.4 AI permissions and governance, 3.5 personal API tokens; added guest email-domain policy to 2.1/3.2 and Audit Log API SIEM streaming to 4.1; rebuilt Appendix A and removed Trust Center sources from Appendix B. support.monday.com articles 403 non-browser fetchers and were content-verified via monday.com's first-party help-center API. Tier 2: no CIS Benchmark, DISA STIG, or CISA SCuBA baseline exists for monday.com (confirmed zero). Tier 3/4: not surveyed in this pass. | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | ai-drafted | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | ai-drafted | Initial guide with SSO, authentication policies, and admin controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
