---
layout: guide
title: "JumpCloud Hardening Guide"
vendor: "JumpCloud"
slug: "jumpcloud"
tier: "2"
category: "Identity"
description: "Cloud directory and identity management hardening for JumpCloud SSO, MFA, and device management"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-08-08"
---

## Overview

JumpCloud is a cloud-based directory platform providing identity management, SSO, MFA, and device management for **over 200,000 organizations**. As a unified directory replacing traditional Active Directory, JumpCloud security configurations directly impact access control across all integrated resources including systems, applications, and networks.

### Intended Audience
- Security engineers managing JumpCloud deployments
- IT administrators configuring directory policies
- GRC professionals assessing identity controls
- Third-party risk managers evaluating directory services

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers JumpCloud Admin Portal security, MFA policies, conditional access, device management, and system policies.

---

## Table of Contents

1. [Admin Account Security](#1-admin-account-security)
2. [Multi-Factor Authentication](#2-multi-factor-authentication)
3. [Conditional Access](#3-conditional-access)
4. [Device & System Management](#4-device--system-management)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Admin Account Security

### 1.1 Secure Admin Portal Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Secure JumpCloud Admin Portal access with MFA and role-based access controls. Admin accounts with unrestricted access are high-value targets.

#### Rationale
**Why This Matters:**
- Admin Portal controls all identity and access settings
- Compromised admin can disable security controls
- Admin MFA is a capability you must configure, not a guaranteed default — JumpCloud's own best-practices guidance lists securing Admin Portal access with MFA as a recommendation, which means an unconfigured tenant is an unprotected one

**Attack Prevented:** Admin Portal account takeover, credential stuffing against directory administrators, disabling of security controls by a compromised admin

#### ClickOps Implementation

**Step 1: Enable Admin MFA**
1. Navigate to: **JumpCloud Admin Portal** → **Security** → **MFA for Admins**
2. Enable **Require MFA for Admin Portal**
3. Configure allowed MFA methods. JumpCloud documents five admin-available options:
   - **JumpCloud Go:** Recommended — device authenticator with biometrics; requires Google Chrome and the JumpCloud Go browser extension
   - **WebAuthn:** Highly recommended — security keys (YubiKey, Titan) or platform authenticators (Touch ID, Windows Hello)
   - **JumpCloud Protect (Push MFA):** Push approval via the JumpCloud Protect mobile app. JumpCloud blocks more than one notification per resource within a sixty-second window by default (except for RADIUS and LDAP), which is its documented anti-push-bombing measure — do not raise that limit in MFA Configurations without a specific reason.
   - **Verification Code (TOTP):** Authenticator-app codes; usable for the Admin Portal, User Portal, RADIUS, LDAP, and macOS/Linux/Windows systems
   - **Duo Security MFA:** Push, phone callback, or mobile passcode via Duo; available for the User Portal, SSO applications, and User Portal password resets
4. Prefer the phishing-resistant options (JumpCloud Go, WebAuthn) for administrators, and treat push and TOTP as secondary. Where a text-message factor is offered anywhere in your tenant, disable it — SMS is the weakest factor available and offers no phishing resistance.

**Step 2: Configure Admin Roles**
1. Navigate to: **Settings** → **Admin Roles**
2. Review default roles:
   - **Administrator:** Full access (limit to 2-3)
   - **Manager:** User and group management
   - **Help Desk:** Password reset, limited user view
   - **Read Only:** View-only access
3. Create custom roles for specific functions
4. Assign minimum required permissions

**Step 3: Audit Admin Accounts**
1. Navigate to: **Admins**
2. Review all administrator accounts
3. Remove unnecessary admin access
4. Verify all admins have MFA enrolled

**Time to Complete:** ~30 minutes

---


{% include pack-code.html vendor="jumpcloud" section="1.1" %}

### 1.2 Implement Least Privilege Administration

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Implement tiered administration following the principle of least privilege.

#### Rationale
**Why This Matters:**
- Tiered admin roles limit each operator to only the permissions their job requires, shrinking the blast radius if any single account is compromised
- A flat model where everyone holds full Administrator rights means one phished help-desk login can disable MFA, alter policies, or create rogue accounts directory-wide
- Reserving the most privileged tier for 2-3 hardware-key-protected admins makes the highest-value credentials the hardest to steal and the easiest to monitor
- Read-only and Help Desk roles let auditors and support staff do their work without ever touching security-critical configuration

**Attack Prevented:** Privilege escalation, lateral movement, insider abuse, blast-radius expansion from a single compromised admin

#### Implementation

**Tier 0 (Critical):**
- Full Administrator role
- Limit to 2-3 trusted admins
- Require strongest MFA (WebAuthn/hardware keys)

**Tier 1 (Standard Admin):**
- Manager role for user/group management
- Day-to-day administration tasks

**Tier 2 (Support):**
- Help Desk role for password resets
- Read Only for auditors

---

### 1.3 Govern Admin API Keys

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2, 6.2 |
| NIST 800-53 | IA-5, AC-2(3) |

#### Description
Set an expiration on every JumpCloud admin API key and re-create keys on a defined cadence. A JumpCloud API key is bound to an individual administrator account and is configured at **Admin Portal → your account initials (top-right) → My API Key**, where the **Expiration Date** menu offers 30, 60, or 90 days, a Custom value from one hour to 365 days, or No Expiration.

#### Rationale
**Why This Matters:**
- JumpCloud states the API key "gives unfiltered access to your JumpCloud instance through API calls" — it carries the admin's full authority with no scoping, so a leaked key is equivalent to a leaked admin session that never ends
- Keys are personal rather than service-bound, which means an administrator's departure leaves live credentials behind unless the key is explicitly invalidated — and a key with no expiration will never invalidate itself
- This is not hypothetical for this vendor: in the July 2023 incident, JumpCloud's own response included invalidating all admin API keys, which only works as a containment measure if the organization then notices and rotates deliberately

**Attack Prevented:** Unscoped API access from a leaked key, indefinite persistence via a never-expiring credential, offboarding gaps leaving live admin keys, undetected key reuse after a vendor-side incident

#### ClickOps Implementation

> **Changed default — pre-2024 admin accounts have no key expiration.** JumpCloud documents that **admin accounts created before July 15, 2024 have no expiration date on their API keys**. This is silent: the key works indefinitely and nothing in normal operation surfaces it. Audit every administrator who predates that date and set an expiration explicitly — the setting can be changed at any time. Note also that keys generated *after* that change default to a 90-day expiration, so newer accounts are not the risk here; older ones are.

**Step 1: Audit Existing Keys**
1. Enumerate all administrator accounts and identify those created before **July 15, 2024**
2. For each, have the account holder open **Admin Portal → account initials → My API Key** and check the displayed expiration date
3. Treat any key showing **No Expiration** as a finding

**Step 2: Set Expirations**
1. In **My API Key**, open the **Expiration Date** menu and select **30 days**, **60 days**, **90 days**, or a **Custom** value (one hour to 365 days). The selection saves automatically.
2. Choose the shortest interval the consuming integration can tolerate. Custom values down to one hour exist precisely for short-lived automation.
3. Note the operational consequence before you shorten it: JumpCloud emails a daily warning starting **seven days** before expiry, and once a key expires you must generate a new one **and update every integration using it**.

**Step 3: Establish a Rotation Cadence**
1. JumpCloud's API best-practices guidance recommends **re-creating API keys on an annual basis** at minimum, on a rolling schedule
2. Rotation is destructive by design — **once a key is rotated the older key is invalidated**, and code still using it will fail. Inventory the integrations consuming each key before rotating.
3. Rotate immediately, without waiting for the schedule, on any suspicion of sharing or compromise
4. Include API key invalidation in the administrator offboarding checklist, since the key belongs to the person, not to a service

#### Validation & Testing
1. For each administrator, confirm **My API Key** shows a concrete expiration date and not "No Expiration"
2. After a rotation, confirm the previous key returns an authentication failure against the API
3. Confirm every integration inventory entry names which administrator's key it consumes — an integration whose key owner is unknown cannot be rotated safely

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Credential lifecycle management for privileged access |
| **NIST 800-53** | IA-5 | Authenticator management |
| **NIST 800-53** | AC-2(3) | Disable accounts and credentials after defined period |
| **CIS Controls** | 5.2 | Use unique passwords / credentials |

---

### 1.4 Maintain Organization and Role Hygiene

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3, 5.4 |
| NIST 800-53 | AC-2, IA-5(1) |

#### Description
Delete unused organizations from the Multi-Tenant Portal, assign the Billing Only role to finance staff rather than a general admin role, and enforce JumpCloud's documented password baseline across users and administrators.

#### Rationale
**Why This Matters:**
- JumpCloud names unused organizations as "an avoidable risk," specifically because they accumulate forgotten or expired passwords and potentially compromised API keys while nobody is watching them — an abandoned tenant is an unmonitored tenant with live credentials
- Finance and accounting staff need billing data, not directory control; the Billing Only role exists so that a routine business function does not require handing out an administrative account that can alter identity configuration
- A documented password baseline (length, character classes, rotation) gives a concrete, auditable target instead of leaving each administrator to decide what "strong" means

**Attack Prevented:** Compromise via an abandoned, unmonitored organization; over-privileged finance accounts; credential-guessing against weak directory passwords; stale-credential persistence

#### ClickOps Implementation

**Step 1: Delete Unused Organizations**
1. Review the organizations in your **Multi-Tenant Portal (MTP)** and identify any that are no longer in use
2. Note the ordering requirement: **all users and devices must be deleted from the organization first** — an Org Delete Request cannot be submitted against a populated organization
3. Submit the Org Delete Request once the organization is empty

**Step 2: Assign the Billing Only Role**
1. Identify administrators who exist solely to handle invoices and payment
2. Assign them the **Billing Only** role so their permissions are limited to billing-specific tasks and information

**Step 3: Enforce the Password Baseline**

JumpCloud's documented recommendation for both users and administrators:

1. **Minimum length: 12 characters**
2. **Character classes:** at least one uppercase letter, one lowercase letter, one number, and one special character
3. **Rotation: every 90 days**
4. Store credentials in JumpCloud Password Manager rather than in personal or ad-hoc stores

#### Validation & Testing
1. List all organizations in the MTP and confirm each has a current owner and an active purpose
2. Review the administrator list and confirm no finance-only user holds a role broader than Billing Only
3. Attempt to set a non-compliant password and confirm the policy rejects it
4. Confirm password expiration is actually applied, not merely configured, by checking a sample account's expiry date

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.2 | Registration and authorization of new users |
| **SOC 2** | CC6.3 | Removal of access when no longer required |
| **NIST 800-53** | AC-2 | Account management |
| **NIST 800-53** | IA-5(1) | Password-based authenticator requirements |

---

## 2. Multi-Factor Authentication

### 2.1 Enforce Organization-Wide MFA

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all user authentication to protected resources including the User Portal, applications, and systems.

#### Rationale
**Why This Matters:**
- Passwords are, in JumpCloud's own framing, a common entry point for attackers precisely because they so often fall short of the baseline — a second factor is what stops a guessed, reused, or phished password from being sufficient on its own
- JumpCloud supports several factor types (JumpCloud Go, JumpCloud Protect push, TOTP, WebAuthn, Duo), so there is a workable option for nearly every user population and no defensible reason to leave a group uncovered
- Enforcement scoped to some groups but not others leaves the unprotected group as the obvious target; organization-wide enforcement is what removes the choice of entry point from the attacker

**Attack Prevented:** Credential stuffing, password spray, reuse of breached credentials, single-factor account takeover on uncovered user groups

#### ClickOps Implementation

**Step 1: Enable User MFA**
1. Navigate to: **Security** → **MFA**
2. Enable **Require MFA for User Portal**
3. Configure enforcement:
   - **All Users:** Recommended for most organizations
   - **User Groups:** For phased rollout

**Step 2: Configure Allowed Methods**
1. Select allowed MFA methods:
   - **TOTP:** Enabled (Google Authenticator, Authy)
   - **WebAuthn (Security Keys):** Enabled
   - **WebAuthn (Platform):** Enabled (Touch ID, Windows Hello)
   - **JumpCloud Go:** Enabled (recommended)
   - **SMS/Voice:** Disable if possible (less secure)
2. Set **Default MFA Method** preference

**Step 3: Enable JumpCloud Go**
1. Navigate to: **Security** → **JumpCloud Go**
2. Enable JumpCloud Go for passwordless authentication
3. This uses device authenticators with biometrics

**Time to Complete:** ~20 minutes

---


{% include pack-code.html vendor="jumpcloud" section="2.1" %}

### 2.2 Configure MFA for System Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for system login (Windows, macOS, Linux) and SSH access.

#### Rationale
**Why This Matters:**
- Endpoint and SSH logins are a primary entry point for attackers who have already harvested a username and password
- Adding MFA at the OS and SSH layer means a stolen or reused credential alone cannot unlock a workstation or server
- SSH credentials leaked through code repositories or phishing are worthless to an attacker without the second factor
- System-level MFA extends Zero Trust to the endpoint, not just the web portal, closing a gap attackers routinely exploit

**Attack Prevented:** Credential stuffing, password reuse, stolen SSH credentials, unauthorized workstation and server access

#### ClickOps Implementation

**Step 1: Enable MFA for Systems**
1. Navigate to: **Security** → **MFA**
2. Enable **Require MFA for System Login**
3. Configure per-OS settings:
   - **Windows:** Enable MFA at Windows logon
   - **macOS:** Enable MFA at macOS login
   - **Linux:** Enable MFA for SSH

**Step 2: Configure SSH MFA**
1. For Linux systems, configure JumpCloud agent
2. Enable **MFA Required** for SSH connections
3. Users will need to complete MFA after password

---

## 3. Conditional Access

### 3.1 Configure Conditional Access Policies

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.4 |
| NIST 800-53 | AC-2(11) |

#### Description
Configure conditional access policies to enforce context-aware security controls based on location, device, and risk signals.

#### Rationale
**Why This Matters:**
- Context-aware access enables Zero Trust by making the authentication requirement a function of the request's circumstances rather than a single global setting
- Conditions let you deny outright — not merely challenge — access from countries, networks, or device states your organization never legitimately operates from
- Because conditional policies fall back to the Default Access Policy when no condition matches, the default is the control that actually governs unanticipated requests and must be set deliberately

**Attack Prevented:** Access from unmanaged or unencrypted endpoints, logins from countries the organization does not operate in, off-network credential use, unrestricted access when no specific policy matches

#### Prerequisites
- **Platform Prime.** Adding a condition to an access policy is a premium feature; per JumpCloud, "Adding a Condition is a Premium feature and is part of our Platform Prime plan." An access policy without conditions can be created on lower tiers, but it is not a *conditional* access policy.

#### ClickOps Implementation

**Step 1: Create the Access Policy**
1. Log in to the **JumpCloud Admin Portal** (check your region-specific login URL if your data is stored outside the US)
2. Navigate to: **Security** → **Conditional Access Policies**
3. From the list view, click **(+)** and select the **Resource** — User Portal, SSO Applications, JumpCloud LDAP, or Admin Portal
4. Complete **General Info** (name, description; new policies are enabled by default)

**Step 2: Scope the Policy (Assignments)**
1. Choose whether the policy applies to specific applications or all of them
2. Choose whether it applies to all users or specific user groups
3. Use **Excluded User Groups** for exceptions — note that a user in both an included and an excluded group is **excluded**, so exclusions win and should be audited

**Step 3: Add Conditions**

Choose whether **all** conditions must match (`and` — more restrictive) or **any** (`or` — more permissive). **At most one condition of each type may be added per policy.** Available conditions:

| Condition | Operators | Notes |
|-----------|-----------|-------|
| **Device Management** | Is / Is Not (value fixed to *JumpCloud Managed*) | Desktop devices prove management via **Device Trust Certificates** or **JumpCloud Go**; mobile devices use **Mobile Device Trust**. Where both are enabled on desktop, **JumpCloud Go takes priority for web application logins**. Keep certificates enabled as a fallback for users who cannot use JumpCloud Go, and for federated logins to desktop applications and VPN clients. |
| **Disk Encryption** | Is / Is Not (value fixed to *Enabled on Device*) | Qualifies as BitLocker enabled (Windows), FileVault policy applied (macOS), or root disk encrypted (Linux). Status is re-checked at most every two hours. Cannot be combined with an Unmanaged device condition — encryption state is undetectable on an unmanaged device. |
| **IP Address** | Is On List / Is Not On List | Evaluated against selected IP lists. |
| **Location** | Is In Country / Is Not In Country | The **Unknown Location** option covers IP addresses that map to no country — decide explicitly how to treat it rather than leaving it unhandled. |
| **Operating System** | Is / Is Not | Desktop (macOS, Windows, Linux) and mobile (iOS/iPadOS, Android). OS information is not guaranteed reliable from non-managed devices. |
| **Managed Chrome Browser** | Enrollment domain is / is not | Requires Chrome. Windows and macOS only; see JumpCloud's Chrome Enterprise Device Trust prerequisites. |
| **Managed Chrome Profile** | Enrollment domain is / is not | Requires access through a managed Chrome profile. Windows and macOS only. |

**Step 4: Define the Action**

There are three outcomes, not a gradient:

1. **Allow without MFA** — set Access to *Allowed* and Authentication to *Password*
2. **Allow with MFA** — set Access to *Allowed* and Authentication to *Password + MFA*
3. **Deny** — set Access to *Denied*

> **Deny requires its own policy.** A policy that allows access when a condition is met does **not** deny access when it isn't — unmatched requests fall through to the Default Access Policy. JumpCloud's own example is disk encryption: to block unencrypted devices you must create a policy that explicitly denies them. Write the deny case as a separate policy rather than assuming the allow case implies it.

> **Enrollment periods are not honored.** When a conditional access policy requiring MFA is enabled, users without MFA configured are forced to enroll at their next login to that resource, regardless of any enrollment grace period. Sequence the rollout accordingly.

{% include pack-code.html vendor="jumpcloud" section="3.1" %}

**Time to Complete:** ~45 minutes

---

### 3.2 Configure Device Trust

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | AC-2(11) |

#### Description
Configure device trust to verify endpoint compliance before granting access to protected resources.

#### Rationale
**Why This Matters:**
- Device trust ensures only managed, compliant endpoints can reach sensitive applications and systems, even when valid credentials are presented
- Requiring the JumpCloud agent, disk encryption, and a current OS blocks access from unmanaged, jailbroken, or out-of-date machines attackers favor
- Tying access to device posture stops valid credentials used from an attacker-controlled or personal device from succeeding
- Continuous compliance checks catch endpoints that fall out of policy, preventing drift from silently expanding the attack surface

**Attack Prevented:** Access from compromised or unmanaged devices, credential use on attacker hardware, BYOD data leakage, non-compliant endpoint access

#### ClickOps Implementation

**Step 1: Choose How Devices Prove Management**
1. **Desktop:** enable **Device Trust Certificates**, **JumpCloud Go**, or both. Where both are enabled, JumpCloud Go takes priority for web application logins when the user authenticates with it; keep certificates enabled as a fallback for users who cannot use JumpCloud Go and for federated logins to desktop applications and VPN clients.
2. **Mobile:** enable **Mobile Device Trust**.

**Step 2: Enable Device Trust via Conditional Access**
1. Navigate to: **Security** → **Conditional Access Policies**
2. Create a policy with the **Device Management** condition (operator *Is*, value *JumpCloud Managed*)
3. Add the **Disk Encryption** condition (operator *Is*, value *Enabled on Device*) where you need encryption assurance. Note this cannot be combined with an unmanaged-device condition, and that encryption status is re-checked at intervals of at most two hours — so it reflects recent state, not live state.
4. Constrain platform with the **Operating System** condition where a device class should not reach the resource at all

**Step 3: Create the Deny Policy**
1. Create a **separate** policy that sets Access to **Denied** for non-compliant devices — an allow-on-compliance policy does not deny non-compliant devices, it simply doesn't match them, and they fall through to the Default Access Policy
2. Alternatively set Authentication to **Password + MFA** where you want step-up rather than a block
3. Confirm the **Default Access Policy** is itself set to a safe outcome, since it governs every request no conditional policy matches

---

## 4. Device & System Management

### 4.1 Configure System Policies

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-7 |

#### Description
Configure JumpCloud system policies to enforce security settings across managed devices.

#### Rationale
**Why This Matters:**
- Centrally enforced policies for screen lock, disk encryption, firewall, and patching guarantee a consistent security baseline on every managed device
- Full-disk encryption with key escrow protects data on lost or stolen laptops, and inactivity screen lock stops walk-up access to unlocked sessions
- Enforcing host firewalls and timely OS updates removes the unpatched, exposed endpoints attackers scan for
- Policy enforcement from the directory prevents individual users from silently disabling protections on their own machines

**Attack Prevented:** Data theft from lost or stolen devices, unpatched-vulnerability exploitation, unauthorized physical access, endpoint configuration drift

#### ClickOps Implementation

**Step 1: Access System Policies**
1. Navigate to: **Device Management** → **Policies**
2. Review available policy types

**Step 2: Configure Security Policies**
Create and apply these essential policies:

**Screen Lock Policy:**
1. Create new policy for screen lock
2. Configure:
   - **Lock after inactivity:** 5 minutes
   - **Require password:** Yes
3. Apply to all systems

**Full Disk Encryption Policy:**
1. Create policy for FDE
2. Configure:
   - **Windows:** BitLocker
   - **macOS:** FileVault
   - **Linux:** LUKS
3. Enforce encryption with key escrow

**Firewall Policy:**
1. Create policy enabling firewall
2. Configure:
   - **Windows Firewall:** Enabled
   - **macOS Firewall:** Enabled
3. Apply to all systems

**System Updates Policy:**
1. Create policy for OS updates
2. Configure update schedule
3. Enforce critical security patches

**Time to Complete:** ~1 hour

---


{% include pack-code.html vendor="jumpcloud" section="4.1" %}

### 4.2 Configure LDAP & RADIUS Security

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.10 |
| NIST 800-53 | SC-8 |

#### Description
Secure JumpCloud's cloud LDAP and RADIUS services for directory and network authentication.

#### Rationale
**Why This Matters:**
- Cloud LDAP and RADIUS authenticate directory binds and WiFi/VPN access, making them high-value targets for credential capture and network intrusion
- Requiring TLS on LDAP prevents bind credentials and directory queries from being intercepted in transit
- Dedicated, least-privilege service accounts for LDAP binds limit what a leaked bind credential can read or do
- Adding MFA to RADIUS and protecting shared secrets keeps a single stolen password or weak secret from granting network access

**Attack Prevented:** Credential interception, man-in-the-middle on directory traffic, unauthorized network and VPN access, shared-secret abuse

#### ClickOps Implementation

**Step 1: Configure Cloud LDAP**
1. Navigate to: **Settings** → **Cloud LDAP**
2. Review bound applications
3. Use dedicated service accounts for LDAP binds
4. Enable TLS for LDAP connections

**Step 2: Configure Cloud RADIUS**
1. Navigate to: **Settings** → **Cloud RADIUS**
2. Configure for WiFi/VPN authentication
3. Require MFA for RADIUS authentication
4. Configure shared secrets securely

---

## 5. Monitoring & Detection

### 5.1 Enable Directory Insights

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-6 |

#### Description
Enable JumpCloud Directory Insights for comprehensive audit logging and security monitoring.

#### Rationale
**Why This Matters:**
- Directory Insights captures admin actions, authentications, SSO, and system events that form the primary evidence trail for detecting and investigating compromise
- Without centralized logging, attacker activity such as new admin creation, MFA changes, or anomalous logins goes unnoticed
- Exporting logs to a SIEM enables real-time alerting and correlation across the rest of the security stack
- Adequate retention preserves the forensic record needed for incident response and compliance audits long after an event occurs

**Attack Prevented:** Undetected account compromise, stealthy privilege changes, delayed breach detection, evidence loss during incident response

#### ClickOps Implementation

**Step 1: Access Directory Insights**
1. Navigate to: **Reports** → **Directory Insights**
2. Review available log types:
   - Admin events
   - User authentication
   - System events
   - SSO events

**Step 2: Configure Log Export**
1. Navigate to: **Settings** → **Directory Insights**
2. Configure SIEM integration:
   - AWS S3
   - Azure Blob Storage
   - Webhook (generic SIEM)
3. Configure retention period

**Time to Complete:** ~30 minutes

---


{% include pack-code.html vendor="jumpcloud" section="5.1" %}

### 5.2 Key Events to Monitor

| Event Type | Detection Use Case |
|------------|-------------------|
| Admin login | Unauthorized admin access |
| Admin changes | Policy modifications |
| MFA bypass | Security control circumvention |
| Failed authentication | Brute force attempts |
| New device enrollment | Unauthorized device |
| Policy changes | Configuration drift |

---

## 6. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | JumpCloud Control | Guide Section |
|-----------|-------------------|---------------|
| CC6.1 | Admin MFA | [1.1](#11-secure-admin-portal-access) |
| CC6.1 | User MFA | [2.1](#21-enforce-organization-wide-mfa) |
| CC6.2 | Admin roles | [1.2](#12-implement-least-privilege-administration) |
| CC6.6 | Conditional access | [3.1](#31-configure-conditional-access-policies) |
| CC7.2 | Directory Insights | [5.1](#51-enable-directory-insights) |

### NIST 800-53 Rev 5 Mapping

| Control | JumpCloud Control | Guide Section |
|---------|-------------------|---------------|
| IA-2(1) | MFA enforcement | [2.1](#21-enforce-organization-wide-mfa) |
| AC-6(1) | Least privilege | [1.2](#12-implement-least-privilege-administration) |
| AC-2(11) | Conditional access | [3.1](#31-configure-conditional-access-policies) |
| CM-7 | System policies | [4.1](#41-configure-system-policies) |
| AU-2 | Logging | [5.1](#51-enable-directory-insights) |

---

## Appendix A: Plan Compatibility

JumpCloud's current packaging is three à la carte packages (**Device Management**, **SSO**, **Device Identity Management**) plus three bundles (**Platform Essentials**, **Platform**, **Platform Prime**). The older "Core" and "Platform Plus" names no longer appear in JumpCloud's packaging. Platform Essentials carries a documented **300-user maximum**.

| Feature | Device Management | SSO | Device Identity Mgmt | Platform Essentials | Platform | Platform Prime |
|---------|-------------------|-----|----------------------|---------------------|----------|----------------|
| Multi-Factor Authentication | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Single Sign-On | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| MDM / Device Management | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ |
| Directory Insights | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Passwordless (JumpCloud Go) | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| Password Management | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Conditional Access / Zero Trust | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |

> **Conditional access has two tiers of meaning.** The packaging table above shows Conditional Access / Zero Trust on Platform and Platform Prime, but the feature documentation is more specific: **adding a condition to an access policy is a premium feature and part of Platform Prime.** Verify against your own entitlement before designing policies around conditions.
>
> JumpCloud offers a **30-day free trial** rather than a permanent free tier at the user counts this guide previously listed; treat any "free for N users" claim as unverified against current packaging.

---

## Appendix B: References

**Official JumpCloud Documentation:**
- [JumpCloud Support](https://jumpcloud.com/support)
- [Best Practices: Secure Your Organization](https://jumpcloud.com/support/best-practices-secure-your-organization)
- [MFA for Admins](https://jumpcloud.com/support/mfa-for-admins)
- [Configure a Conditional Access Policy](https://jumpcloud.com/support/configure-a-conditional-access-policy)
- [JumpCloud APIs](https://jumpcloud.com/support/jumpcloud-apis)
- [Best Practices: JumpCloud API](https://jumpcloud.com/support/best-practices-jumpcloud-api)
- [JumpCloud Pricing and Packaging](https://jumpcloud.com/pricing)

**API & Developer Resources:**
- [JumpCloud API Documentation](https://docs.jumpcloud.com/)
- [JumpCloud PowerShell Module](https://github.com/TheJumpCloud/support/wiki)

**Compliance Frameworks:**
- Framework mappings for the controls in this guide are in [§6 Compliance Quick Reference](#6-compliance-quick-reference). For attestation evidence, request current reports through your JumpCloud account team and validate them against your own control set — the vendor's `/security` marketing page is not configuration documentation and is out of scope for this project's source standard.

**Security Incidents:**
- **July 2023:** JumpCloud disclosed a security incident involving a nation-state threat actor who compromised JumpCloud's internal systems, targeting a small set of customers. JumpCloud invalidated all admin API keys and notified affected customers. The incident was attributed to a North Korean state-sponsored group. See [1.3](#13-govern-admin-api-keys) — mass key invalidation is only an effective containment measure if customers then rotate deliberately and set expirations, which is why never-expiring keys on pre-2024 admin accounts matter.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Add 1.3 admin API key governance (keys are personal and unscoped; expiration options 30/60/90d, custom 1h-365d, or none; changed-default callout for the no-expiration keys on admin accounts predating 2024-07-15; annual re-creation cadence) and 1.4 organization/role/password hygiene; correct 1.1 to the five documented admin MFA methods and drop the implication that admin MFA is a guaranteed default; replace the unsourced "MFA blocks 99.9%" statistic in 2.1 with vendor-sourced rationale; correct the 3.1/3.2 console path to Security → Conditional Access Policies, record the Platform Prime requirement for conditions, and expand the full condition set, AND/OR logic, one-condition-per-type limit, three actions, and the deny-needs-its-own-policy behavior; remove the duplicate 3.1 pack include; rebuild the plan table on current packaging (Platform Essentials 300-user cap, Platform, Platform Prime, plus à la carte packages); add missing Attack Prevented to 1.1, 2.1, and 3.1; re-source the compliance references off the vendor security marketing page | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with admin security, MFA, and conditional access | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
